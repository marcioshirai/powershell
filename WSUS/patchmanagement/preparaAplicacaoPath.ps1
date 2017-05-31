# importar modulo com funcoes prontas para administrar o wsus
Import-Module "C:\Users\Administrator\Desktop\Scripts\poshWSUS.psm1" 

# vars das pastas de processamento
$executarFolder = ".\executar"
$processandoFolder = ".\processando"
$acompanhamentoFolder = ".\acompanhamento"
$finalizadasFolder = ".\finalizadas"

# header padrao para os arquivos html gerados
$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

# carregar arquivos da mudancas do diretorio num obj ps. Padrao nome dos arquivos: M<nnnnnn>-<site>.TXT
#$gmud = Read-Host "Mudanca"
$filesExecutar = gci .\executar\M*.txt | foreach { 
                                            $tmpGmud = ((($_.BaseName).Split("-"))[0]).ToUpper()
                                            $tmpSite = ((($_.BaseName).Split("-"))[1]).ToUpper()
                                            [pscustomobject]@{
                                            Gmud = $tmpGmud
                                            BaseName = $_.BaseName
                                            FileName = $_.Name
                                            Site = $tmpSite
                                            WSUSserver = "" 
                                            WSUSport = ""
                                            Status = "NAO INICIADA"
                                            Mensagem = ""
                                            QtServers = "0"
                                            LinkGmudAntes = "<a href='file://C:\Users\Administrator\Desktop\Scripts\processando\$tmpGmud-$tmpSite.HTML'>antes</a>"
                                            LinkGmudDurante = "<a href='file://C:\Users\Administrator\Desktop\Scripts\acompanhamento\$tmpGmud-$tmpSite.HTML'>execucao</a>"
                                            } }

# tratar cada arquivo de mudanca
foreach ($gmud in $filesExecutar) {

    # flag de validacao da mudanca
    $ignoraGmud=$False
    
    # a partir do site, carregar server e port do wsus
    switch ($gmud.Site) {
    "CTSP"  { $wsusServer="W2K12"; $wsusPort="8530" }
    "CTMM1" { $wsusServer="W2K12"; $wsusPort="8530" }
    "CTMM2" { $wsusServer="W2K12"; $wsusPort="8530" }
    default { $gmud.Status="ERRO";$gmud.Mensagem="Site nao identificado no nome do arquivo"; $ignoraGmud=$True }
    }

    # se flag ativa, ignorar gmud
    if ($ignoraGmud) { continue }

    # carregar dados no obj de gmuds
    $gmud.WSUSserver = $wsusServer
    $gmud.WSUSport = $wsusPort

    # conectar no wsus
    $conexao = Connect-WSUSServer -WsusServer $wsusServer -Port $wsusPort 

    # se ja existir grupo da mudanca no wsus, gerar erro e pular para proximo
    if (Get-WSUSGroup -Name $gmud.Gmud -EA SilentlyContinue) { 
        #Write-Warning "Grupo $($gmud.Gmud) ja existe no servidor WSUS $wsusServer ($($gmud.Site))"
        # mover arquivo de gmud para finalizadas
        Move-Item -Path $executarFolder\$($gmud.FileName) -Destination $finalizadasFolder\$($gmud.FileName) -Force
        # gerar html da gmud com o erro e carregar status
        $msg=[pscustomobject]@{Erro="Grupo $($gmud.Gmud) ja existe no servidor WSUS $wsusServer ($($gmud.Site))"} 
        $msg | ConvertTo-Html -Head $Header -Body "<H2>ERRO na preparacao da GMUD</H2>" | Set-Content "$($finalizadasFolder)\$($gmud.BaseName).HTML"
        $gmud.Status="ERRO"
        $gmud.Mensagem=($msg.Erro)
        Continue
        }
    
    # cria grupo no wsus com o nome da gmud
    New-WSUSGroup -Group $gmud.Gmud

    # move arquivo da gmud para pasta processando
    Move-Item $executarFolder\$($gmud.FileName) $processandoFolder\$($gmud.FileName) -Force

    # carrega clients a serem tratados (aqui considerando todos do wsus, alterar se for de fonte diferente)
    $clientsFull = Get-WSUSClients

    # change membership do wsus incluindo cada client no grupo
    $clientsGmud = $clientsFull | foreach { Add-WSUSClientToGroup -Group $gmud.Gmud -Computer $_.FullDomainName | Out-Null; $_ }
    
    # carregar mensagem com qtde de clientes a serem tratados
    $gmud.QtServers = $clientsGmud.Count
    $gmud.Mensagem = "$($clientsGmud.Count) servidores para aplicacao de patch"

    # carregar obj com dados dos clientes da gmud
    $clientsGmudFile = $clientsGmud | foreach { 
                            $update = $_.GetUpdateInstallationSummary() 
                            [pscustomobject]@{
                                Computername = $_.FullDomainName
                                #ID=  $_.Id
                                IPAddress = $_.IPAddress
                                LastReported = $_.LastReportedStatusTime
                                LastSync = $_.LastSyncTime
                                OS = $_.OSDescription
                                Unknown       = $update.UnknownCount
                                NotApplicable = $update.NotApplicableCount
                                NotInstalled  = $update.NotInstalledCount
                                Downloaded    = $update.DownloadedCount
                                Installed     = $update.InstalledCount
                                PendingReboot = $update.InstalledPendingRebootCount
                                Failed        = $update.FailedCount
                                } }

    # gerar arq csv e html com obj dos clientes na pasta processando
    $clientsGmudFile | ConvertTo-Csv -Delimiter ";" -NoTypeInformation | Set-Content "$($processandoFolder)\$($gmud.BaseName).TXT"
    $clientsGmudFile | ConvertTo-Html -Head $Header -Body "<H2>Posicao Inicial - Preparacao GMUD $($gmud.Gmud)</H2>" | Set-Content "$($processandoFolder)\$($gmud.BaseName).HTML"
}

# gerar html com posicao das gmuds preparadas
$filesExecutarHTML = $filesExecutar | ConvertTo-Html -Head $Header -Body "<H2>STATUS - Mudancas</H2>" 

# tratar o link incluido no objeto
Add-Type -AssemblyName System.Web
[System.Web.HttpUtility]::HtmlDecode($filesExecutarHTML) | Set-Content "$($acompanhamentoFolder)\indexGmuds.HTML"



#Read-Host "Pressione qq tecla para continuar"
#$clients | foreach { Remove-WSUSClientFromGroup -Group $gmud -Computer $_.FullDomainName }
#Remove-WSUSGroup -Name $gmud
# Disconnect-WSUSServer
# Get-WSUSCommands





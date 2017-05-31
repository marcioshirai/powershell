# importar modulo com funcoes prontas para administrar o wsus
Import-Module "C:\Users\Administrator\Desktop\Scripts\poshWSUS.psm1" 

# vars das pastas de processamento
$executarFolder = "executar"
$processandoFolder = "processando"
$acompanhamentoFolder = "acompanhamento"
$finalizadasFolder = "finalizadas"
$backupFolder = "backup"

# header padrao para os arquivos html gerados
$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

# carregar arquivos da mudancas do diretorio num obj posh. Padrao nome dos arquivos: M<nnnnnn>-<site>.TXT
# 
$filesExecutar = gci $executarFolder\M*.txt | foreach { 
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
                                            LinkGmudInicio = "<a href='$tmpGmud-$tmpSite-inicio.html'>antes</a>"
                                            LinkGmudDurante = "<a href='$tmpGmud-$tmpSite.html'>execucao</a>"
                                            } }

# cancelar se nao tiver nada para executar
if (!($filesExecutar)) { return }

# retirar as gmuds que ja estao processando ou acompanhadas para nao dar duplicidade
# $processando = (Get-Item $processandoFolder\M*.txt).Name
# $acompanhando = (Get-Item $acompanhamentoFolder\M*.txt).Name
# if ($processando)  { $filesExecutar = $filesExecutar | ?{ $processando  -notcontains $_.FileName } }
# if ($acompanhando) { $filesExecutar = $filesExecutar | ?{ $acompanhando -notcontains $_.FileName } }

# cancelar se nao tiver nada para executar depois da validacao acima
# if (!($filesExecutar)) { return -1 }

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

    # copia arquivo para pasta backup
    Copy-Item $executarFolder\$($gmud.FileName) $backupFolder\$($gmud.FileName) -Force

    # carregar dados no obj de gmuds
    $gmud.WSUSserver = $wsusServer
    $gmud.WSUSport = $wsusPort

    # conectar no wsus
    $conexao = Connect-WSUSServer -WsusServer $($gmud.WSUSserver) -Port $($gmud.WSUSport)

    # se ja existir grupo da mudanca no wsus, gerar erro e pular para proximo
    if (Get-WSUSGroup -Name $gmud.Gmud -EA SilentlyContinue) { 
        #Write-Warning "Grupo $($gmud.Gmud) ja existe no servidor WSUS $wsusServer ($($gmud.Site))"
        
        # mover arquivo de gmud para finalizadas
        Move-Item -Path $executarFolder\$($gmud.FileName) -Destination $finalizadasFolder\$($gmud.FileName) -Force
        
        # gerar html da gmud com o erro e carregar status
        $msg=[pscustomobject]@{Erro="Grupo $($gmud.Gmud) ja existe no servidor WSUS $wsusServer ($($gmud.Site))"} 
        $msg | ConvertTo-Html -Head $Header -Body "<H2>ERRO na preparacao da GMUD</H2>" | Set-Content "$($finalizadasFolder)\$($gmud.BaseName).html"
        $gmud.Status="ERRO"
        $gmud.Mensagem=$($msg.Erro)
        
        # pular para proxima gmud ignorando abaixo
        Continue
        }
    
    # -------------
    # MAIN SECTION
    # -------------

    # cria grupo no wsus com o nome da gmud
    New-WSUSGroup -Group $gmud.Gmud

    # move arquivo da gmud (txt) para pasta processando
    Move-Item $executarFolder\$($gmud.FileName) $processandoFolder\$($gmud.FileName) -Force

    # carrega clients a serem tratados (aqui considerando todos do wsus, alterar se for de fonte diferente)
    # ex.: se fornecido no arquivo TXT, carregar o conteudo com get-content
    $clientsFull = Get-WSUSClients

    # change membership do wsus incluindo cada client no grupo - regra para inclusao aqui
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

    # gerar arq csv e html com obj dos clientes na pasta acompanhamento
    $clientsGmudFile | ConvertTo-Csv -Delimiter ";" -NoTypeInformation | Set-Content "$($acompanhamentoFolder)\$($gmud.BaseName)-inicio.csv"
    $clientsGmudFile | ConvertTo-Html -Head $Header -Body "<H2>Posicao Inicial - Preparacao GMUD $($gmud.Gmud) ($($gmud.Site))</H2>" | Set-Content "$($acompanhamentoFolder)\$($gmud.BaseName)-inicio.html"
}

$filesExecutar = $filesExecutar | ?{ $_.Status -ne "ERRO" } 
$filesErro | ?{ $_.Status -eq "ERRO" } 

# gerar html com posicao das gmuds
# $filesExecutarHTML = $filesExecutar | ConvertTo-Html -Head $Header -Body "<H2>STATUS - Mudancas</H2>" 

# tratar o link incluido no objeto e salvar o arquivo html com append
# Add-Type -AssemblyName System.Web
# [System.Web.HttpUtility]::HtmlDecode($filesExecutarHTML) | Set-Content "$($acompanhamentoFolder)\indexGmuds.html"

# gravar o obj como csv adicionando registros no fim do arquivo
if ($filesExecutar) { $filesExecutar | Export-Csv "$($acompanhamentoFolder)\indexGmuds.csv" -Delimiter ";" -NoTypeInformation -Force -Append }
if ($filesErro)     { $filesErro     | Export-Csv "$($finalizadasFolder)\indexGmuds.csv"    -Delimiter ";" -NoTypeInformation -Force -Append }

#Read-Host "Pressione qq tecla para continuar"
#$clients | foreach { Remove-WSUSClientFromGroup -Group $gmud -Computer $_.FullDomainName }
#Remove-WSUSGroup -Name $gmud
# Disconnect-WSUSServer
# Get-WSUSCommands





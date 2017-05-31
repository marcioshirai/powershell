# importar modulo com funcoes prontas para administrar o wsus
Import-Module "C:\Users\Administrator\Desktop\Scripts\poshWSUS.psm1" 

# vars das pastas de processamento
$executarFolder = "executar"
$processandoFolder = "processando"
$acompanhamentoFolder = "acompanhamento"
$finalizadasFolder = "finalizadas"

# header padrao para os arquivos html gerados
$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

# carregar os nomes dos arquivos da pasta processando 
# pois o arquivo indexGmuds contera todas as mudancas processadas. a base sera o que estiver no dir processando
$processando = (Get-Item $processandoFolder\M*.txt).Name


# carregar arquivo das mudancas num obj posh, com filtro somente da pasta processando (parar tudo que estava na pasta)
if (!(Test-Path "$($acompanhamentoFolder)\indexGmuds.csv")) { Write-Warning "Arquivo indexGmuds.csv nao encontrado"; return}
$filesProcessando = Import-Csv "$($acompanhamentoFolder)\indexGmuds.csv" -Delimiter ";" | ?{ $processando -contains $_.FileName }

# cancelar se nao tiver nada para executar
if (!($filesProcessando)) { return }

# tratar cada arquivo de mudanca
foreach ($gmud in $filesProcessando) {

    # conectar no wsus
    $conexao = Connect-WSUSServer -WsusServer $($gmud.WSUSserver) -Port $($gmud.WSUSport)

    # se nao encontrar grupo da mudanca no wsus, gerar erro e pular para proximo
    if (!(Get-WSUSGroup -Name $gmud.Gmud -EA SilentlyContinue)) { 
        #Write-Warning "Grupo $($gmud.Gmud) nao existe no servidor WSUS $wsusServer ($($gmud.Site))"
        
        # atualizar html com o erro e status
        $msg=[pscustomobject]@{Erro="Grupo $($gmud.Gmud) nao existe no servidor WSUS $wsusServer ($($gmud.Site))"} 
        $gmud.Status="ERRO"
        $gmud.Mensagem=$($msg.Erro)
        
        # pular para proxima gmud ignorando abaixo
        Continue
        }
    
    # -------------
    # MAIN SECTION
    # -------------

    # carrega clients do grupo com o nome da mudanca gmud
    $clientsGmud = Get-WSUSClientsInGroup -Name $gmud.Gmud

    # carregar mensagem com qtde de clientes a serem tratados
    $gmud.Status = "FINALIZADA"
    $gmud.Mensagem = "$($clientsGmud.Count) servidores para aplicacao de patch"
    $gmud.QtServers = $($clientsGmud.Count)

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
    $clientsGmudFile | ConvertTo-Csv -Delimiter ";" -NoTypeInformation | Set-Content "$($acompanhamentoFolder)\$($gmud.BaseName).CSV"
    $clientsGmudFile | ConvertTo-Html -Head $Header -Body "<H2>Acompanhamento - GMUD $($gmud.Gmud) ($($gmud.Site))</H2>" | Set-Content "$($acompanhamentoFolder)\$($gmud.BaseName).html"

    # move arquivo da gmud (txt) da pasta processando para finalizadas
    Move-Item $processandoFolder\$($gmud.FileName) $finalizadasFolder\$($gmud.FileName) -Force
    $arquivos = "$($gmud.Gmud)" + "-" + "$($gmud.Site)" + "*.*"
    Move-Item $acompanhamentoFolder\$arquivos $finalizadasFolder -Force

    
    Write-Warning "Removendo GRUPO NO WSUS"

    $clientsGmud | foreach { Remove-WSUSClientFromGroup -Group $gmud.Gmud -Computer $_.FullDomainName }
    Remove-WSUSGroup -Name $gmud.Gmud
    # Disconnect-WSUSServer
    # Get-WSUSCommands

}

# retirar as finalizadas do csv
$filesRestante = Import-Csv "$($acompanhamentoFolder)\indexGmuds.csv" -Delimiter ";" | ?{ $processando -notcontains $_.FileName }

# gerar html com posicao das gmuds restantes
$filesProcessandoHTML = $filesRestante | ConvertTo-Html -Head $Header -Body "<H2>STATUS - Mudancas</H2>" 

# tratar o link incluido no objeto e salvar o arquivo html
Add-Type -AssemblyName System.Web
[System.Web.HttpUtility]::HtmlDecode($filesProcessandoHTML) | Set-Content "$($acompanhamentoFolder)\indexGmuds.html"

# gravar o obj como csv para utilizacao no acompanhamento
$filesRestante | Export-Csv "$($acompanhamentoFolder)\indexGmuds.csv" -Delimiter ";" -NoTypeInformation -Force

# gravar o obj como csv finalizadas
$filesProcessando | Export-Csv "$($finalizadasFolder)\indexGmuds.csv" -Delimiter ";" -NoTypeInformation -Force -Append

# ATUALIZAR O HTML DAS FINALIZADAS

# carregar csv das finalizadas
$finalizadas = Import-Csv "$($finalizadasFolder)\indexGmuds.csv" -Delimiter ";" 

# gerar html com posicao das gmuds finalizadas
$finalizadasHTML = $finalizadas | ConvertTo-Html -Head $Header -Body "<H2>STATUS - Mudancas FINALIZADAS</H2>" 

# tratar o link incluido no objeto e salvar o arquivo html
Add-Type -AssemblyName System.Web
[System.Web.HttpUtility]::HtmlDecode($finalizadasHTML) | Set-Content "$($finalizadasFolder)\indexGmuds.html"

<#
Update Log:
    1. Updated code to use APIs instead of Functions (Get-WSUSGroup, Get-WSUSUpdate) in other WSUS functions
    2. Changed monitoring notification from gui based to text based
    3. 5 new functions for WSUS Automatic Approvals 
        a.New-WSUSInstallApprovalRule
        b.Set-WSUSInstallApprovalRule
        c.Get-WSUSInstallApprovalRules
        d.Remove-WSUSInstallApprovalRule
        e.Start-WSUSInstallApprovalRule
    4. 2 new functions for working with the Database server used by WSUS
        a.Connect-WSUSDatabaseServer
        b.Test-WSUSDatabaseServerConnection
    5. Get-WSUSUpdateClassifications
#>

Write-Host "`n"
Write-Host "`t`tPoshWSUS 1.1"
Write-Host "`n"
Write-Host -nonewline "Make initial connection to WSUS Server:`t"
Write-Host -fore Yellow "Connect-WSUSServer"
Write-Host -nonewline "Disconnect from WSUS Server:`t`t"
Write-Host -fore Yellow "Disconnect-WSUSServer"
Write-Host -nonewline "List all available commands:`t`t"
Write-Host -fore Yellow "Get-WSUSCommands"
Write-Host "`n"

function Get-WSUSCommands {
<#  
.SYNOPSIS  
    Lists all WSUS functions available from this module.
.DESCRIPTION
    Lists all WSUS functions available from this module.    
.NOTES  
    Name: Get-WSUSCommand
    Author: Boe Prox
    DateCreated: 18Oct2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
Get-WSUSCommands 

Description
-----------
This command lists all of the available WSUS commands in the module.      
#> 
[cmdletbinding()]  
Param () 

#List all WSUS functions available
Get-Command *WSUS*  -CommandType Function  | Sort-Object Name
}

function Connect-WSUSServer {
<#  
.SYNOPSIS  
    Retrieves the last check-in times of clients on WSUS.
.DESCRIPTION
    Retrieves the last check-in times of clients on WSUS. You will need to run this on a machine that
    has the WSUS Administrator console installed.
.PARAMETER WsusServer
    Name of WSUS server to query against.          
.PARAMETER Secure
    Determines if a secure connection will be used to connect to the WSUS server. If not used, then a non-secure
    connection will be used.    
.PARAMETER Port
    Port number if default ports 80 and 443 not used    
.NOTES  
    Name: Get-LastCheckIn
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE
Connect-WSUSServer -wsusserver "server1"

Description
-----------
This command will make the connection to the WSUS using an unsecure port (Default:80).
.EXAMPLE
Connect-WSUSServer -wsusserver "server1"  -secure 

Description
-----------
This command will make a secure connection (Default: 443) to a WSUS server.   
.EXAMPLE
Connect-WSUSServer -wsusserver "server1" -port 8560

Description
-----------
This command will make the connection to the WSUS using a defined port 8560.  
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'wsus',
	ConfirmImpact = 'low'
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = '',
            ValueFromPipeline = $True)]
            [string]$WsusServer,                     
        [Parameter(
            Mandatory = $False,
            Position = 1,
            ParameterSetName = '',
            ValueFromPipeline = $False)]
            [switch]$Secure,   
        [Parameter(
            Mandatory = $False,
            Position = 2,
            ParameterSetName = 'port',
            ValueFromPipeline = $False)]
            [int]$port                                
            )            
#Load required assemblies            
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
#Make connection to WSUS server 
Write-Host -ForegroundColor Yellow "Attempting connection to WSUS Server: $($wsusserver)"   
$ErrorActionPreference = 'stop'
Try {
    If ($secure) {
        Switch ($pscmdlet.ParameterSetName) {
            "wsus" {
                $Global:wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($wsusserver,$True)
                $Wsus | Select Name, Version,PortNumber
                }
            "port" {
                $Global:wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($wsusserver,$True,$port)
                $Wsus | Select Name, Version,PortNumber                
                }                
            }
        }
    Else {
        Switch ($pscmdlet.ParameterSetName) {
            "wsus" {
                $Global:wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($wsusserver,$False)
                $Wsus | Select Name, Version,PortNumber
                }
            "port" {
                $Global:wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($wsusserver,$False,$port)
                $Wsus | Select Name, Version,PortNumber                
                }                
            }
        }
    }
Catch {
    Write-Error "Unable to connect to $($wsusserver)!`n$($error[0])"
    }                
}

function Disconnect-WSUSServer {
<#  
.SYNOPSIS  
    Disconnects session against WSUS server.
.DESCRIPTION
    Disconnects session against WSUS server.
.NOTES  
    Name: Disconnect-WSUSServer
    Author: Boe Prox
    DateCreated: 27Oct2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE
Disconnect-WSUSServer

Description
-----------
This command will disconnect the session to the WSUS server.  
       
#> 
[cmdletbinding()]  
Param () 
#Disconnect WSUS session by removing the variable   
Remove-Variable -Name $wsus -Force
}

function Get-WSUSClients {
<#  
.SYNOPSIS  
    Retrieves a list of all of the clients in WSUS.
.DESCRIPTION
    Retrieves a list of all of the clients in WSUS.  
.NOTES  
    Name: Get-WSUSClients
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE
Get-WSUSClients

Description
-----------
This command will list every client in WSUS.  
       
#> 
[cmdletbinding()]  
Param () 
#Gather all computers in WSUS    
$wsus.GetComputerTargets()
}
        

function Start-WSUSSync {
<#  
.SYNOPSIS  
    Start synchronization on WSUS server.
.DESCRIPTION
    Start synchronization on WSUS server.
.PARAMETER Monitor
    Starts a synchronization and runs a background job to monitor currently running content download and 
    notifies user when completed.         
.NOTES  
    Name: Start-WSUSSync
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE
Start-WSUSSync

Description
-----------
This command will begin a manual sychronization on WSUS with the defined update source. 
.EXAMPLE
Start-WSUSSync -monitor

Description
-----------
This command will begin a manual synchronization on WSUS and will begin a background job that will notifiy via
pop-up message when the synchronization has completed.      
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'monitor',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)] 
Param (
    [Parameter(
        Mandatory = $False,
        Position = 0,
        ParameterSetName = 'monitor',
        ValueFromPipeline = $False)]
        [switch]$Monitor
    )
$sub = $wsus.GetSubscription()    
$sync = $sub.GetSynchronizationProgress()    
If ($monitor) {
    #Stop and remove any jobs for SyncMonitoring
    $jobs = Get-Job | ? {$_.Name -eq "WSUSSyncProgressMonitor"}
    If ($jobs) {
        $jobs | Stop-Job
        $jobs | Remove-Job
        }
    #Start WSUS synchronization
    If ($pscmdlet.ShouldProcess($($wsus.name))) {
            $sub.StartSynchronization()  
            "Synchronization have been started."
            Start-Sleep -Seconds 3
        Start-Job -Name "WSUSSyncProgressMonitor" -ArgumentList $sync -ScriptBlock {
            Param (
                $sync
                )
            #Load required assemblies for message window    
            [void] [System.Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”)                        
            While ($sync.Phase -ne "NotProcessing") {
                $null
                }
            Write-Host -BackgroundColor Black -ForegroundColor Green "Synchronization has been completed on WSUS"
            } | Out-Null
        }             
    }
Else {
    #Start WSUS synchronization
    If ($pscmdlet.ShouldProcess($($wsus.name))) {
        $sub.StartSynchronization()  
        "Synchronization have been started."
        } 
    } 
}         

function Stop-WSUSSync {
<#  
.SYNOPSIS  
    Stops a currently running WSUS sync.
.DESCRIPTION
    Stops a currently running WSUS sync.
.NOTES  
    Name: Stop-WSUSSync
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE
Stop-WSUSSync  

Description
-----------
This command will stop a currently running WSUS synchronization.
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'update',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)]
    Param()
$sub = $wsus.GetSubscription()      
#Cancel synchronization running on WSUS       
If ($pscmdlet.ShouldProcess($($wsus.name))) {
    $sub.StopSynchronization() 
    "Synchronization have been cancelled."
    }    
}        

function Get-WSUSSyncHistory {
<#  
.SYNOPSIS  
    Retrieves the synchronization history of the WSUS server.
.DESCRIPTION
    Retrieves the synchronization history of the WSUS server.    
.NOTES  
    Name: Get-WSUSSyncHistory 
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE
Get-WSUSSyncHistory

Description
-----------
This command will list out the entire synchronization history of the WSUS server.  
       
#> 
[cmdletbinding()]  
Param () 

$sub = $wsus.GetSubscription()
$sub.GetSynchronizationHistory()      
}  

function Get-WSUSSyncProgress {
<#  
.SYNOPSIS  
    Displays the current progress of a WSUS synchronization.
.DESCRIPTION
    Displays the current progress of a WSUS synchronization. 
.PARAMETER Monitor
    Runs a background job to monitor currently running synchonization and notifies user when completed.      
.NOTES  
    Name: Get-WSUSSyncProgress
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE
Get-WSUSSyncProgress 

Description
-----------
This command will show you the current status of the WSUS sync.
.EXAMPLE
Get-WSUSSyncProgress -monitor     

Description
-----------
This command will begin a background job that will notify you when the WSUS synchronization
has been completed.
       
#> 
[cmdletbinding()]  
Param (
    [Parameter(
        Mandatory = $False,
        Position = 0,
        ParameterSetName = 'monitor',
        ValueFromPipeline = $False)]
        [switch]$Monitor
    )
$sub = $wsus.GetSubscription()    
If ($monitor) {
    $job = Get-Job
    If ($job) {
        $job = Get-Job -Name "WSUSSyncProgressMonitor"
        }
    If ($job) {
        Get-Job -Name "WSUSSyncProgressMonitor" | Stop-Job
        Get-Job -Name "WSUSSyncProgressMonitor" | Remove-Job
        }    
    Start-Job -Name "WSUSSyncProgressMonitor" -ArgumentList $sub -ScriptBlock {
        Param (
            $sub
            )
        #Load required assemblies for message window    
        [void] [System.Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”)                        
        While (($sub.GetSynchronizationProgress()).Phase -ne "NotProcessing") {
            $null
            }
        Write-Host -BackgroundColor Black -ForegroundColor Green "Synchronization has been completed on WSUS"
        } | Out-Null 
    }
Else {
    #Gather all child servers in WSUS    
    $sub.GetSynchronizationProgress() 
    } 
     
}  

function Get-WSUSEvents {
<#  
.SYNOPSIS  
    Retrieves all WSUS events.
.DESCRIPTION
    Retrieves all WSUS events from the WSUS server.  
.NOTES  
    Name: Get-WSUSEvents
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE
Get-WSUSEvents  

Description
-----------
This command will show you all of the WSUS events.
       
#> 
[cmdletbinding()]  
Param () 

$sub = $wsus.GetSubscription()
$sub.GetEventHistory()      
}  

function Get-WSUSGroups {
<#  
.SYNOPSIS  
    Retrieves all of the WSUS Target Groups.
.DESCRIPTION
    Retrieves all of the WSUS Target Groups.    
.NOTES  
    Name: Get-WSUSGroups
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE
Get-WSUSGroups  

Description
-----------
This command will list out all of the WSUS Target groups and their respective IDs.
       
#> 
[cmdletbinding()]  
Param () 
 
$wsus.GetComputerTargetGroups()      
}  

function Get-WSUSServer {
<#  
.SYNOPSIS  
    Retrieves connection and configuration information from the WSUS server.
.DESCRIPTION
    Retrieves connection and configuration information from the WSUS server. 
.PARAMETER Configuration
    Lists more configuration information from WSUS Server      
.NOTES  
    Name: Get-WSUSServer
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE
Get-WSUSServer

Description
-----------
This command will display basic information regarding the WSUS server.
.EXAMPLE
Get-WSUSServer -configuration      

Description
-----------
This command will list out more detailed information regarding the configuration of the WSUS server.
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'wsus',
	ConfirmImpact = 'low'
)]
    Param(                         
        [Parameter(
            Mandatory = $False,
            Position = 0,
            ParameterSetName = 'wsus',
            ValueFromPipeline = $False)]
            [switch]$Configuration                     
            )                    
If ($configuration) {
    $wsus.GetConfiguration()
    }
Else {
    $wsus
    }        
}  

function Get-WSUSUpdates {
<#  
.SYNOPSIS  
    Retrieves all of the updates from a WSUS server.
.DESCRIPTION
    Retrieves all of the updates from a WSUS server.   
.NOTES  
    Name: Get-WSUSUpdates
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE
Get-WSUSUpdates  

Description
-----------
This command will list out every update that is in WSUS's database whether it has been approved or not.
       
#> 
[cmdletbinding()]  
Param () 
 
$wsus.GetUpdates()      
}  

function Get-WSUSEmailConfig {
<#  
.SYNOPSIS  
    Retrieves the email notification configuration from WSUS.
.DESCRIPTION
    Retrieves the email notification configuration from WSUS.
.PARAMETER SendTestEmail
    Optional switch that will send a test email to the configured email addresses        
.NOTES  
    Name: Get-WSUSEmailConfig
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
 Get-WSUSEmailConfig 
 
 Description
-----------
This command will display the configuration of the email notifications.
.EXAMPLE 
Get-WSUSEmailConfig -SendTestEmail    

Description
-----------
This command will send a test email to the address or addresses in the To field.
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'wsus',
	ConfirmImpact = 'low'
)]
    Param(                          
        [Parameter(
            Mandatory = $False,
            Position = 0,
            ParameterSetName = 'wsus',
            ValueFromPipeline = $False)]
            [switch]$SendTestEmail                   
            )                   
$email = $wsus.GetEmailNotificationConfiguration()    
If ($SendTestEmail) {
    $email.SendTestEmail()
    Write-Host -fore Green "Test email sent."
    }           
Else {
    $email
    }    
}  

function Get-WSUSUpdateCategories {
<#  
.SYNOPSIS  
    Retrieves the list of Update categories available from WSUS.
.DESCRIPTION
    Retrieves the list of Update categories available from WSUS.   
.NOTES  
    Name: Get-WSUSUpdateCategories
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE
Get-WSUSUpdateCategories  

Description
-----------
This command will list all of the categories for updates in WSUS.
       
#> 
[cmdletbinding()]  
Param () 
 
$wsus.GetUpdateCategories()      
}  

function Get-WSUSStatus {
<#  
.SYNOPSIS  
    Retrieves a list of all updates and their statuses along with computer statuses.
.DESCRIPTION
    Retrieves a list of all updates and their statuses along with computer statuses.   
.NOTES  
    Name: Get-WSUSStatus
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
Get-WSUSStatus 

Description
-----------
This command will display the status of the WSUS server along with update statuses.
       
#> 
[cmdletbinding()]  
Param () 

$wsus.getstatus()      
}  

function Set-WSUSEmailConfig {
<#  
.SYNOPSIS  
    Configures the email notifications on a WSUS server.
.DESCRIPTION
    Configures the email notifications on a WSUS server. It is important to note that the email address to send
    the emails to is Read-Only and can only be configured from the WSUS Admin Console. After the settings have been
    changed, the new configuration will be displayed.
.PARAMETER EmailLanguage
    What type of language to send the email in.          
.PARAMETER SenderDisplayName
    The friendly name of where the email is coming from.    
.PARAMETER SenderEmailAddress
    The senders email address
.PARAMETER SendStatusNotification
    Determines if an email will be sent for a status notification    
.PARAMETER SendSyncnotification
    Determines if an email will be sent after a sync by WSUS
.PARAMETER SMTPHostname
    Server name of the smtp server to send email from
.PARAMETER SMTPPort
    Port number to be used to connect to smtp server to send email
.PARAMETER SmtpServerRequiresAuthentication
    Used if smtp server requires authentication
.PARAMETER SmtpUserName  
    Username to submit if required by smtp server
.PARAMETER StatusNotificationFrequency
    Frequency (Daily or Weekly) to send notifications
.PARAMETER StatusNotificationTimeOfDay
    Date/Time to send notifications
.PARAMETER UpdateServer
    Name of the WSUS update server
.PARAMETER SmtpPassword
    Password to user for smtp server connection.    
.NOTES  
    Name: Set-WSUSEmailConfig
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Set-WSUSEmailConfig -SenderDisplayName "WSUSAdmin" -SenderEmailAddress "wsusadmin@domain.com"

Description
-----------  
This command will change the sender name and email address for email notifications and then display the new settings.      
#> 
[cmdletbinding(
	DefaultParameterSetName = 'wsus',
	ConfirmImpact = 'low'
)]
    Param(
        [Parameter(
            Mandatory = $False, Position = 0,
            ParameterSetName = '', ValueFromPipeline = $False)]
            [string]$EmailLanguage,                     
        [Parameter(
            Mandatory = $False, Position = 1,
            ParameterSetName = '', ValueFromPipeline = $False)]
            [string]$SenderDisplayName,                          
        [Parameter(
            Mandatory = $False, Position = 2,
            ParameterSetName = '', ValueFromPipeline = $False)]
            [string]$SenderEmailAddress,   
        [Parameter(
            Mandatory = $False, Position = 3,
            ParameterSetName = '', ValueFromPipeline = $False)]
            [string][ValidateSet("True","False")]$SendStatusNotification,
        [Parameter(
            Mandatory = $False, Position = 4,
            ParameterSetName = '',ValueFromPipeline = $False)]
            [string][ValidateSet("True","False")]$SendSyncnotification,
        [Parameter(
            Mandatory = $False, Position = 5,
            ParameterSetName = '', ValueFromPipeline = $False)]
            [string]$SMTPHostname,
        [Parameter(
            Mandatory = $False, Position = 6,
            ParameterSetName = '', ValueFromPipeline = $False)]
            [int]$SMTPPort,
        [Parameter(
            Mandatory = $False, Position = 7,
            ParameterSetName = '', ValueFromPipeline = $False)]
            [string][ValidateSet("True","False")]$SmtpServerRequiresAuthentication,    
        [Parameter(
            Mandatory = $False, Position = 8,
            ParameterSetName = 'account', ValueFromPipeline = $False)]
            [string]$SmtpUserName,
        [Parameter(
            Mandatory = $False, Position = 9,
            ParameterSetName = '', ValueFromPipeline = $False)]
            [string][ValidateSet("Daily","Weekly")]$StatusNotificationFrequency,
        [Parameter(
            Mandatory = $False, Position = 10,
            ParameterSetName = '', ValueFromPipeline = $False)]
            [string]$StatusNotificationTimeOfDay,
        [Parameter(
            Mandatory = $False,Position = 11,
            ParameterSetName = '',ValueFromPipeline = $False)]
            [string]$UpdateServer,
        [Parameter(
            Mandatory = $False,Position = 12,
            ParameterSetName = 'account',ValueFromPipeline = $False)]
            [string]$SmtpPassword                                                                                                                                                              
            )   
#Configure Email Notifications
$email = $wsus.GetEmailNotificationConfiguration()
$ErrorActionPreference = 'stop'
Try {
    If ($StatusNotificationTimeOfDay) {
        #Validate Notification Time of Day Parameter
        If (!([regex]::ismatch($StatusNotificationTimeOfDay,"^\d{2}:\d{2}$"))) {
            Write-Error "$($StatusNotificationTimeOfDay) is not a valid time to use!`nMust be 'NN:NN'"
            }
        Else {                
            $email.StatusNotificationTimeOfDay = $StatusNotificationTimeOfDay
            }
        }
    If ($UpdateServer) {$email.UpdateServer = $UpdateServer}
    If ($EmailLanguage) {$email.EmailLanguage = $EmailLanguage}
    If ($SenderDisplayName) {$email.SenderDisplayName = $SenderDisplayName}
    If ($SenderEmailAddress) {
        #Validate Email Address Parameter
        If (!([regex]::ismatch($SenderEmailAddress,"^\w+@\w+\.com|mil|org|net$"))) {
            Write-Error "$($SenderEmailAddress) is not a valid email address!`nMust be 'xxxx@xxxxx.xxx'"
            }
        Else {                    
            $email.SenderEmailAddress = $SenderEmailAddress
            }
        }
    If ($SMTPHostname) {$email.SMTPHostname = $SMTPHostname}
    If ($SMTPPort) {$email.SMTPPort = $SMTPPort}
    If ($SmtpServerRequiresAuthentication) {$email.SmtpServerRequiresAuthentication = $SmtpServerRequiresAuthentication}
    If ($SmtpUserName) {$email.SmtpUserName = $SmtpUserName}
    If ($SmtpPassword) {$mail.SetSmtpUserPassword($SmtpPassword)}
    Switch ($StatusNotificationFrequency) {
        "Daily" {$email.StatusNotificationFrequency = [Microsoft.UpdateServices.Administration.EmailStatusNotificationFrequency]::Daily}
        "Weekly" {$email.StatusNotificationFrequency = [Microsoft.UpdateServices.Administration.EmailStatusNotificationFrequency]::Weekly}
        Default {$Null}
        }
    Switch ($SendStatusNotification) {
        "True" {$email.SendStatusNotification = 1}
        "False" {$email.SendStatusNotification = 0}
        Default {$Null}
        }        
    Switch ($SendSyncNotification) {
        "True" {$email.SendSyncNotification = 1}
        "False" {$email.SendSyncNotification = 0}
        Default {$Null}
        } 
    }    
Catch {
    Write-Error "$($error[0])"
    }
#Save Configuration Changes
Try {
    $email.Save()
    Write-Host -fore Green "Email settings changed"
    $email
    }        
Catch {
    Write-Error "$($error[0])"
    }    
}  

function Convert-WSUSTargetGroup {
<#  
.SYNOPSIS  
    Converts the WSUS group from ID to Name or Name to ID.
.DESCRIPTION
    Converts the WSUS group from ID to Name or Name to ID.
.PARAMETER Id
    GUID of the group to be converted to friendly name          
.PARAMETER Name
    Name of the group to be converted to a guid    
.NOTES  
    Name: Convert-WSUSTargetGroup
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Convert-WSUSTargetGroup -name "Domain Servers"

Description
-----------      
This command will convert the group name "Domain Servers" into the GUID format.

.EXAMPLE
Convert-WSUSTargetGroup -ID "b73ca6ed-5727-47f3-84de-015e03f6a88a"

Description
-----------    
This command will convert the given GUID into a friendly name.

#> 
[cmdletbinding(
	DefaultParameterSetName = 'name',
	ConfirmImpact = 'low'
)]
    Param(
        [Parameter(
            Mandatory = $False,
            Position = 2,
            ParameterSetName = 'id',
            ValueFromPipeline = $False)]
            [string]$Id,
        [Parameter(
            Mandatory = $False,
            Position = 3,
            ParameterSetName = 'name',
            ValueFromPipeline = $False)]
            [string]$Name                          
            )            
If ($name) {    
    Try {     
        $group = $wsus.GetComputerTargetGroups() | ? {$_.Name -eq $name}
        $group | Select -ExpandProperty ID
        }
    Catch {
        Write-Error "Unable to locate $($name)."
        }        
    }  
If ($id) {    
    Try {     
        $group = $wsus.GetComputerTargetGroups() | ? {$_.ID -eq $id}
        $group | Select -ExpandProperty Name
        }
    Catch {
        Write-Error "Unable to locate $($id)."
        }        
    }           
}  

function Get-WSUSClientsInGroup {
<#  
.SYNOPSIS  
    Retrieves a list of clients that are members of a group.
.DESCRIPTION
    Retrieves a list of clients that are members of a group.
.PARAMETER Id
    Retrieves list of clients in group by group guid.          
.PARAMETER Name
    Retrieves list of clients in group by group name.    
.NOTES  
    Name: Get-WSUSClientsInGroup
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Get-WSUSClientsInGroup -name "Domain Servers"

Description
-----------      
This command will list all clients that are members of the specified group via group name.

.EXAMPLE
Get-WSUSClientsInGroup -ID "b73ca6ed-5727-47f3-84de-015e03f6a88a"

Description
-----------    
This command will list all clients that are members of the specified group via the group guid.
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'name',
	ConfirmImpact = 'low'
)]
    Param(
        [Parameter(
            Mandatory = $False,
            Position = 2,
            ParameterSetName = 'name',            
            ValueFromPipeline = $False)]
            [string]$Name,
        [Parameter(
            Mandatory = $False,
            Position = 3,
            ParameterSetName = 'id',
            ValueFromPipeline = $False)]
            [string]$Id                           
            )                        
If ($id) {     
    ($wsus.GetComputerTargetGroups() | ? {$_.Id -eq $id}).GetComputerTargets()
    }
If ($name) {
    ($wsus.GetComputerTargetGroups() | ? {$_.name -eq $name}).GetComputerTargets()
    }    
}  

function Get-WSUSClient {
<#  
.SYNOPSIS  
    Retrieves information about a WSUS client.
.DESCRIPTION
    Retrieves information about a WSUS client.
.PARAMETER Computer
    Name of the client to search for. Accepts a partial name.
.NOTES  
    Name: Get-WSUSClient
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Get-WSUSClient -computer "server1"

Description
-----------      
This command will search for and display all computers matching the given input. 
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'wsus',
	ConfirmImpact = 'low'
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'wsus',
            ValueFromPipeline = $True)]
            [string]$Computer                                  
            )                
$ErrorActionPreference = 'stop'    
#Retrieve computer in WSUS
Try {      
    $wsus.SearchComputerTargets($computer)
    }
Catch {
    Write-Error "Unable to retrieve $($computer) from database."
    }    
}

function New-WSUSGroup {
<#  
.SYNOPSIS  
    Creates a new WSUS Target group.
.DESCRIPTION
    Creates a new WSUS Target group.
.PARAMETER Group
    Name of group being created.
.PARAMETER ParentGroupName
    Name of group being created.
.PARAMETER ParentGroupId
    Name of group being created.        
.NOTES  
    Name: New-WSUSGroup
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
New-WSUSGroup -name "TestGroup"

Description
-----------  
This command will create a new Target group called 'TestGroup'       
.EXAMPLE 
New-WSUSGroup -name "TestGroup" -parentgroupname "Domain Servers"

Description
-----------  
This command will create a new Target group called 'TestGroup' under the parent group 'Domain Servers'    
#> 
[cmdletbinding(
	DefaultParameterSetName = 'group',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = '',
            ValueFromPipeline = $True)]
            [string]$Group,
        [Parameter(
            Mandatory = $False,
            Position = 1,
            ParameterSetName = 'parentgroup',
            ValueFromPipeline = $True)]
            [string]$ParentGroupName,
        [Parameter(
            Mandatory = $False,
            Position = 2,
            ParameterSetName = 'parentgroup',
            ValueFromPipeline = $True)]
            [string]$ParentGroupId                                              
            ) 
Process {
    #Determine action based on Parameter Set Name
    Switch ($pscmdlet.ParameterSetName) {            
        "group" {
            Write-Verbose "Creating computer group"        
            If ($pscmdlet.ShouldProcess($group)) {
                #Create the computer target group
                $wsus.CreateComputerTargetGroup($group)
                "$($group) has been created."
                }
            }                
        "parentgroup" {
            If ($parentgroupname) {
                #Retrieve group based off of name
                Write-Verbose "Querying for parent group"
                $parentgroup = $wsus.getcomputertargetgroups() | ? {$_.name -eq $parentgroupname}
                If (!$parentgroup) {
                    Write-Error "Parent Group name `'$parentgroupname`' does not exist in WSUS!"
                    Break
                    }
                }
            If ($parentgroupid) {
                #Retrieve group based off of guid
                Write-Verbose "Querying for parent group"
                $parentgroup = $wsus.getcomputertargetgroups() | ? {$_.id -eq $parentgroupid}
                If (!$parentgroup) {
                    Write-Error "Parent Group id `'$parentgroupid`' does not exist in WSUS!"
                    Break
                    }                
                }                    
            Write-Verbose "Creating computer group"                
            If ($pscmdlet.ShouldProcess($group)) {
                #Create the computer target group
                $wsus.CreateComputerTargetGroup($group,$parentgroup)
                "$($group) has been created under $($parentgroup.Name)."
                }            
            }                
        }
    }                
}            

function Get-WSUSUpdate {
<#  
.SYNOPSIS  
    Retrieves information from a wsus update.
.DESCRIPTION
    Retrieves information from a wsus update. Depending on how the information is presented in the search, more
    than one update may be returned. 
.PARAMETER Update
    String to search for. This can be any string for the update to include
    KB article numbers, name of update, category, etc... Use of wildcards (*,%) not allowed in search!
.NOTES  
    Name: Get-WSUSUpdate
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
Get-WSUSUpdate -update "Exchange"

Description
-----------  
This command will list every update that has 'Exchange' in it.
.EXAMPLE
Get-WSUSUpdate -update "925474"

Description
-----------  
This command will list every update that has '925474' in it.
#> 
[cmdletbinding(
	DefaultParameterSetName = 'wsus',
	ConfirmImpact = 'low'
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'wsus',
            ValueFromPipeline = $True)]
            [string]$Update                                  
            )                
$ErrorActionPreference = 'stop'    
#Retrieve computer in WSUS
Try {      
    $wsus.SearchUpdates($update)
    }
Catch {
    Write-Error "Unable to retrieve $($update) from database."
    }    
}

function Remove-WSUSGroup {
<#  
.SYNOPSIS  
    Creates a new WSUS Target group.
.DESCRIPTION
    Creates a new WSUS Target group.
.PARAMETER Name
    Name of group being deleted.
.PARAMETER Id
    Id of group being deleted.       
.NOTES  
    Name: Remove-WSUSGroup
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
Remove-WSUSGroup  -name "Domain Servers"

Description
-----------  
This command will remove the Domain Servers WSUS Target group.  
.EXAMPLE 
Remove-WSUSGroup  -id "fc93e74e-ba59-4593-9ff7-690af1be695f"

Description
-----------  
This command will remove the Target group with ID 'fc93e74e-ba59-4593-9ff7-690af1be695f' from WSUS.       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'name',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)]
    Param(
        [Parameter(
            Mandatory = $False,
            Position = 0,
            ParameterSetName = 'name',
            ValueFromPipeline = $True)]
            [string]$Name,
        [Parameter(
            Mandatory = $False,
            Position = 1,
            ParameterSetName = 'id',
            ValueFromPipeline = $True)]
            [string]$Id
        )            
Process {
    #Determine action based on Parameter Set Name
    Switch ($pscmdlet.ParameterSetName) {            
        "name" {
            Write-Verbose "Querying for computer group"
            $group = $wsus.getcomputertargetgroups() | ? {$_.Name -eq $name}
            If (!$group) {
                Write-Error "Group $name does not exist in WSUS!"
                Break
                }
            Else {                               
                If ($pscmdlet.ShouldProcess($name)) {
                    #Create the computer target group
                    $group.Delete()
                    "$($name) has been deleted from WSUS."
                    }
                }                    
            }                
        "id" {
            Write-Verbose "Querying for computer group"
            $group = $wsus.getcomputertargetgroups() | ? {$_.id -eq $id}
            If (!$group) {
                Write-Error "Group $id does not exist in WSUS!"
                Break
                }                                       
            If ($pscmdlet.ShouldProcess($id)) {
                #Create the computer target group
                $group.Delete()
                "$($id) has been deleted from WSUS."
                }            
            }                
        }
    }                
} 

function Add-WSUSClientToGroup {
<#  
.SYNOPSIS  
    Adds a computer client to an existing WSUS group.
.DESCRIPTION
    Adds a computer client to an existing WSUS group.
.PARAMETER Group
    Name of group to add client to.
.PARAMETER Computer
    Name of computer being added to group.        
.NOTES  
    Name: Add-WSUSClientToGroup
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
Add-WSUSClientToGroup -group "Domain Servers" -computer "server1"

Description
-----------  
This command will add the client "server1" to the WSUS target group "Domain Servers".       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'group',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'group',
            ValueFromPipeline = $True)]
            [string]$Group,
        [Parameter(
            Mandatory = $False,
            Position = 1,
            ParameterSetName = 'group',
            ValueFromPipeline = $True)]
            [string]$Computer                                             
            )
#Verify Computer is in WSUS
Write-Verbose "Validating client in WSUS"
$client = Get-WSUSClient -computer $computer
If ($client) {
    #Get group object
    Write-Verbose "Retrieving group"
    $targetgroup = $wsus.getcomputertargetgroups() | ? {$_.Name -eq $group}
    If (!$targetgroup) {
        Write-Error "Group $group does not exist in WSUS!"
        Break
        }    
    #Add client to group
    Write-Verbose "Adding client to group"
    If ($pscmdlet.ShouldProcess($($client.fulldomainname))) {
        $targetgroup.AddComputerTarget($client)
        "$($client.FullDomainName) has been added to $($group)"
        }
    }
Else {
    Write-Error "Computer: $computer is not in WSUS!"
    }    
}           

function Remove-WSUSClientFromGroup {
<#  
.SYNOPSIS  
    Removes a computer client to an existing WSUS group.
.DESCRIPTION
    Removes a computer client to an existing WSUS group.
.PARAMETER Group
    Name of group to remove client from.
.PARAMETER Computer
    Name of computer being removed from group.        
.NOTES  
    Name: Remove-WSUSClientToGroup
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
Remove-WSUSClientFromGroup -group "Domain Servers" -computer "server1"

Description
-----------  
This command will remove the client "server1" from the WSUS target group "Domain Servers".       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'group',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'group',
            ValueFromPipeline = $True)]
            [string]$Group,
        [Parameter(
            Mandatory = $False,
            Position = 1,
            ParameterSetName = 'group',
            ValueFromPipeline = $True)]
            [string]$Computer                                             
            )
#Verify Computer is in WSUS
$client = Get-WSUSClient -computer $computer
If ($client) {
    #Get group object
    Write-Verbose "Retrieving group"
    $targetgroup = $wsus.getcomputertargetgroups() | ? {$_.Name -eq $group}
    If (!$targetgroup) {
        Write-Error "Group $group does not exist in WSUS!"
        Break
        }
    #Remove client from group
    Write-Verbose "Removing client to group"
    If ($pscmdlet.ShouldProcess($($client.fulldomainname))) {
        $targetgroup.RemoveComputerTarget($client)
        "$($client.fulldomainname) has been removed from $($group)"
        }
    }
Else {
    Write-Error "Computer: $computer is not in WSUS!"
    }    
}             

function Get-WSUSDatabaseConfig {
<#  
.SYNOPSIS  
    Displays the current WSUS database configuration.
.DESCRIPTION
    Displays the current WSUS database configuration.
.NOTES  
    Name: Get-WSUSDatabaseConfig
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
Get-WSUSDatabaseConfig 

Description
-----------  
This command will display the configuration information for the WSUS connection to a database.       
#> 
[cmdletbinding()]  
Param () 

$wsus.GetDatabaseConfiguration()      
} 

function Get-WSUSSubscription {
<#  
.SYNOPSIS  
    Displays WSUS subscription information.
.DESCRIPTION
    Displays WSUS subscription information. You can view the next synchronization time, who last modified the schedule, etc...
.NOTES  
    Name: Get-WSUSSubscription
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Get-WSUSSubscription      

Description
-----------  
This command will list out the various subscription information on the WSUS server.
#> 
[cmdletbinding()]  
Param () 

$wsus.GetSubscription()     
} 

function Deny-WSUSUpdate {
<#  
.SYNOPSIS  
    Declines an update on WSUS.
.DESCRIPTION
    Declines an update on WSUS. Use of the -whatif is advised to be sure you are declining the right patch or patches.
.PARAMETER InputObject
    Collection of update/s being declined. This must be an object, otherwise it will fail.      
.PARAMETER Update
    Name of update/s being declined.    
.NOTES  
    Name: Deny-WSUSUpdate
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE
Get-WSUSUpdate -update "Exchange 2010" | Deny-WSUSUpdate 

Description
-----------  
This command will decline all updates with 'Exchange 2010' in its metadata.
.EXAMPLE
Deny-WSUSUpdate  -Update "Exchange 2010"

Description
-----------  
This command will decline all updates with 'Exchange 2010' in its metadata.
.EXAMPLE
$updates = Get-WSUSUpdate -update "Exchange 2010" 
Deny-WSUSUpdate -InputObject $updates

Description
-----------  
This command will decline all updates with 'Exchange 2010' in its metadata.   
.EXAMPLE
Get-WSUSUpdate -update "Exchange 2010" | Deny-WSUSUpdate

Description
-----------  
This command will decline all updates with 'Exchange 2010' in its metadata via the pipeline.    
#> 
[cmdletbinding(
	DefaultParameterSetName = 'collection',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'collection',
            ValueFromPipeline = $True)]
            [system.object]$InputObject,                                          
        [Parameter(
            Mandatory = $False,
            Position = 1,
            ParameterSetName = 'string',
            ValueFromPipeline = $False)]
            [string]$Update                                          
            )                       
Process {
    Switch ($pscmdlet.ParameterSetName) {
        "Collection" {
            Write-Verbose "Using 'Collection' set name"        
            #Change the collection to patches for use in loop
            $patches = $inputobject        
            }
        "String" {
            Write-Verbose "Using 'String' set name"        
            #Gather all updates from given information
            Write-Verbose "Searching for updates"
            $patches = $wsus.SearchUpdates($update)       
            }
        } 
    ForEach ($patch in $patches) {
        #Decline the update
        Write-Verbose "Declining update"                
        If ($pscmdlet.ShouldProcess($($patch.title))) {
            $patch.Decline($True) | out-null
            #Print out report of what was declined
            New-Object PSObject -Property @{
                Patch = $patch.title
                ApprovalAction = "Declined"
                }
            }         
        }
    }    
}            

function Approve-WSUSUpdate {
<#  
.SYNOPSIS  
    Approves a WSUS update for a specific group with an optional deadline.
.DESCRIPTION
    Approves a WSUS update for a specific group with an optional deadline.
.PARAMETER InputObject
    Update object that is being approved.    
.PARAMETER Update
    Name of update being approved.
.PARAMETER Group
    Name of group which will receive the update.       
.PARAMETER Deadline
    Optional deadline for client to install patch.
.PARAMETER Action
    Type of approval action to take on update. Accepted values are Install, Approve, Uninstall and NotApproved       
.NOTES  
    Name: Approve-WSUSUpdate
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Approve-WSUSUpdate -update "KB979906" -Group "Domain Servers" -Action Install

Description
----------- 
This command will approve all updates with the KnowledgeBase number of KB979906 for the 'Domain Servers' group and
the action command of 'Install'.
.EXAMPLE  
Approve-WSUSUpdate -update "KB979906" -Group "Domain Servers" -Action Install -Deadline (get-Date).AddDays(3)

Description
----------- 
This command will approve all updates with the KnowledgeBase number of KB979906 for the 'Domain Servers' group and
the action command of 'Install' and sets a deadline for 3 days from when this command is run.
.EXAMPLE  
Get-WSUSUpdate -Update "KB979906" | Approve-WSUSUpdate -Group "Domain Servers" -Action Install

Description
----------- 
This command will take the collection of objects from the Get-WSUSUpdate command and then approve all updates for 
the 'Domain Servers' group and the action command of 'Install'.
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'string',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)]
    Param(
        [Parameter(            
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'collection',
            ValueFromPipeline = $True)]
            [system.object]
            [ValidateNotNullOrEmpty()]
            $InputObject,     
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'string',
            ValueFromPipeline = $False)]
            [string]$Update,           
        [Parameter(
            Mandatory = $True,
            Position = 1,
            ParameterSetName = '',
            ValueFromPipeline = $False)]
            [string]
            [ValidateSet("Install", "All", "NotApproved","Uninstall")]
            $Action,              
        [Parameter(
            Mandatory = $True,
            Position = 2,
            ParameterSetName = '',
            ValueFromPipeline = $False)]
            [string]$Group,
        [Parameter(
            Mandatory = $False,
            Position = 3,
            ParameterSetName = '',
            ValueFromPipeline = $False)]
            [datetime]$Deadline                      
        )
Begin {
    #Define the actions available
    Write-Verbose "Defining available approval actions"
    Switch ($Action) {
        "Install" {
            Write-Verbose "Action: Install"
            $Action = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::Install
            }
        "All" {
            Write-Verbose "Action: All"
            $Action = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::All
            }
        "NotApproved" {
            Write-Verbose "Action: NotApproved"
            $Action = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::NotApproved
            }
        "Uninstall" {
            Write-Verbose "Action: Uninstall"
            $Action = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::Uninstall
            }
        }
    
    #Search for group specified
    Write-Verbose "Searching for group"        
    $targetgroup = $wsus.getcomputertargetgroups() | ? {$_.Name -eq $group}
    If (!$targetgroup) {
        Write-Error "Group $group does not exist in WSUS!"
        Break
        }       
    }                    
Process {
    #Perform appropriate action based on Parameter set name
    Switch ($pscmdlet.ParameterSetName) {            
        "collection" {
            Write-Verbose "Using 'Collection' set name"
            #Change the variable that will hold the objects
            $patches = $inputobject    
            }                
        "string" {
            Write-Verbose "Using 'String' set name"
            #Search for updates
            Write-Verbose "Searching for update/s"
            $patches = $wsus.SearchUpdates($update)
            If (!$patches) {
                Write-Error "Update $update could not be found in WSUS!"
                Break
                }                     
            }                
        } 
    ForEach ($patch in $patches) {
        #Determine if Deadline is required
        If ($deadline) {
            Write-Verbose "Approving update with a deadline."
            If ($pscmdlet.ShouldProcess($($patch.title))) {
                #Create the computer target group
                $patch.Approve($action,$targetgroup,$deadline) | out-null
                #Print out report of what was approved
                New-Object PSObject -Property @{
                    Patch = $patch.title
                    TargetGroup = $group
                    ApprovalAction = $action
                    Deadline = "$($deadline)"
                    } 
                }        
            }
        Else {    
            #Approve the patch
            Write-Verbose "Approving update without a deadline."                              
            If ($pscmdlet.ShouldProcess($($patch.title))) {
                #Create the computer target group
                $patch.Approve($action,$targetgroup) | out-null
                #Print out report of what was approved
                New-Object PSObject -Property @{
                    Patch = $patch.title
                    TargetGroup = $group
                    ApprovalAction = $action
                    }               
                }
            }                 
        }
    }                
} 

function Get-WSUSGroup {
<#  
.SYNOPSIS  
    Retrieves specific WSUS target group.
.DESCRIPTION
    Retrieves specific WSUS target group.
.PARAMETER Name
    Name of group to search for. No wildcards allowed. 
.PARAMETER Id
    GUID of group to search for. No wildcards allowed.       
.NOTES  
    Name: Get-WSUSGroups
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Get-WSUSGroup -name "Domain Servers"

Description
----------- 
This command will search for the group and display the information for Domain Servers"

.EXAMPLE  
Get-WSUSGroup -ID "0b5ba818-021e-4238-8098-7245b0f90557"

Description
----------- 
This command will search for the group and display the information for the WSUS 
group guid 0b5ba818-021e-4238-8098-7245b0f90557"
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'name',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
    )]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'name',
            ValueFromPipeline = $False)]
            [string]$Name,
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'id',
            ValueFromPipeline = $False)]
            [string]$Id            
        )            
Switch ($pscmdlet.ParameterSetName) {
    "name" {$wsus.GetComputerTargetGroups() | ? {$_.name -eq $name}}
    "id"   {$wsus.GetComputerTargetGroups() | ? {$_.id -eq $id}}
    }
}  

function Remove-WSUSUpdate {
<#  
.SYNOPSIS  
    Removes an update on WSUS.
.DESCRIPTION
    Removes an update on WSUS. Use of the -whatif is advised to be sure you are declining the right patch or patches.
.PARAMETER Update
    Name of update being removed.       
.NOTES  
    Name: Remove-WSUSUpdate
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Remove-WSUSUpdate -update "KB986569"

Description
----------- 
This command will remove all instances of KB986569 from WSUS.
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'update',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'update',
            ValueFromPipeline = $True)]
            [string]$Update                                          
            ) 
Begin {
    #Gather all updates from given information
    Write-Verbose "Searching for updates"
    $patches = $wsus.SearchUpdates($update)
    }            
Process {
    ForEach ($patch in $patches) {
        #Storing update guid
        $guid = ($patch.id).updateid              
        If ($pscmdlet.ShouldProcess($($patch.title))) {
            $wsus.DeleteUpdate($id,$True)
            "$($patch.title) has been deleted from WSUS"
            }         
        }
    }    
}   

function Stop-WSUSDownloads {
<#  
.SYNOPSIS  
    Cancels all current WSUS downloads.
.DESCRIPTION
    Cancels all current WSUS downloads.      
.NOTES  
    Name: Stop-WSUSDownloads
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
Stop-WSUSDownloads

Description
-----------  
This command will stop all updates being downloaded to the WSUS server.
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'update',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)]
    Param() 
#Cancel all downloads running on WSUS       
If ($pscmdlet.ShouldProcess($($wsus.name))) {
    $wsus.CancelAllDownloads()
    "Downloads have been cancelled."
    }
}    

function Resume-WSUSDownloads {
<#  
.SYNOPSIS  
    Resumes all current WSUS downloads.
.DESCRIPTION
    Resumes all current WSUS downloads that had been cancelled.
.NOTES  
    Name: Resume-WSUSDownloads
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
Resume-WSUSDownloads

Description
----------- 
This command will resume the downloading of updates to the WSUS server. 
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'update',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)]
    Param() 
#Cancel all downloads running on WSUS       
If ($pscmdlet.ShouldProcess($($wsus.name))) {
    $wsus.ResumeAllDownloads()
    "Downloads have been resumed."
    }
} 

function Stop-WSUSUpdateDownload {
<#  
.SYNOPSIS  
    Stops update download after approval.
.DESCRIPTION
    Stops update download after approval.
.PARAMETER update
    Name of update to cancel download.       
.NOTES  
    Name: Stop-WSUSUpdateDownload
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Stop-WSUSUpdateDownload -update "KB965896"

Description
----------- 
This command will cancel the download of update KB956896.       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'update',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'update',
            ValueFromPipeline = $True)]
            [string]$update                                          
            ) 
Begin {
    #Gather all updates from given information
    Write-Verbose "Searching for updates"
    $patches = $wsus.SearchUpdates($update)
    }            
Process {
    If ($patches) {
        ForEach ($patch in $patches) {
            Write-Verbose "Cancelling update download"                
            If ($pscmdlet.ShouldProcess($($patch.title))) {
                $patch.CancelDownload()
                "$($patch.title) download has been cancelled."
                }         
            }
        }
    Else {
        Write-Warning "No patches found that need downloading cancelled."
        }        
    }    
} 

function Resume-WSUSUpdateDownload {
<#  
.SYNOPSIS  
    Resumes previously cancelled update download after approval.
.DESCRIPTION
    Resumes previously cancelled update download after approval.
.PARAMETER Update
    Name of cancelled update download to resume download.       
.NOTES  
    Name: Resume-WSUSUpdateDownload
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Resume-WSUSUpdateDownload -update "KB965896"

Description
----------- 
This command will resume the download of update KB956896 that was previously cancelled.       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'update',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'update',
            ValueFromPipeline = $True)]
            [string]$Update                                          
            ) 
Begin {
    #Gather all updates from given information
    Write-Verbose "Searching for updates"
    $patches = $wsus.SearchUpdates($update)
    }                
Process {
    If ($patches) {
        ForEach ($patch in $patches) {
            Write-Verbose "Resuming update download"                
            If ($pscmdlet.ShouldProcess($($patch.title))) {
                $patch.ResumeDownload()
                "$($patch.title) download has been resumed."
                }         
            }
        }
    Else {
        Write-Warning "No patches found needing to resume download!"
        }        
    }    
} 

function Start-WSUSCleanup {
<#  
.SYNOPSIS  
    Performs a cleanup on WSUS based on user inputs.
.DESCRIPTION
    Performs a cleanup on WSUS based on user inputs.
.PARAMETER DeclineSupersededUpdates
    Declined Superseded Updates will be removed.
.PARAMETER DeclineExpiredUpdates
    Expired updates should be declined.
.PARAMETER CleanupObsoleteUpdates
    Delete obsolete updates from the database.
.PARAMETER CompressUpdates
    Obsolete revisions to updates should be deleted from the database.
.PARAMETER CleanupObsoleteComputers
    Delete obsolete computers from the database.
.PARAMETER CleanupUnneededContentFiles 
    Delete unneeded update files.   
.NOTES  
    Name: Start-WSUSCleanup
    Author: Boe Prox
    DateCreated: 24SEPT2010            
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Start-WSUSCleanup -CompressUpdates -CleanupObsoleteComputers

Description
----------- 
This command will run the WSUS cleanup wizard and delete obsolete computers from the database and delete obsolete update 
revisions from the database.  
.EXAMPLE 
Start-WSUSCleanup -CompressUpdates -CleanupObsoleteComputers -DeclineExpiredUpdates -CleanupObsoleteUpdates -CleanupUnneededContentFiles 

Description
----------- 
This command performs a full WSUS cleanup against the database.      
#> 
[cmdletbinding(
	DefaultParameterSetName = 'cleanup',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True
)]
    Param(
        [Parameter(
            Mandatory = $False,
            Position = 0,
            ParameterSetName = 'cleanup',
            ValueFromPipeline = $False)]
            [switch]$DeclineSupersededUpdates,   
        [Parameter(
            Mandatory = $False,
            Position = 1,
            ParameterSetName = 'cleanup',
            ValueFromPipeline = $False)]
            [switch]$DeclineExpiredUpdates,  
        [Parameter(
            Mandatory = $False,
            Position = 2,
            ParameterSetName = 'cleanup',
            ValueFromPipeline = $False)]
            [switch]$CleanupObsoleteUpdates,  
        [Parameter(
            Mandatory = $False,
            Position = 3,
            ParameterSetName = 'cleanup',
            ValueFromPipeline = $False)]
            [switch]$CompressUpdates,  
        [Parameter(
            Mandatory = $False,
            Position = 4,
            ParameterSetName = 'cleanup',
            ValueFromPipeline = $False)]
            [switch]$CleanupObsoleteComputers,  
        [Parameter(
            Mandatory = $False,
            Position = 5,
            ParameterSetName = 'cleanup',
            ValueFromPipeline = $False)]
            [switch]$CleanupUnneededContentFiles                                                                                                     
            ) 
Begin {            
    #Create cleanup scope
    $cleanScope = new-object Microsoft.UpdateServices.Administration.CleanupScope
    #Create cleanup manager object
    $cleanup = $wsus.GetCleanupManager()

    #Determine what will be in the scope
    If ($DeclineSupersededUpdates) {
        $cleanScope.DeclineSupersededUpdates = $True
        }
    If ($DeclineExpiredUpdates) {
        $cleanScope.DeclineExpiredUpdates = $True
        }
    If ($CleanupObsoleteUpdates) {
        $cleanScope.CleanupObsoleteUpdates = $True
        }        
    If ($CompressUpdates) {
        $cleanScope.CompressUpdates = $True
        }
    If ($CleanupObsoleteComputers) {
        $cleanScope.CleanupObsoleteComputers = $True
        }
    If ($CleanupUnneededContentFiles) {
        $cleanScope.CleanupUnneededContentFiles = $True
        }
    }
Process {
    Write-Host "Beginning cleanup"                
    If ($pscmdlet.ShouldProcess($($wsus.name))) {
        $cleanup.PerformCleanup($cleanScope)
        }     
    }                        

}

function Get-WSUSChildServers {
<#  
.SYNOPSIS  
    Retrieves all WSUS child servers.
.DESCRIPTION
    Retrieves all WSUS child servers.
.NOTES  
    Name: Get-WSUSChildServers
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Get-WSUSChildServers

Description
----------- 
This command will display all of the Child WSUS servers.
       
#> 
[cmdletbinding()]  
Param () 
#Gather all child servers in WSUS    
$wsus.GetChildServers()
}

function Get-WSUSDownstreamServers {
<#  
.SYNOPSIS  
    Retrieves all WSUS downstream servers.
.DESCRIPTION
    Retrieves all WSUS downstream servers.
.NOTES  
    Name: Get-WSUSDownstreamServers
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Get-WSUSDownstreamServers

Description
----------- 
This command will display a list of all of the downstream WSUS servers.
       
#> 
[cmdletbinding()]  
Param () 
#Gather all child servers in WSUS    
$wsus.GetDownstreamServers()
}

function Get-WSUSContentDownloadProgress {
<#  
.SYNOPSIS  
    Retrieves the progress of currently downloading updates. Displayed in bytes downloaded.
.DESCRIPTION
    Retrieves the progress of currently downloading updates. Displayed in bytes downloaded.
.PARAMETER Monitor
    Runs a background job to monitor currently running content download and notifies user when completed.    
.NOTES  
    Name: Get-WSUSContentDownloadProgress
    Author: Boe Prox
    DateCreated: 24SEPT2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Get-WSUSContentDownloadProgress

Description
----------- 
This command will display the current progress of the content download.
.EXAMPLE  
Get-WSUSContentDownloadProgress -monitor

Description
----------- 
This command will create a background job that will monitor the progress and alert the user via pop-up message that
the download has been completed.
       
#> 
[cmdletbinding()]  
Param (
    [Parameter(
        Mandatory = $False,
        Position = 0,
        ParameterSetName = 'monitor',
        ValueFromPipeline = $False)]
        [switch]$Monitor
    )
If ($monitor) {
    #Stop and remove same jobs if existing
        $job = Get-Job
    If ($job) {
        $job = Get-Job -Name "WSUSSyncProgressMonitor"
        }
    If ($job) {
        Get-Job -Name "WSUSContentProgressMonitor" | Stop-Job
        Get-Job -Name "WSUSContentProgressMonitor" | Remove-Job
        }
    Start-Job -Name "WSUSContentProgressMonitor" -ArgumentList $wsus -ScriptBlock {
        Param (
            $wsus
            )
        #Load required assemblies for message window    
        [void] [System.Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”)            
        $progress = $wsus.GetContentDownloadProgress()            
        While ($progress.TotalBytesToDownload -ne $progress.DownloadedBytes) {
            $null
            }
        [System.Windows.Forms.MessageBox]::Show("Content download has been completed on WSUS",”Information”)            
        } | Out-Null 
    }
Else {
    #Gather all child servers in WSUS    
    $wsus.GetContentDownloadProgress()
    }         
}

function Remove-WSUSClient {
<#  
.SYNOPSIS  
    Removes client from WSUS.
.DESCRIPTION
    Removes client from WSUS.
.PARAMETER Computer
    Name of the client to remove from WSUS.
.PARAMETER InputObject
    Computer object that is being removed.     
.NOTES  
    Name: Remove-WSUSClient
    Author: Boe Prox
    DateCreated: 12NOV2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Remove-WSUSClient -computer "server1"

Description
-----------      
This command will remove 'server1' from WSUS. 
.EXAMPLE  
Get-WSUSClient -computer "server1" | Remove-WSUSClient

Description
-----------      
This command will remove 'server1' from WSUS. 
.EXAMPLE  
Get-WSUSClient -computer "servers" | % {Remove-WSUSClient -inputobject $_}

Description
-----------      
This command will remove multiple servers from WSUS. 
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'collection',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True    
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'string',
            ValueFromPipeline = $True)]
            [string]$Computer,
        [Parameter(            
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'collection',
            ValueFromPipeline = $True)]
            [system.object]
            [ValidateNotNullOrEmpty()]
            $InputObject                                              
            )                
$ErrorActionPreference = 'continue' 
Switch ($pscmdlet.ParameterSetName) {        
   "string" {
        Write-Verbose "String parameter"
        #Retrieve computer in WSUS
        Try { 
            Write-Verbose "Searching for computer"     
            $client = $wsus.SearchComputerTargets($computer)
            }
        Catch {
            Write-Error "Unable to retrieve $($computer) from database."
            } 
        }
    "Collection" {
        Write-Verbose "Collection parameter"
        $client = $inputobject
        }
    }                               
#Remove client from WSUS
If ($pscmdlet.ShouldProcess($computer)) {
    Try {
        Write-Verbose "Removing computer from WSUS"
        $client | % -process {$_.Delete()}
        Write-Host -fore Green "$($Client.FullDomainName) removed from WSUS"
        }
    Catch {
        Write-Error "Unable to remove $($client.fulldomainname) from WSUS."
        }  
    }                 
}

function Get-WSUSClientGroupMembership {
<#  
.SYNOPSIS  
    Lists all Target Groups that a client is a member of in WSUS.
.DESCRIPTION
    Lists all Target Groups that a client is a member of in WSUS.
.PARAMETER Computer
    Name of the client to check group membership.
.PARAMETER InputObject
    Computer object being used to check group membership.     
.NOTES  
    Name: Get-WSUSClientGroupMembership
    Author: Boe Prox
    DateCreated: 12NOV2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Get-WSUSClientGroupMembership -computer "server1"

Description
-----------      
This command will retrieve the group membership/s of 'server1'. 
.EXAMPLE  
Get-WSUSClient -computer "server1" | Get-WSUSClientGroupMembership

Description
-----------      
This command will retrieve the group membership/s of 'server1'. 
.EXAMPLE  
Get-WSUSClient -computer "servers" | % {Get-WSUSClientGroupMembership -inputobject $_}

Description
-----------      
This command will retrieve the group membership/s of each server. 
       
#> 
[cmdletbinding(
	DefaultParameterSetName = 'collection',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True    
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'string',
            ValueFromPipeline = $True)]
            [string]$Computer,
        [Parameter(            
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'collection',
            ValueFromPipeline = $True)]
            [system.object]
            [ValidateNotNullOrEmpty()]
            $InputObject                                              
            )                
Switch ($pscmdlet.ParameterSetName) {        
   "string" {
        Write-Verbose "String parameter"
        #Retrieve computer in WSUS
        Try { 
            Write-Verbose "Searching for computer"     
            $client = $wsus.SearchComputerTargets($computer)
            }
        Catch {
            Write-Error "Unable to retrieve $($computer) from database."
            } 
        }
    "Collection" {
        Write-Verbose "Collection parameter"
        $client = $inputobject
        }
    } 
#List group membership of client
$client | % -process {$_.GetComputerTargetGroups()}
}

Function Get-WSUSInstallApprovalRules {
<#  
.SYNOPSIS  
    Lists the currently configured Automatic Install Approval Rules on WSUS.
.DESCRIPTION
    Lists the currently configured Automatic Install Approval Rules on WSUS.
.NOTES  
    Name: Get-WSUSInstallApprovalRules
    Author: Boe Prox
    DateCreated: 08DEC2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
Get-WSUSInstallApprovalRules

Description
-----------  
This command will display the configuration information for the WSUS connection to a database.       
#> 
[cmdletbinding()]  
    Param()
$wsus.GetInstallApprovalRules()        
}

Function New-WSUSInstallApprovalRule {
<#  
.SYNOPSIS  
    Creates a new Install Approval Rule in WSUS.
.DESCRIPTION
    Creates a new Install Approval Rule in WSUS.
.PARAMETER Name
    Name of the new Install Approval Rule
.PARAMETER Enable
    Enables the approval rule after created
.PARAMETER Categories
    Collection of categories that will be applied to the rule. Use Get-WSUSUpdateCategories to gather the collection.
.PARAMETER Group
    Collection of Computer Target Groups that will be applied to the rule.  Use Get-WSUSGroups to gather the collection.
.PARAMETER Classifications 
    Collection of Update Classifications that will be applied to the rule.  Use Get-WSUSUpdateClassifications for the collection.
.PARAMETER PassThru       
.NOTES  
    Name: New-WSUSInstallApprovalRule
    Author: Boe Prox
    DateCreated: 08DEC2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
New-WSUSInstallApprovalRule -Name 'NewApproval'

Description
-----------
Creates a new rule with nothing configured named 'NewApproval'

.EXAMPLE  
$cat = Get-WSUSUpdateCategories | ? {$_.Title -eq "Windows Server 2008"}
$group = Get-WSUSGroups | ? {$_.Name -eq "Test"}
$class = Get-WSUSUpdateClassifications | ? {$_.Title -eq "Updates"}
New-WSUSInstallApprovalRule -Name "Rule1" -Category $cat -Classification $class -Group $group -Enable

Description
-----------
Creates a new rule named 'NewApproval' with groups, categories and classifications configured and enables the rule.
#> 
[cmdletbinding(
	DefaultParameterSetName = 'Name',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True    
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = '',
            ValueFromPipeline = $True)]
            [string]$Name,  
        [Parameter(
            Mandatory = $False,
            Position = 2,
            ParameterSetName = '',
            ValueFromPipeline = $False)]
            [switch]$Enable, 
        [Parameter(
            Mandatory = $False,
            Position = 3,
            ParameterSetName = 'Properties',
            ValueFromPipeline = $False)]
            [System.Object]$Category,  
        [Parameter(
            Mandatory = $False,
            Position = 4,
            ParameterSetName = 'Properties',
            ValueFromPipeline = $False)]
            [System.Object]$Group, 
        [Parameter(
            Mandatory = $False,
            Position = 5,
            ParameterSetName = 'Properties',
            ValueFromPipeline = $False)]
            [System.Object]$Classification,
        [Parameter(
            Mandatory = $False,
            Position = 6,
            ParameterSetName = '',
            ValueFromPipeline = $False)]
            [Switch]$PassThru                                                                                                                                 
            )
Begin {
    #Define the required action for the rule
    Write-Verbose "Setting the Action to 'Install'"
    $install = [Microsoft.UpdateServices.Administration.AutomaticUpdateApprovalAction]::Install       
    }
Process {
    If ($pscmdlet.ShouldProcess($Name)) {
        #Create the Rule
        Write-Verbose "Creating Approval Rule"
        $rule = $wsus.CreateInstallApprovalRule($Name)
        }
    #Begin setting the properties of the Rule
    If ($psboundparameters.keys -contains "Category") {
        #Create the update collections object
        Write-Verbose "Creating collection of categories"
        $cat_coll = New-Object Microsoft.UpdateServices.Administration.UpdateCategoryCollection
        #Add categories to collection
        Write-Verbose "Adding categories to collection"
        $cat_coll.AddRange($Category)
        #Set the categories for rule
        If ($pscmdlet.ShouldProcess($Name)) {        
            Write-Verbose "Setting categories on rule"
            $rule.SetCategories($cat_coll)
            }
        }
    If ($psboundparameters.keys -contains "Group") {
        #Create the update collections object
        Write-Verbose "Creating collection of groups"
        $group_coll = New-Object Microsoft.UpdateServices.Administration.ComputerTargetGroupCollection
        #Add groups to collection
        Write-Verbose "Adding groups to collection"
        $group_coll.AddRange($group)
        If ($pscmdlet.ShouldProcess($Name)) {        
            #Set the groups for rule
            Write-Verbose "Setting groups on rule"
            $rule.SetComputerTargetGroups($group_coll)
            }
        }
    If ($psboundparameters.keys -contains "Classification") {
        #Create the update collections object
        Write-Verbose "Creating collection of classifications"
        $class_coll = New-Object Microsoft.UpdateServices.Administration.UpdateClassificationCollection
        #Add classifications to collection
        Write-Verbose "Adding classifications to collection"
        $class_coll.AddRange($classification)
        If ($pscmdlet.ShouldProcess($Name)) {        
            #Set the classification for rule
            Write-Verbose "Setting Classification on rule"
            $rule.SetUpdateClassifications($class_coll)
            }
        } 
    If ($Enable) {
        If ($pscmdlet.ShouldProcess($Name)) {        
            #Enable the rule for use
            Write-Verbose "Enabling Rule"
            $rule.Enabled = $True
            }
        }
    }        
End{ 
    If ($pscmdlet.ShouldProcess($Name)) {        
        #Save the Rule
        Write-Verbose "Saving new rule"
        $rule.Save()
        Write-Host -fore Green "Rule $($name) has been created."
        }
                
    If ($PassThru) {
        Write-Output $rule
        }  
    }                                                               
}

Function Set-WSUSInstallApprovalRule {
<#  
.SYNOPSIS  
    Configures an existing Approval Rule in WSUS
.DESCRIPTION
    Configures an existing Approval Rule in WSUS
.PARAMETER Name
    Name of the Install Approval Rule
.PARAMETER Enable
    Enables the approval rule
.PARAMETER Categories
    Collection of categories that will be applied to the rule. Use Get-WSUSUpdateCategories to gather the collection.
.PARAMETER Group
    Collection of Computer Target Groups that will be applied to the rule.  Use Get-WSUSGroups to gather the collection.
.PARAMETER Classifications 
    Collection of Update Classifications that will be applied to the rule.  Use Get-WSUSUpdateClassifications for the collection.
.PARAMETER Disable
    Disable the rule       
.NOTES  
    Name: New-WSUSInstallApprovalRule
    Author: Boe Prox
    DateCreated: 08DEC2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Set-WSUSInstallApprovalRule -Name "Rule1" -Enable

Description
-----------      
Enables Rule1 to run on WSUS   
.EXAMPLE  
Set-WSUSInstallApprovalRule -Name "Rule1" -Disable

Description
-----------      
Disables Rule1 on WSUS  
.EXAMPLE  
$cat = Get-WSUSUpdateCategories | ? {$_.Title -eq "Windows Server 2008"}
$group = Get-WSUSGroups | ? {$_.Name -eq "Test"}
$class = Get-WSUSUpdateClassifications | ? {$_.Title -eq "Updates"}
Set-WSUSInstallApprovalRule -Name "Rule1" -Category $cat -Classification $class -Group $group

Description
-----------      
Configures Approval Rule1 with classification, group and categories on rule. First the holders for the category, group and classification 
collections are created to be supplied to the command. Then the command is run.
#> 
[cmdletbinding(
	DefaultParameterSetName = '',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True    
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'name',
            ValueFromPipeline = $True)]
            [string]$Name,
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'object',
            ValueFromPipeline = $True)]
            [system.object]$InputObject,               
        [Parameter(
            Mandatory = $False,
            Position = 2,
            ParameterSetName = '',
            ValueFromPipeline = $False)]
            [switch]$Enable, 
        [Parameter(
            Mandatory = $False,
            Position = 3,
            ParameterSetName = '',
            ValueFromPipeline = $False)]
            [System.Object]$Category,  
        [Parameter(
            Mandatory = $False,
            Position = 4,
            ParameterSetName = '',
            ValueFromPipeline = $False)]
            [System.Object]$Group, 
        [Parameter(
            Mandatory = $False,
            Position = 5,
            ParameterSetName = '',
            ValueFromPipeline = $False)]
            [System.Object]$Classification,
        [Parameter(
            Mandatory = $False,
            Position = 6,
            ParameterSetName = '',
            ValueFromPipeline = $False)]
            [Switch]$Disable                                                                                                                                 
            )
Process {
    If ($pscmdlet.parametersetname -eq "Name") {
        #Locate rule by name
        Write-Verbose "Locating Rule by name"
        $rule = $wsus.GetInstallApprovalRules() | ? {$_.Name -eq $name}
        If ($rule -eq $Null) {
            Write-Warning "No rules found by given name"
            Continue
            }
        }
    Else {
        #Rule is coming in as an object
        Write-Verbose "Rule is an object"
        $rule = $inputobject
        }        
    
    #Begin setting the properties of the Rule
    If ($psboundparameters.keys -contains "Category") {
        #Create the update collections object
        Write-Verbose "Creating collection of categories"
        $cat_coll = New-Object Microsoft.UpdateServices.Administration.UpdateCategoryCollection
        #Add categories to collection
        Write-Verbose "Adding categories to collection"
        $cat_coll.AddRange($Category)
        #Set the categories for rule
        If ($pscmdlet.ShouldProcess($Name)) {        
            Write-Verbose "Setting categories on rule"
            $rule.SetCategories($cat_coll)
            }
        }
    If ($psboundparameters.keys -contains "Group") {
        #Create the update collections object
        Write-Verbose "Creating collection of groups"
        $group_coll = New-Object Microsoft.UpdateServices.Administration.ComputerTargetGroupCollection
        #Add groups to collection
        Write-Verbose "Adding groups to collection"
        $group_coll.AddRange($group)
        If ($pscmdlet.ShouldProcess($Name)) {        
            #Set the groups for rule
            Write-Verbose "Setting groups on rule"
            $rule.SetComputerTargetGroups($group_coll)
            }
        }
    If ($psboundparameters.keys -contains "Classification") {
        #Create the update collections object
        Write-Verbose "Creating collection of classifications"
        $class_coll = New-Object Microsoft.UpdateServices.Administration.UpdateClassificationCollection
        #Add classifications to collection
        Write-Verbose "Adding classifications to collection"
        $class_coll.AddRange($classification)
        If ($pscmdlet.ShouldProcess($Name)) {        
            #Set the classification for rule
            Write-Verbose "Setting Classification on rule"
            $rule.SetUpdateClassifications($class_coll)
            }
        } 
    If ($Enable) {
        If ($pscmdlet.ShouldProcess($Name)) {        
            #Enable the rule for use
            Write-Verbose "Enabling Rule"
            $rule.Enabled = $True
            }
        }
    If ($Disable) {
        If ($pscmdlet.ShouldProcess($Name)) {        
            #Disable the rule for use
            Write-Verbose "Disabling Rule"
            $rule.Enabled = $False
            }
        }        
    }        
End{ 
    If ($pscmdlet.ShouldProcess($Name)) {        
        #Save the Rule
        Write-Verbose "Saving rule"
        $rule.Save()
        Write-Host -fore Green "Rule $($rule.Name) has been updated."
        }
    } 
}

Function Remove-WSUSInstallApprovalRule {
<#  
.SYNOPSIS  
    Removes Install Approval Rule from WSUS
.DESCRIPTION
    Removes Install Approval Rule from WSUS
.PARAMETER Name
    Name of the Install Approval Rule to remove
.PARAMETER InputObject
    Rule object to be removed       
.NOTES  
    Name: Remove-WSUSInstallApprovalRule
    Author: Boe Prox
    DateCreated: 24JAN2011 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Remove-WSUSInstallApprovalRule -name "Rule1"

Description
-----------      
Removes Rule1 from WSUS      
.EXAMPLE  
$rule = Get-WSUSInstallApprovalRule | ? {$_.Name -eq "Rule1"}
$rule | Remove-WSUSInstallApprovalRule

Description
-----------      
Removes Rule1 from WSUS   
#> 
[cmdletbinding(
	DefaultParameterSetName = '',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True    
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'name',
            ValueFromPipeline = $True)]
            [string]$Name,
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'object',
            ValueFromPipeline = $True)]
            [system.object]$InputObject                                                                                                                                
            )
Process {
    Switch ($pscmdlet.parametersetname) {
        Name {
            #Locate rule by name
            Write-Verbose "Locating Rule by name"
            $rule = $wsus.GetInstallApprovalRules() | ? {$_.Name -eq $name}
            If ($rule -eq $Null) {
                Write-Warning "No rules found by given name"
                Continue
                }
            Else {
                If ($pscmdlet.ShouldProcess("$($rule.name)")) {
                    #Removing rule
                    Write-Verbose "Removing rule"
                    $wsus.DeleteInstallApprovalRule($rule.id)
                    Write-Host "Rule $($rule.name) removed"
                    }                
                }                
            }
        Object {
            #Rule is an object
            Write-Verbose "Rule is an object"
            $rule = $inputobject
            If ($pscmdlet.ShouldProcess("$($rule.name)")) {
                #Removing rule
                Write-Verbose "Removing rule"
                $wsus.DeleteInstallApprovalRule($rule.id)
                Write-Host "Rule $($rule.name) removed"
                }
            }
        }
    }                    
}

Function Start-WSUSInstallApprovalRule {
<#  
.SYNOPSIS  
    Starts a given rule to process approvals
.DESCRIPTION
    Starts a given rule to process approvals
.PARAMETER Name
    Name of the Install Approval Rule to run
.PARAMETER InputObject
    Rule object to run       
.NOTES  
    Name: Start-WSUSInstallApprovalRule
    Author: Boe Prox
    DateCreated: 24JAN2011 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE  
Start-WSUSInstallApprovalRule -Name "Rule1"

Description
-----------      
Rule1 will begin approving updates based on its configuration    

.EXAMPLE
$rule = Get-WSUSInstallApprovalRules | ? {$_.Name -eq "Rule1"}  
$rule | Start-WSUSInstallApprovalRule

Description
-----------      
Rule1 will begin approving updates based on its configuration   
#> 
[cmdletbinding(
	DefaultParameterSetName = '',
	ConfirmImpact = 'low',
    SupportsShouldProcess = $True    
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'name',
            ValueFromPipeline = $True)]
            [string]$Name,
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ParameterSetName = 'object',
            ValueFromPipeline = $True)]
            [system.object]$InputObject                                                                                                                                
            )
Process {
    Switch ($pscmdlet.parametersetname) {
        Name {
            #Locate rule by name
            Write-Verbose "Locating Rule by name"
            $rule = $wsus.GetInstallApprovalRules() | ? {$_.Name -eq $name}
            If ($rule -eq $Null) {
                Write-Warning "No rules found by given name"
                Continue
                }
            Else {
                If ($pscmdlet.ShouldProcess("$($rule.name)")) {
                    #Running approval rule
                    Write-Verbose "Running approval rule"
                    $rule.ApplyRule()
                    }                
                }                
            }
        Object {
            #Rule is an object
            Write-Verbose "Rule is an object"
            If ($pscmdlet.ShouldProcess("$($rule.name)")) {
                #Running approval rule
                Write-Verbose "Running approval rule"
                $rule.ApplyRule()
                }
            }
        }
    }
}

Function Connect-WSUSDatabaseServer {
<#  
.SYNOPSIS  
    Makes a database connection to the server hosting the WSUS database.
.DESCRIPTION
    Makes a database connection to the server hosting the WSUS database.
.NOTES  
    Name: Connect-WSUSDatabaseServer
    Author: Boe Prox
    DateCreated: 06DEC2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
Connect-WSUSDatabaseServer

Description
-----------  
This command will display the configuration information for the WSUS connection to a database.       
#> 
[cmdletbinding()]  
    Param(
        [Parameter(
            Mandatory = $False,
            Position = 0,
            ValueFromPipeline = $False)]
            [switch]$Passthru
        ) 
#Create database connection
Write-Verbose "Creating the database connection to the database hosting WSUS"
$Global:wsusdb = ($wsus.GetDatabaseConfiguration()).CreateConnection()

#Display connection information if passthru is used
If ($passthru) {
    $Global:wsusdb
    }
}

Function Test-WSUSDatabaseServerConnection {
<#  
.SYNOPSIS  
    Tests the database connection from the console to the SQL database hosting the WSUS database.
.DESCRIPTION
    Tests the database connection from the console to the SQL database hosting the WSUS database.
.NOTES  
    Name: Test-WSUSDatabaseServerConnection
    Author: Boe Prox
    DateCreated: 06DEC2010 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
Test-WSUSDatabaseServerConnection

Description
-----------  
This command will test the database connection and return a boolean value based on the connection status.
#> 
[cmdletbinding()]  
Param () 
Try {
    #Test the connection to the database
    Write-Verbose "Testing the database connection to the WSUS database server."
    ($wsus.GetDatabaseConfiguration()).ConnectToDatabase()
    Write-Output $True
    }
Catch {
    Write-Output $False
    }    
}

Function Get-WSUSUpdateClassifications {
<#  
.SYNOPSIS  
    Lists all update classifications under WSUS.
.DESCRIPTION
    Lists all update classifications under WSUS.
.NOTES  
    Name: Get-WSUSUpdateClassifications
    Author: Boe Prox
    DateCreated: 24JAN2011 
           
.LINK  
    https://boeprox.wordpress.com
.EXAMPLE 
Get-WSUSUpdateClassifications

Description
-----------  
This command will display all update classifications available under WSUS.
#> 
[cmdletbinding()]  
    Param()
$wsus.GetUpdateClassifications()        
}
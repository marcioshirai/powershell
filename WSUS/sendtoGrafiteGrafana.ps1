# --------------------------
function Send-GraphiteMetric
# --------------------------
{
<#
    .Synopsis
        Sends Graphite Metrics to a Carbon server.
    .Description
        This function takes a metric, value and Unix timestamp and sends it to a Graphite server.
    .Parameter CarbonServer
        The Carbon server IP or address.
    .Parameter CarbonServerPort
        The Carbon server port. Default is 2003.
    .Parameter MetricPath
        The Graphite formatted metric path. (Must contain no spaces).
    .Parameter MetricValue
        The the value of the metric path you are sending.
    .Parameter UnixTime
        The the unix time stamp of the metric being sent the Graphite Server.
    .Parameter DateTime
        The DateTime object of the metric being sent the Graphite Server. This does a direct conversion to Unix time without accounting for Time Zones. If your PC time zone does not match your Graphite servers time zone the metric will appear on the incorrect time.
    .Example
        Send-GraphiteMetric -CarbonServer myserver.local -CarbonServerPort 2003 -MetricPath houston.servers.webserver01.cpu.processortime -MetricValue 54 -UnixTime 1391141202
        This sends the houston.servers.webserver01.cpu.processortime metric to the specified carbon server.
    .Example
        Send-GraphiteMetric -CarbonServer myserver.local -CarbonServerPort 2003 -MetricPath houston.servers.webserver01.cpu.processortime -MetricValue 54 -DateTime (Get-Date)
        This sends the houston.servers.webserver01.cpu.processortime metric to the specified carbon server.
    .Notes
        NAME:      Send-GraphiteMetric
        AUTHOR:    Matthew Hodgkins
        WEBSITE:   http://www.hodgkins.net.au
#>
    param
    (
        [CmdletBinding(DefaultParametersetName = 'Date Object')]
        [parameter(Mandatory = $true)]
        [string]$CarbonServer,

        [parameter(Mandatory = $false)]
        [ValidateRange(1, 65535)]
        [int]$CarbonServerPort = 2003,

        [parameter(Mandatory = $true)]
        [string]$MetricPath,

        [parameter(Mandatory = $true)]
        [string]$MetricValue,

        [Parameter(Mandatory = $true,
                   ParameterSetName = 'Epoch / Unix Time')]
        [ValidateRange(1, 99999999999999)]
        [string]$UnixTime,

        [Parameter(Mandatory = $true,
                   ParameterSetName = 'Date Object')]
        [datetime]$DateTime,

        # Will Display what will be sent to Graphite but not actually send it
        [Parameter(Mandatory = $false)]
        [switch]$TestMode,

        # Sends the metrics over UDP instead of TCP
        [Parameter(Mandatory = $false)]
        [switch]$UDP
    )

    # If Received A DateTime Object - Convert To UnixTime
    if ($DateTime)
    {
        # Convert to a Unix time without any rounding
        #$UnixTime = [uint64]$DateTime.ToUniversalTime()
        $unixTime = [long] (Get-Date -Date (($DateTime).ToUniversalTime()) -UFormat %s)
    }

    # Create Send-To-Graphite Metric
    $metric = $MetricPath + " " + $MetricValue + " " + $UnixTime

    Write-Verbose "Metric Received: $metric"

    $sendMetricsParams = @{
        "CarbonServer" = $CarbonServer
        "CarbonServerPort" = $CarbonServerPort
        "Metrics" = $metric
        "IsUdp" = $UDP
        "TestMode" = $TestMode
    }

    SendMetrics @sendMetricsParams
}


# ------------------
function SendMetrics
# ------------------
{
    param (
        [string]$CarbonServer,
        [int]$CarbonServerPort,
        [string[]]$Metrics,
        [switch]$IsUdp = $false,
        [switch]$TestMode = $false
    )

    if (!($TestMode))
    {
        try
        {
            if ($isUdp)
            {
                PSUsing ($udpobject = new-Object system.Net.Sockets.Udpclient($CarbonServer, $CarbonServerPort)) -ScriptBlock {
                    $enc = new-object system.text.asciiencoding
                    foreach ($metricString in $Metrics)
                    {
                        $Message += "$($metricString)`n"
                    }
                    $byte = $enc.GetBytes($Message)

                    Write-Verbose "Byte Length: $($byte.Length)"
                    $Sent = $udpobject.Send($byte,$byte.Length)
                }

                Write-Verbose "Sent via UDP to $($CarbonServer) on port $($CarbonServerPort)."
            }
            else
            {
                PSUsing ($socket = New-Object System.Net.Sockets.TCPClient) -ScriptBlock {
                    $socket.connect($CarbonServer, $CarbonServerPort)
                    PSUsing ($stream = $socket.GetStream()) {
                        PSUSing($writer = new-object System.IO.StreamWriter($stream)) {
                            foreach ($metricString in $Metrics)
                            {
                                $writer.WriteLine($metricString)
                            }
                            $writer.Flush()
                            Write-Verbose "Sent via TCP to $($CarbonServer) on port $($CarbonServerPort)."
                        }
                    }
                }
            }
        }
        catch
        {
            $exceptionText = "XXX"     # GetPrettyProblem $_
            Write-Error "Error sending metrics to the Graphite Server. Please check your configuration file. `n$exceptionText"
        }
    }
}



# http://support-hq.blogspot.com/2011/07/using-clause-for-powershell.html
# --------------
function PSUsing
# --------------
{
    param (
        [System.IDisposable] $inputObject = $(throw "The parameter -inputObject is required."),
        [ScriptBlock] $scriptBlock = $(throw "The parameter -scriptBlock is required.")
    )

    Try
    {
        &$scriptBlock
    }
    Finally
    {
        if ($inputObject -ne $null)
        {
            if ($inputObject.psbase -eq $null)
            {
                $inputObject.Dispose()
            }
            else
            {
                $inputObject.psbase.Dispose()
            }
        }
    }
}




Send-GraphiteMetric `
-CarbonServer fb649c0f.carbon.hostedgraphite.com `
-CarbonServerPort 2003 `
-MetricPath 461cc027-f4d8-453b-baac-c99a73fb0032.gru.linux `
-MetricValue 130 `
-DateTime (Get-Date)


Send-GraphiteMetric `
-CarbonServer fb649c0f.carbon.hostedgraphite.com `
-CarbonServerPort 2003 `
-MetricPath 461cc027-f4d8-453b-baac-c99a73fb0032.gru.windows `
-MetricValue 210 `
-DateTime (Get-Date)



$unixTime = [long] (Get-Date -Date ((Get-Date).ToUniversalTime()) -UFormat %s)

Invoke-WebRequest -Uri "fb649c0f.carbon.hostedgraphite.com:2003" -Method Post -Body "461cc027-f4d8-453b-baac-c99a73fb0032.gru.windows 10 $($unixTime )"




[DateTimeOffset]::Now.ToUnixTimeSeconds()
$DateTime = Get-Date #or any other command to get DateTime object
([DateTimeOffset]$DateTime).ToUnixTimeSeconds()



<#

I just wanted to present yet another, and hopefully simpler, way to address this. Here is a one liner I used to obtain the current Unix(epoch) time in UTC:

$unixTime = [long] (Get-Date -Date ((Get-Date).ToUniversalTime()) -UFormat %s)
Breaking this down from the inside out:

(Get-Date).ToUniversalTime()

This gets the current date/time in UTC time zone. If you want the local time, just call Get-Date. This is then used as input to...

[long] (Get-Date -Date (UTC date/time from above) -UFormat %s)

Convert the UTC date/time (from the first step) to Unix format. The -UFormat %s tells Get-Date to return the result as Unix epoch time (seconds elapsed since January 01, 1970 00:00:00). Note that this returns a double data type (basically a decimal). By casting it to a long data type, it is automatically converted (rounded) to a 64-bit integer (no decimal). If you want the extra precision of the decimal, don't cast it to a long type.
#>





<#
# Welcome to Hosted Graphite! The first step is sending a metric
# 
# fb649c0f.carbon.hostedgraphite.com
# 2003
#

var endPoint = new IPEndPoint(Dns.GetHostAddresses("fb649c0f.carbon.hostedgraphite.com")[0],2003);
var bytes = Encoding.ASCII.GetBytes("None.test.testing 1.2\n");
var sock = new Socket(AddressFamily.InterNetwork,SocketType.Dgram, ProtocolType.Udp) { Blocking = false };
sock.SendTo(bytes, endPoint);
#>







# grafana key
# eyJrIjoiN2Q1N2MyNzM4NzkwNDFkMzczZDg1NmViNmM3OTMwMzBjYzYzMmNiNyIsIm4iOiJzaGlyYWluZXQiLCJpZCI6NjIyMjh9






# --------------------------------------------------------------------------------------------------------------
# http://josh.behrends.us/2012/07/windows-powershell-graphite-awesome/
# --------------------------------------------------------------------------------------------------------------

# CODIGO OK

#Set the Graphite carbon server location and port number
$carbonServer = "fb649c0f.carbon.hostedgraphite.com"
$carbonServerPort = 2003
#Get Unix epoch Time
#$epochTime=[int](Get-Date -UFormat "%s")    # TA ENVIANDO COM -3H
$epochTime=[long](Get-Date -Date ((Get-Date).ToUniversalTime()) -UFormat %s)


#Putting some value here that I want to send
$value = 320
 
#Build our metric string in the format required by Graphite's carbon-cache service.
$metric1 = ("461cc027-f4d8-453b-baac-c99a73fb0032.gru.linux " + $value + " " + $epochTime)
$metric2 = ("461cc027-f4d8-453b-baac-c99a73fb0032.gru.windows " + $value + " " + $epochTime)

$metric1 = ("461cc027-f4d8-453b-baac-c99a73fb0032.windows.totalspace 100 " + $epochTime)
$metric2 = ("461cc027-f4d8-453b-baac-c99a73fb0032.windows.usedspace 82 " + $epochTime)
$metric3 = ("461cc027-f4d8-453b-baac-c99a73fb0032.windows.freespace 18 " + $epochTime)
$metric4 = ("461cc027-f4d8-453b-baac-c99a73fb0032.windows.percentfree 6 " + $epochTime)


#Stream results to the Carbon server
$socket = New-Object System.Net.Sockets.TCPClient 
$socket.connect($carbonServer, $carbonServerPort) 
$stream = $socket.GetStream() 
$writer = new-object System.IO.StreamWriter($stream)
#Write out metric to the stream.
$writer.WriteLine($metric1)
$writer.WriteLine($metric2)
$writer.WriteLine($metric3)
$writer.WriteLine($metric4)

$writer.Flush() #Flush and write our metrics.
$writer.Close() 
$stream.Close()

# --------------------------------------------------------------------------------------------------------------

curl https://YOUR-API-KEY@www.hostedgraphite.com/api/v1/sink --data-binary "conc_users 59"

Invoke-WebRequest -Uri "https://461cc027-f4d8-453b-baac-c99a73fb0032@www.hostedgraphite.com/api/v1/sink" -Method POST -Body "gru.linux 50" -UseBasicParsing
Invoke-WebRequest -Uri "https://461cc027-f4d8-453b-baac-c99a73fb0032@www.hostedgraphite.com/api/v1/sink" -Method Post -Body "461cc027-f4d8-453b-baac-c99a73fb0032.gru.windows 50 $($epochTime )"



# RETORNANDO 401 UNAUTHORIZED
# curl -Method GET "https://461cc027-f4d8-453b-baac-c99a73fb0032@api.hostedgraphite.com/api/v1/metric/search?pattern=gru.linux.*&not_updated_in=5h"
# Invoke-WebRequest -Method GET -Uri "https://461cc027-f4d8-453b-baac-c99a73fb0032@api.hostedgraphite.com/api/v1/metric/search?pattern=gru.linux.*" 
# /metrics/find?query=collectd.*
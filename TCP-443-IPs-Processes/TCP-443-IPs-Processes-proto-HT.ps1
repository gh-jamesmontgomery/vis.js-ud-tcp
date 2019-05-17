Clear-Host
Write-Host "===begin==="
#$processes = Get-Process
$TCPConnections = Get-NetTCPConnection | where {$_.RemoteAddress -notmatch "127.0.0.1|0.0.0.0|::" }
$htTCP = @{}
$htIPs = @{}

foreach($connection in $TCPConnections)
{
    #process look up for the connection owning process
    $thisProcess = Get-Process -id $connection.owningprocess
    $strProcessName = $thisProcess.name.ToString()

    if($strProcessName -ne "idle"){
        $thisRemoteIP = $connection.RemoteAddress.ToString()
        if($htIPs.ContainsKey($thisRemoteIP))
        {
            $htIPs[$thisRemoteIP] = $htIPs[$thisRemoteIP]+1
        }
        else {
            $htIPs.Add($thisRemoteIP,1)
        }
        $thisProcessID = $thisProcess.id.ToString()
        
        if($htTCP.ContainsKey(($strProcessName)))
            {
                write-host "Process Name $strProcessName exists" -ForegroundColor Yellow
                #retrieve process IDs HT
                $htThisProcessConnections = @{}
                $htThisProcessConnections = $htTCP[$strProcessName]
                
                #process name exists, check if we have *this* process ID
                if($htThisProcessConnections.ContainsKey($thisProcessID)){
                    write-host "Process ID $thisProcessID exists" -ForegroundColor Yellow
                    
                    
                    #process with multiple connections
                    $htThisProcessConnection = @{
                        remoteIP = $connection.RemoteAddress.ToString()
                        remotePort = $connection.remoteport.ToString()
                        localPort = $connection.localport.ToString()
                    }
                    $htTCP[$strProcessName][$thisProcessID] += @($htThisProcessConnection)
                    write-host "adding to $thisProcessID"
                }
                else {
                    #new processID for an existing process
                    write-host "New process ID $thisProcessID for $strProcessName" -BackgroundColor Green
                    
                    $htThisProcessConnection = @{
                        remoteIP = $connection.RemoteAddress.ToString()
                        remotePort = $connection.remoteport.ToString()
                        localPort = $connection.localport.ToString()
                    }

                    $htTCP[$strProcessName].add($thisProcessID, @($htThisProcessConnection))
                }

            }
            else {
                #New process name
                write-host "New process name $strProcessName with process ID $thisProcessID" -ForegroundColor Green

                #ht {processID = array of (htConnections)}
                $HTprocessID = @{$thisProcessID= @(
                    @{
                    remoteIP = $connection.RemoteAddress.ToString()
                    remotePort = $connection.remoteport.ToString()
                    localPort = $connection.localport.ToString()
                    }
                )}
                $htTCP.add($strProcessName, $HTprocessID)
            }
    }
    else
    {
        write-host "IDLE" -ForegroundColor Red
    }
}
$htTCP.Count
$HTOutput = @{Processes=$htTCP;RemoteAddresses=$htIPs}
$HTOutput.Processes
$jBody = ConvertTo-Json -InputObject $HTOutput -Depth 5
$jBody |clip 
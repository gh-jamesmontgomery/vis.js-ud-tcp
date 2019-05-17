$Endpoint = New-UDEndpoint -Url "/tcp-processes" -Method "GET" -Endpoint {
    
    #Get list of TCP connections, filter out local host IPs and listeners
    $TCPConnections = Get-NetTCPConnection | Where-Object {$_.RemoteAddress -notmatch "127.0.0.1|0.0.0.0|^::$|^::1$" }
    #create the hast table for representing the name->PID->connection relationship
    $htTCP = @{} 
    #create the hast table for representing the IP addressed found and count of connections
    $htIPs = @{} 

    foreach($connection in $TCPConnections)
    {
        #process name look up for the connection owning process ID
        $thisProcess = Get-Process -id $connection.owningprocess
        $strProcessName = $thisProcess.name.ToString()
    
        if($strProcessName -ne "idle"){

            #Setup strings for the connection properties for use later
            $thisRemoteIP = $connection.RemoteAddress.ToString()
            $thisRemotePort = $connection.remoteport.ToString()
            $thisLocalPort = $connection.localport.ToString()

            #Review each connection remote IP against the IP hash table
            if($htIPs.ContainsKey($thisRemoteIP))
            {
                #IP exists, increment count by 1.
                $htIPs[$thisRemoteIP] = $htIPs[$thisRemoteIP]+1
            }
            else {
                #First sight of this IP, set count to 1
                $htIPs.Add($thisRemoteIP,1)
            }

            #Set PID string for use later
            $thisProcessID = $thisProcess.id.ToString()
            
            #Check if we have observed the Process Name already
            if($htTCP.ContainsKey(($strProcessName)))
                {
                    Write-Debug "Process Name $strProcessName exists"

                    #retrieve process IDs TCP connections HT
                    $htThisProcessConnections = @{}
                    $htThisProcessConnections = $htTCP[$strProcessName]
                    
                    #process name exists, check if we have *this* process ID
                    if($htThisProcessConnections.ContainsKey($thisProcessID)){
                        Write-Debug "Process ID $thisProcessID exists"
                        
                        #process with multiple connections, build new connection HT
                        $htThisProcessConnection = @{
                            remoteIP = $thisRemoteIP
                            remotePort = $thisRemotePort
                            localPort = $thisLocalPort
                        }
                        #Retrieve the existing array of connection HTs, add this connection HT to it.
                        $htTCP[$strProcessName][$thisProcessID] += @($htThisProcessConnection)
                        Write-Debug "adding to $thisProcessID"
                    }
                    else {
                        #new processID for an existing process
                        Write-Debug "New process ID $thisProcessID for $strProcessName"
                       
                        #build new connection HT
                        $htThisProcessConnection = @{
                            remoteIP = $thisRemoteIP
                            remotePort = $thisRemotePort
                            localPort = $thisLocalPort
                        }

                        #Retrieve existing Process name HT, add this PID HT with the Connection HT in an array
                        $htTCP[$strProcessName].add($thisProcessID, @($htThisProcessConnection))
                    }
                    
                }
                else {
                    #New process name
                    Write-Debug "New process name $strProcessName with process ID $thisProcessID"
    
                    #Build the PID HT, {processID = array of (htConnections)}
                    $HTprocessID = @{$thisProcessID= @(
                        @{
                            remoteIP = $thisRemoteIP
                            remotePort = $thisRemotePort
                            localPort = $thisLocalPort
                        }
                    )}
                    #Add the PID HT to the Connection HT
                    $htTCP.add($strProcessName, $HTprocessID)
                }
        }
        else
        {
            Write-Debug "Idle process"
        }
    }
    #Further wrap our built HT into a Processes and Remote Addresses HT
    $HTOutput = @{Processes=$htTCP;RemoteAddresses=$htIPs}
    #Convert to JSON
    $jBody = ConvertTo-Json -InputObject $HTOutput -Depth 5
    #Return the JSON response
    $jBody
}

Start-UDRestApi -Port 10001 -Endpoint @(
   $Endpoint
)


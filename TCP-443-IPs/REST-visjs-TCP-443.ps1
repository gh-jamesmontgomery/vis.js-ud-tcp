$Endpoint = New-UDEndpoint -Url "/tcp-443" -Method "GET" -Endpoint {
    Get-NetTCPConnection | Where-Object{$_.RemotePort -eq 443} | Select-Object RemoteAddress | ConvertTo-Json
}

Start-UDRestApi -Port 10000 -Endpoint @(
   $Endpoint
)

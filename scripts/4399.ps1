[CmdletBinding()]param($query)
$TLDs = DATA {
  ConvertFrom-StringData -stringdata @'
    .br.com=whois.centralnic.net
    .cn.com=whois.centralnic.net
    .eu.org=whois.eu.org
    .com=whois.crsnic.net
    .net=whois.crsnic.net
    .org=whois.publicinterestregistry.net
    .edu=whois.educause.net
    .gov=whois.nic.gov
'@
}

$EAP, $ErrorActionPreference = $ErrorActionPreference, "Stop"

$query = $query.Trim()

if($query -match "(?:\d{1,3}\.){3}\d{1,3}") {
    Write-Verbose "IP Lookup!"
    $query = "n $query"
    $server = "whois.arin.net"
} else {
    $server = $TLDs.GetEnumerator() |
        Where { $query -like  ("*"+$_.name) } |
        Select -Expand Value -First 1
}
if(!$server) {
    $server = "whois.arin.net"
}

Write-Verbose "Connecting to $server"
$client = New-Object System.Net.Sockets.TcpClient $server, 43

try {
    $stream = $client.GetStream()

    Write-Verbose "Sending Query: $query"
    $data = [System.Text.Encoding]::Ascii.GetBytes( $query + "`r`n" )
    $stream.Write($data, 0, $data.Length)

    Write-Verbose "Reading Response:"
    $reader = New-Object System.IO.StreamReader $stream, [System.Text.Encoding]::ASCII

    $reader.ReadToEnd()
} finally {
    if($stream) {
        $stream.Close()
        $stream.Dispose()
    }
}
$ErrorActionPreference = $EAP

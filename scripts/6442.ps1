function Test-Port {
	<#
	.SYNOPSIS
	Test ports on computer
	.DESCRIPTION
	Test TCP or UDP ports on computer
	.PARAMETER ComputerName
	The computer name or ip address to query, can be array
	.PARAMETER PortNumber
	Integer value of port to test, default 135 for RPC, can be array
	.PARAMETER Timeout
	Time in milliseconds to timeout connection
	.PARAMETER TCP
	Test TCP Connection
	.PARAMETER UDP
	Test UDP Connection
	.EXAMPLE
	Test-Port localhost
	Checks if TCP port 135 open on localhost
	.EXAMPLE
	"Server" | Test-Port
	Checks if TCP port 135 open on Server
	.EXAMPLE
	Test-Port -ComputerName "Server1","Server2" -Port 80,21 -TCP
	Checks if TCP ports 80 and 21 are open on Server1 and Server2
	.EXAMPLE
	Test-Port -ComputerName "Server" -PortNumber 161 -UDP
	Check if UDP port 161 is open on Server
	.LINK
	Based on Test-Port by Chad Miller
	http://poshcode.org/2392
	#>
	
	[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low',DefaultParameterSetName="TCP")]
	param
	(
		[Parameter(Mandatory = $True,
		ValueFromPipeline = $True,
		ValueFromPipelineByPropertyName = $True,
		Position = 0)]
		[string[]]$ComputerName,
		
		[int[]]$PortNumber = 135,
		
		[Parameter(ParameterSetName="TCP")]
		[switch]$TCP,
		
		[Parameter(ParameterSetName="UDP")]
		[switch]$UDP
	)
	
	begin {
		
	}

	process {

		write-verbose "Beginning process loop"

		foreach ($computer in $computername) {
			foreach ($port in $PortNumber) {
				if ($pscmdlet.ShouldProcess($computer,"Testing port $port")) {
					#Create return object
					$returnobj = New-Object psobject | select ComputerName,Port,Connected
					$returnobj.ComputerName = $computer
					$returnobj.Port = $port
					if (($psCmdlet.ParameterSetName) -eq "TCP") {
						Write-Verbose "Processing $computer TCP"
						$sock = new-object System.Net.Sockets.Socket -ArgumentList $([System.Net.Sockets.AddressFamily]::InterNetwork),$([System.Net.Sockets.SocketType]::Stream),$([System.Net.Sockets.ProtocolType]::Tcp)

						try {
							Write-Verbose "Open socket to $port"
							$sock.Connect($Computer,$port)
							Write-Verbose "Returning Connection Status"
							$returnobj.connected = $sock.Connected
							Write-Verbose "Closing socket to $port"
							$sock.Close()
						}
						catch {
							
							Write-Verbose $error[0]
							$returnobj.connected = $false
						}
					}
					
					if (($psCmdlet.ParameterSetName) -eq "UDP") {
						$sock = new-object System.Net.Sockets.Socket -ArgumentList $([System.Net.Sockets.AddressFamily]::InterNetwork),$([System.Net.Sockets.SocketType]::Dgram),$([System.Net.Sockets.ProtocolType]::Udp)

						try {
							Write-Verbose "Open socket to $port"
							$sock.Connect($Computer,$port)
							Write-Verbose "Returning Connection Status"
							$returnobj.connected = $sock.Connected
							Write-Verbose "Closing socket to $port"
							$sock.Close()
						}
						catch {
							
							Write-Verbose $error[0]
							$returnobj.connected = $false
						}
					}
				$returnobj
				}
			}
		}
	}
}

function Set-CustomIP {

        <#
    	.SYNOPSIS
    	Set network settings.
    	.DESCRIPTION
    	Set network settings.
    	.EXAMPLE
    	Set-CustomIP 192.168.1.123
    	.PARAMETER IPAddress
    	Preferred IP Address. DHCP is available to set IP with DHCP.
    	.PARAMETER DefaultGateway
    	Preferred Default Gateway. If no value is provided, a value is calculated.
	.PARAMETER PrimaryDNSServer
	Primary DNS server. Defaults to 8.8.8.8
	.PARAMETER SecondaryDNSServer
	Secondary DNS server. Defaults to 8.8.4.4
	.PARAMETER AddressFamily
	Currently only available in IPv4
	.PARAMETER InterfaceIndex
	Specify which interface using InterfaceIndex. Defaults to physical interface.
    	#>
	
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, Position=1)]
        [string] $IPAddress,

        [Parameter(Mandatory=$False, Position=2)]
        [string] $DefaultGateway,

        [Parameter(Mandatory=$False, Position=3)]
        [string] $PrimaryDNSServer = "8.8.8.8",

        [Parameter(Mandatory=$False, Position=4)]
        [string] $SecondaryDNSServer = "8.8.4.4",
		
	[Parameter(Mandatory=$False, Position=5)]
        [string] $AddressFamily = "IPv4",
		
	[Parameter(Mandatory=$False, Position=6)]
        [string] $PrefixLength = "24",
		
	[Parameter(Mandatory=$False, Position=7)]
        [string] $InterfaceIndex = (Get-NetAdapter -physical).ifIndex
    )
	
	### Removes current IP settings to avoid clutter.
	Get-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily $AddressFamily | % {Remove-NetIPAddress $_.IPAddress -Confirm:$false} 
	Remove-NetRoute -InterfaceIndex $InterfaceIndex -Confirm:$false
	
	if ($IPAddress -eq "DHCP") {
		Get-NetAdapter -InterfaceIndex $InterfaceIndex | Set-NetIPInterface -Dhcp enabled
		break
		}
	
	### If DefaultGateway not specified, calculate standard value for Default Gateway.
	if (!$DefaultGateway) {
		$IPArray = $IPAddress.split(".")
		$DefaultGateway = $IPArray[0] + "." + $IPArray[1] + "." + $IPArray[2] + ".1"
		}
	
    	New-NetIPAddress `
		-InterfaceIndex $InterfaceIndex `
		-IPAddress $IPAddress `
		-DefaultGateway $DefaultGateway `
		-AddressFamily $AddressFamily `
		-PrefixLength $PrefixLength `
        	-Confirm:$false
		
    	Set-DnsClientServerAddress `
		-InterfaceIndex $InterfaceIndex `
		-ServerAddresses $PrimaryDNSServer, $SecondaryDNSServer

    }

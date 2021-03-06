<# 
	.SYNOPSIS
		Gets the public IP address that represents your computer on the internet.
	
	.DESCRIPTION
		The Get-MyPublicIPAddress script uses DNS-O-Matic, an OpenDNS resource, to retreive the public IP address that represents your computer on the internet.
	
	.EXAMPLE
		Get-MyPublicIPAddress
		1.1.1.1
		
		Description
		-----------
		This command returns the public IP address that represents your computer on the internet.
	
	.INPUTS
		None
	
	.OUTPUTS
		System.String
	
	.NOTES
		Name: Get-MyPublicIPAddress
		Author: Rich Kusak
		Created: 2010-08-30
		LastEdit: 2010-08-30 11:05
		Version: 1.0.0.0
		
	.LINK
		http://myip.dnsomatic.com

	.LINK
		http://www.opendns.com	
#>

	[CmdletBinding()]
	param ()
	
	# Create a web client object
	$webClient = New-Object System.Net.WebClient
	
	# Returns the public IP address
	$webClient.DownloadString('http://myip.dnsomatic.com/')


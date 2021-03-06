function Get-NistNtpServer {
<#
	.SYNOPSIS
		Gets the list NIST NTP servers.

	.DESCRIPTION
		The Get-NistNtpServer function retrieves the list of NIST NTP server names, IP addresses, and locations.

	.EXAMPLE
		Get-NistNtpServer
		Returns the list of NIST NTP servers.

	.INPUTS
		None

	.OUTPUTS
		PSObject

	.NOTES
		Name: Get-NistNtpServer
		Author: Rich Kusak
		Created: 2011-12-31
		LastEdit: 2011-12-31 20:46
		Version: 1.0.0.0

	.LINK
		http://tf.nist.gov/tf-cgi/servers.cgi

#>

	[CmdletBinding()]
	param ()
	
	begin {
	
		$uri = 'http://tf.nist.gov/tf-cgi/servers.cgi'
		$webClient = New-Object System.Net.WebClient
		$filter = "$null", 'time.nist.gov', 'global address for all servers', 'Multiple locations'
		$i = 0

	} # begin
	
	end {
	
		try {
			$webpage = $webClient.DownloadString($uri)
		} catch {
			throw $_
		}
		
		$list = ([regex]::Matches($webpage, 'td align = "center">.*') | Select -ExpandProperty Value) -replace '.*>' | Where {
			 $filter -notcontains $_
		}
		
		$names = $list | Select-String '.*\.\D{2,3}$'
		$ips = $list | Select-String '^(\d{1,3}\.){3}\d{1,3}$'
		$locations = $list -like '*,*'
		
		foreach ($name in $names) {
			New-Object PSObject -Property @{
				'Name' = $name
				'IPAddress' = $ips[$i]
				'Location' = $locations[$i]
			}

			$i++
			
		} # foreach
	} # end
} # function Get-NistNtpServer


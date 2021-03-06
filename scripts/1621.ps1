<#
	.SYNOPSIS
		Gets the bogon list.
	
	.DESCRIPTION
		The Get-BogonList script retrieves the bogon prefix list maintained by Team Cymru.
		
		A bogon prefix is a route that should never appear in the Internet routing table.
		A packet routed over the public Internet (not including over VPNs or other tunnels) should never have a source address in a bogon range.
		These are commonly found as the source addresses of DDoS attacks. Bogons are defined as Martians (private and reserved addresses defined by RFC 1918 and RFC 3330) and 
		netblocks that have not been allocated to a regional internet registry (RIR) by the Internet Assigned Numbers Authority.
		
	.PARAMETER Aggregated
		By default the unaggregated bogon list is retrieved. Use this switch parameter to retrieve the aggregated list.
	
	.OUTPUTS
		PSObject
	
	.EXAMPLE
		Get-BogonList
		Retrieves the unaggregated bogon list from Team Cymru.
		
	.EXAMPLE
		Get-BogonList -Aggregated
		Retrieves the aggregated bogon list from Team Cymru.
	
	.NOTES
		Name: Get-BogonList
		Author: Rich Kusak (rkusak@cbcag.edu)
		Created: 2010-01-31
		Version: 1.0.0
		
		#Requires -Version 2.0
		
	.LINK
		http://www.team-cymru.org/Services/Bogons/

#>
	
	param (
		[switch]$Aggregated
	)
	
	$webClient = New-Object System.Net.WebClient
	
	$version = $webClient.DownloadString("http://www.cymru.com/Documents/bogon-list.html") -split "`n" |
		Where-Object {$_ -cmatch "TITLE"} | ForEach-Object {$_.Remove(0,7).Replace('</TITLE>',"").Trim()}
	
	if ($Aggregated) {
		foreach ($bogon in $webClient.DownloadString("http://www.cymru.com/Documents/bogon-bn-agg.txt") -split "`n" | Where-Object {$_ -notlike $null}) {
			New-Object PSObject -Property @{$version = $bogon}
		}
	} else {
		foreach ($bogon in $webClient.DownloadString("http://www.cymru.com/Documents/bogon-bn-nonagg.txt") -split "`n" | Where-Object {$_ -notlike $null}) {
			New-Object PSObject -Property @{$version = $bogon}
		}
	}


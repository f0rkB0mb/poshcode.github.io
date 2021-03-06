<#
	.SYNOPSIS
		Pulls down the leaderboards for the 2011 Scripting Games

	.DESCRIPTION
		Quick and dirty script to pull down the leaderboards for the 2011 scripting games.  
		Can choose either beginner or advanced via a command line switch. To see the output
		in a table, you must pipe to "format-table -autosize" or "out-gridview"
		
	.PARAMETER  Level
		The leaderboard to parse

	.EXAMPLE
		Get-LeaderBoard -Level Beginner
		
		Retrieves the beginner leaderboard.

	.EXAMPLE
		Get-LeaderBoard -Level Advanced
		
		Retrieves the advanced leaderboard
	
	.EXAMPLE
		Get-LeaderBoard Advanced | Format-Table -Autosize
		
		Retrieves the advanced leaderboard and returns values in a table
	
	.EXAMPLE
		Get-LeaderBoard Advanced | Format-Table -Autosize
		
		Retrieves the advanced leaderboard and displays a table.
	
	.EXAMPLE
		Get-LeaderBoard Advanced | where { $_.UserName -eq "My Name" }
		
		Retrieves status for user "My Name"	
	.NOTES
		NAME:      Get-LeaderBoard
 		VERSION:   1.01
 		AUTHOR:    Alex McFarland
 		LASTEDIT:  04/23/2011
	 	-Added rankings to output.  This unfortunately requires use of ft - auto to get 
		 decent looking output.
		-Incorporated regex changes to to issues points out by Scott Alvarino. Was
		 missing foreign language characters and periods.
#>
function Get-LeaderBoard 
{
	param(
		[Parameter(
			Position = 0,
			Mandatory = $true,
			HelpMessage = "Leaderboard to parse.  Advanced, or Beginner")]
		[ValidateSet("Advanced","Beginner")]
		[String]$Level="Advanced"
	)
	
	# create a webclient
	$WebClient = New-Object System.Net.WebClient
	# download the page
	$LeaderPage = $WebClient.DownloadString("http://2011sg.poshcode.org/Reports/TopUsers?filter=$Level") 
	
	# create a horrific looking regular expression
	$RegEx = '<a href="/Scripts/By/\d{1,3}">(?<UserName>[\w\s\S]*)</a>\s*</td>\s*<td>\s*(?<TotalPoints>\d{1,2}\.\d{1,2})\s*</td>\s*<td>\s*(?<ScriptsRated>\d*)'
	
	# initialize counter for ratings
	$i = 1
	# split the page into seperate objects so we can parse each invidual
	$LeaderPage -split "<tr>" | ForEach { 
		# match the regex
		$_ -match $RegEx | Out-Null
		# create a new PSObject, supply a hashtable with the properties
		if (-not $Matches.UserName -eq "") 
		{
			New-Object PSObject -Property @{
				"Ranking" = $i++
				"UserName" = $Matches.UserName
				"ScriptsRated" = $Matches.ScriptsRated
				"TotalPoints" = $Matches.TotalPoints
				"AverageRating" = if  ($Matches.ScriptsRated -gt 0) 
				{
					# get average round to two decimal places
					"{0:N2}" -f ($Matches.TotalPoints / $Matches.ScriptsRated)
				}
			}
		}
		# clear matches
		if ($Matches) { $Matches.Clear() }
		
		# get our objects in a specific order.
	} | select -Unique Ranking,UserName,ScriptsRated,AverageRating,TotalPoints
}



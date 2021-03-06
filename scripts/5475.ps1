

function Check-WindowsPreview
{
	[CmdletBinding()]
	[OutputType([PSObject])]
	PARAM(
		[Parameter(Position=0,HelpMessage="The duration between requests if using -WaitForItSwitch")]
		[ValidateRange(5,300)]
		[int]$SleepDuration = 5,

		[Parameter(HelpMessage="Run until it is released and then exit")]
		[switch]$WaitForIt
	)

	BEGIN
	{
		$webClient = new-object System.Net.WebClient
		$webClient.Headers.Add("user-agent", "PowerShell Script")
		$webClient.Headers.Add("Cache-Control", "no-cache");
		$webClient.CachePolicy = $(New-Object System.Net.Cache.RequestCachePolicy NoCacheNoStore)

		do
		{
			try
			{
 				$startTime = Get-Date
 				$output = $webClient.DownloadString("http://preview.windows.com")
 				$endTime = Get-Date

	 			if ($output -like "*so please check back soon*")
				{
					Write-Output $(New-Object -type PSObject -Property @{
     						Released = "Nope"
     						StartTime = $startTime
     						EndTime = $endTime
						Duration = ($endTime - $startTime).TotalSeconds
						HttpStatus = "Success"
					})
				}
				else
				{
					Write-Output $(New-Object -type PSObject -Property @{
     						Released = "Yepp"
     						StartTime = $startTime
     						EndTime = $endTime
						Duration = ($endTime - $startTime).TotalSeconds
						HttpStatus = "Success"
					})
					$WaitForIt = $false
				}
			}
			catch
			{
				Write-Output $(new-object -type PSObject -Property @{
     					Released = "Unknown"
     					StartTime = $startTime
     					EndTime = $endTime
					Duration = ($endTime - $startTime).TotalSeconds
					HttpStatus = "Error: $($_.Exception.Message)"
				})
			}

 			if ($WaitForIt) { Sleep($SleepDuration) }
		}
		while ($WaitForIt)
	}

}

## this filer passes through only objects that are pingable
## it takes any object as input, but the property containing the hostname
## to ping must be specified if the object is not a string
function Select-Alive {param(	[object]$InputObject,
				[string]$Property,
				[int32]$Requests = 3,
				[switch]$Verbose)

	PROCESS {
		if ($InputObject -eq $null) {$In = $_} else {$In = $InputObject}
		if ($In.GetType().Name -eq "String") {
			$HostName = $In
		} 
		elseif (($In | Get-Member | Where-Object {$In.Name -eq $Property}) -ne $null) {
			$HostName = $In.$Property
		} else {return $null}
		
		if ($Verbose) {Write-Host "Pinging $HostName..." -NoNewline}
		for ($i = 1; $i -le $Requests; $i++) {
			$Result = Get-WmiObject -Class Win32_PingStatus -ComputerName . -Filter "Address='$HostName'"
			Start-Sleep -Seconds 1
			if ($Result.StatusCode -ne 0) {
				if ($Verbose) {Write-Host "No response." -ForegroundColor "Red"}
				return $null
			}
		}
		if ($Verbose) {Write-Host "Success." -ForegroundColor "Green"}
		return $In
	}
}

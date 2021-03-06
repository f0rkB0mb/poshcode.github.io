# Get-ProcessCount uses 2 main variables, server and process name.
# Process name is typically the end exe, such as "svchost.exe"
# Will accept unnamed args (Get-ProcessCount servername processname)
# or named args (Get-ProcessCount -Computer servername -Process processname)
Function Get-ProcessCount([string]$process, [string]$computer = "localhost", [switch]$guess) {
	if($guess) {
		$clause = [string]::Format("like '%{0}%'",$process)
	}
	else {
		$clause = [string]::Format("='{0}'",$process)
	}
	#using string.Format can be very nice to do variable substitution
	$selectstring = [string]::Format("select * from Win32_Process where name {0}",
		$clause)
	$result = get-wmiobject -query $selectstring -ComputerName $computer
	# I really like the group-object cmdlet for reporting stuff 
	if($result) { $result | Group-Object Name }
	else { Write "Process $process could not be found" }
}

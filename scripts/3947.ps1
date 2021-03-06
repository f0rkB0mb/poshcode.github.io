param (
$logpath = "C:\WINDOWS\system32\LogFiles\SMTPSVC1"
 # can also be fed by "gci $logpath | select basename" but then all logfiles would be read
$logfiles = @("ex130213.log","ex130214.log")
$regex = "(?:[0-9]{1,3}\.){3}[0-9]{1,3}"
)
$smtphosts = @()
foreach ($logFile in $logfiles){
	# can also be iterated thru "gci $logpath" if all logfiles need parsing
	$logfilepath = Join-Path $logpath $logfile
	write-host "getting smtp connections from $logfile" -foregroundcolor green
	$smtphosts += select-string -Path $logfilepath -Pattern $regex -AllMatches | %{ $_.Matches } | % { $_.Value } | sort -Unique
	}
$smtphosts | sort -Unique
# can be followed by "| nslookup" for automated reverse lookup

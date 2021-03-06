# ========================================================================
# 
# NAME: Get-LogicalDiskInfo.ps1
# 
# AUTHOR: Alex Ocampo , Daptiv Solutions LLC
# DATE  : 7/19/2011
# 
# COMMENT: Using WMI, script check logical disk information of a single
# server or a group of servers. Script send email notification if any
# logical disk free space falls below minimum free disk space
# ($minFreeSpace).
#          
#
# Syntax:
#
# Check logicalDisks info on a single host in this case "server1"
# PS C:\Scripts> .\Get-LogicalDiskInfo.ps1 -computerNames "server1"
#
# Running script without passing a parameter checks logicalDisks of all
# computers or servers listed on C:\Scripts\Computers.txt. Script stop
# execution if no parameter is passed and Computers.txt is not present.
#
# Sample (Computers.txt), add computers/servers to check as needed...
# SERVER1
# SERVER2
# SERVER3
# 
# ========================================================================

param (
	[string[]] $computerNames
)

Set-Location -Path ([System.Environment]::GetEnvironmentVariable("SystemDrive") + "\Scripts")

# Test that parameters exists
if ($computerNames -eq $null) {
	if (Test-Path -LiteralPath ".\Computers.txt" -PathType "leaf") {
		$computerNames = Get-Content -Path	".\Computers.txt"
	}
	
	else {
		Write-Host "missing parameters..."
		exit
	}
}

# $minFreeSpace = $_.freespace/$_.size
# higher value translate to lower maximum disk space used and reports
# more drives meeting criteria.

[double] $minFreeSpace=.25

function notify {
	param (
		[string] $subject,
		[string] $message,
		[string] $to="DL Team IT <distributionGroup@mydomain.com>",
		[string] $from="IT Notification <itNotification@mydomain.com>",		
		[string] $smtpserver="mailServer.mydomain.com"
	)
	
	Send-MailMessage -From $from -To $to -Subject $subject -Body $message -SmtpServer $smtpserver
}
 
function existTest {
	param ([string] $node2Chk)
	$pathStr="\\$node2Chk\ADMIN$"
	return Test-Path -LiteralPath $pathStr
}

function chkDisk {
	param (
		[string] $node
	)
		# $messageBody string = "WARNING: Drive C: is 85% full..."
		[string] $messageBody="WARNING: Immediate action required...`r`n`r`n"
				
		Get-WmiObject Win32_LogicalDisk -ComputerName $node | `
			Where-Object {$_.DriveType -eq 3} | `
			ForEach-Object { If (($_.FreeSpace/$_.Size) -le $minFreeSpace) { `
				$result="Drive " + $_.DeviceID + " is " + (100 - [math]::Round(($_.FreeSpace/$_.Size)*100, 2)) + "% full..."
				# $result=$node + ": " + $_.DeviceID + " - Free disk space: " + [math]::Round($_.FreeSpace/1GB, 2) + "GB"
				$messageBody="$messageBody" + "`t$result`r`n"
			}
		}
		
		# do not call function if variable is equals to initial value
		if ($messageBody -ne "WARNING: Immediate action required...`n`n") {				
			notify -subject "RE: \\$node" -message "$messageBody"
		}
}

function main {
	param (
		[bool] $validNode
	)
		
	foreach ($computer in $computerNames) {
		# Test if computer exists
		$validNode = existTest $computer
		
		if ($validNode) {
			chkDisk $computer
		}		
	}
} 

# call main function
main

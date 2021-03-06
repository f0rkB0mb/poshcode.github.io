[CmdletBinding()]
Param(
   [Parameter(ValueFromRemainingArguments=$true)]
   $command=$(Read-Host "You must specify a command")
)

#requires -version 2.0
function global:Sudo {
## In order to use this, you have to 
## Create a "Scheduled Task" named "Elevated powershell.exe" to run
##    PowerShell -Command "exit"
## The scheduled task must be set to "Run with highest privileges" 
## NOTE: THIS IS A SECURITY RISK. 
##    You should at least set it to run only when you're logged on
##    I also do NOT set it to run "Hidden" so I always know.
######################################################################
##### You could create that with a script: http://poshcode.org/907
## New-ElevatedTask $((gcm PowerShell | ls).FullName) `
##                  '-Command "exit"' -TaskName "Elevated PowerShell"
######################################################################
[CmdletBinding()]
Param(
   [Parameter(ValueFromRemainingArguments=$true)]
   $command=$(Read-Host "You must specify a command")
)

$SchTasks = ls ([Environment]::GetFolderPath("System")) schtasks.exe
$SchTasks = $SchTasks.FullName
$TaskName = '"Elevated PowerShell"'

$AllProfile = Join-Path $(Split-Path $Profile) "Profile.ps1"
$OutputXml  = Join-Path $(Split-Path $Profile) "SudoOutput.psxml"
$OutputErr  = Join-Path $(Split-Path $Profile) "SudoOutput.err"
$command = $($command -join " ") + " 2> $OutputErr | 
Export-CliXml $OutputXml"

$donecheck = { 
Get-WinEvent -LogName Microsoft-Windows-TaskScheduler/Operational `
-FilterXPath "*[System[TimeCreated[timediff(@SystemTime) <= 2500]] 
               and EventData[@Name='TaskSuccessEvent' 
               and Data[@Name='TaskName']='\Elevated PowerShell']]" `
-ErrorAction "SilentlyContinue"
}


## Append our command to the end of the profile script ...
## But make sure we remove any sig block at the end first
$script = gc $AllProfile

Set-Content $AllProfile @"
$(($script -notmatch "^\s*#") -join "`n")
Remove-Item $OutputXml -ErrorAction "SilentlyContinue"
Write-Host "$Command" -Fore Cyan
$Command
"@

$result = &$SchTasks /Run /TN $TaskName
if($result -notmatch "^SUCCESS") {
   Write-Error $result
} else {
   while(!(&$donecheck)) { sleep 1 }
}

$ErrorActionPreference = "SilentlyContinue"
Import-CliXml $OutputXml

Write-Warning $(@(Get-Content $OutputErr) -join "`n")
Remove-Item $OutputXml
Remove-Item $OutputErr

Set-Content $AllProfile $script

}

Sudo $($command -join " ")

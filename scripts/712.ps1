# Author: Steven Murawski http://www.mindofroot.com

# This script creates two functions (and a helper function).  One starts logging all commands entered,
# and the second removes the logging.
# This script is similar to the Start-Transcript, but only logs the command line and not the output.


function New-ScriptBlock()
{
	param ([string]$scriptblock)
	$executioncontext.InvokeCommand.NewScriptBlock($scriptblock.trim())
}

function Start-Verify ()
{
	param ($logfile = 'c:\scripts\powershell\logs\verify.txt')
	$lastcmd = 'get-history | select -property CommandLine -Last 1 | Out-File -Append {0}' -f $logfile
	Get-Content -Path function:\prompt | ForEach-Object { $function:prompt =  New-ScriptBlock ($_.toString() +"`n$lastcmd") } | Out-Null
}

function Stop-Verify ()
{
	$lastcmd = 'get-history.*$' 
	Get-Content -Path function:\prompt | ForEach-Object { $function:prompt = New-ScriptBlock ($_.tostring() -replace "$lastcmd")} | Out-Null
}



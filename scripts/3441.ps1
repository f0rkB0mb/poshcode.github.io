#========================================================================
# Created on:   5/17/2012 2:03 PM
# Created by:   Clint Jones
# Organization: Virtually Genius!
# Filename:     Get-VMHostVersions
#========================================================================

#Import modules
Add-PSSnapin "Vmware.VimAutomation.Core"

#Path to the log files
$log = "C:\Scripts\VMware\Logs\hostversions.txt"

#Creates directory structure for log files
$pathverif = Test-Path -Path c:\scripts\vmware\logs
switch ($pathverif)
    {
        True    {}
        False   {New-Item "c:\scripts\vmware\logs" -ItemType directory}
        default {Write-Host "An error has occured when checking the file structure"}
    }

#Connect to VMware servers
$viserver = Read-Host "Enter VMware server:"
$creds = Get-Credential
Connect-ViServer -Server $viserver -Credential $creds

#Get the version number of the host
Get-VMHost | Select-Object Name, Version | Format-Table -AutoSize | Out-File -FilePath $log -Append


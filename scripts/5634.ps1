# This script lists Shadow Copies on specified servers created over past 7 days
# 
# Author: Andy McKnight
# Created: 08/12/2014
# Last Edit: 08/12/2014
#

$servers = "SERVER1", "SERVER2", "SERVER3" # etc, etc
$daystocheck = 7

#region CheckShadowCopies
# Uses WMI Win32_Volume to get drive letter from device id
Function Get-DriveLetters($server)
{
    $volumes = @{}
    $allvolumes = Get-WmiObject win32_volume -ComputerName $server -Property DeviceID, Name
    foreach ($v in $allvolumes)
        {
            $volumes.add($v.DeviceID, $v.Name)
        }
    $volumes
}

Function Check-ShadowCopies
{
<# 
.SYNOPSIS
Checks Shadow Copy Status of specified servers for past 7 days.

.DESCRIPTION
Checks Shadow Copy Status on specified servers for past 7 days.  Script designed to be ran as a scheduled task.

.EXAMPLE
powershell.exe Check-ShadowCopies.ps1

No parameters required.  Run the script to return the content of the various backup locations.
#>
    $allshadowcopies = @()
    Foreach ($server in $servers)
        {
            $driveletters = Get-DriveLetters $server
            $shadowcopies = Get-WmiObject -Class "Win32_ShadowCopy" -ComputerName $server -Property InstallDate, VolumeName
                Foreach ($copy in $shadowcopies)
                    {
                        $shadowcopy = New-Object System.Object

                        $date = [datetime]::ParseExact($copy.InstallDate.Split(".")[0], "yyyyMMddHHmmss", $null)

                        $shadowcopy | Add-Member -Type NoteProperty -Name Server -Value $server
                        $shadowcopy | Add-Member -Type NoteProperty -Name Date -Value $date
                        $shadowcopy | Add-Member -Type NoteProperty -Name Drive -Value $driveletters.Item($copy.VolumeName)

                        If ($date -gt (Get-Date).AddDays(-$daystocheck))
                            {
                                $allshadowcopies += $shadowcopy
                            }
                    }
        }
    $allshadowcopies | Sort-Object Date -Descending
}
#endregion CheckShadowCopies

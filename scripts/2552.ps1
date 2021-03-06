#======================================================================================
#              File Name : DataStoreBalancer.ps1
#        Original Author : Kenneth C. Mazie 
#            Description : Scans VM datastores and moves  a single VM from the most heavily
#                        :   loaded to the most lightly loaded.
#                        :
#                  Notes : This script was cobbled together from various sources around the
#                        :   Internet and adjusted to suit my purposes.  Original scripts at
#                        :   http://poshcode.org/2449 and http://www.vcritical.com/2009/10/powershell-prevents-datastore-emergencies/
#                        :
#              Operation : Normal operation is with no command line options.  Script may be  
#                        :   fed from Virtual Center alarms to automatically start clearing
#                        :   VM guests from conjested datastores.  As written will run a single
#                        :   time and exit.  May be looped via internal or external triggers
#                        :   if desired, additional coding is required.
#                        : The script creates a new Windows Application Event Log called
#                        :   "PowerShellScripts" and writes status to it.  Also optional  
#                        :   status to the screen is available. 
#                        : To call from Virtual Center to automatically relocate a guest VM 
#                        :   when a datastore goes into alarm set an alarm to run a program
#                        :   and use a command line similar to the following:
#                        :   "c:\windows\system32\cmd.exe" "/c echo.|powershell.exe -nologo -noprofile -noninteractive c:\scripts\datastoremigrator.ps1"
#                        :   More on this at http://www.vcritical.com/2009/10/powershell-prevents-datastore-emergencies/
#                        :
#               Warnings : Remove the comment from the WHATIF to enable the move
#                        : 
#	               Legal : Public Domain.  Modify and redistribute freely.  No rights reserved.
#              	         : SCRIPT PROVIDED "AS IS" WITHOUT WARRANTIES OR GUARANTEES OF ANY KIND.
#                        : USE AT YOUR OWN RISK. NO TECHNICAL SUPPORT PROVIDED.
#                        :
#         Last Update by : Kenneth C. Mazie 
#        Version History : v1.0 - 02-18-11 - Original 
#         Change History : v1.1 - 00-00-00 -            
#
#=======================================================================================

#--[ Clear the screen, disable error notification, and create the event log ]--
Clear-Host 
$ErrorActionPreference = "SilentlyContinue"
New-EventLog Application PowerShellScripts
$EventID = "33333"  #--[ Set whatever Event ID number here that you like ]--

#--[ Load the VMWare snapin if not already ]--
$out = Get-PSSnapin | Where-Object {$_.Name -like "vmware.vimautomation.core"}
if ($out -eq $null){Add-PSSnapin vmware.vimautomation.core}

#--[ Connect to the Virtual Center server ]--
Connect-VIServer -Server <YourVCenterServer> -User <UserName> -Password <Password>

#--[ Write status to Windows event log ]--
#Write-Output "`n$(Get-Date)- Script started`n"
Write-EventLog -LogName Application -Source PowerShellScripts -EntryType Information -EventId $EventID -Message "`n$(Get-Date) - VMWare Datastore balancing script started`n"

#--[ Get the list of valid datastores and pick the ones with the most and least free space.
$DataStores = Get-datastore | Sort-Object FreeSpaceMB | Where-Object {$_.Name -like "A*" -or $_.Name -like "B*" -and $_.Name -notmatch "B202_Perf"}
$DSInfo = $DataStores | Select-Object Name,@{n="CapacityGB";e={[math]::round(($_.CapacityMB/1024))}},@{n="FreeSpaceGB";e={[math]::round(($_.FreeSpaceMB/1024))}},@{n="FreeSpacePercent";e={[math]::round(($_.FreeSpaceMB/$_.CapacityMB*100))}} | Sort-Object FreeSpacePercent
$DSLeastFree = $DSInfo | Select-Object -first 1
$DSMostFree  = $DSInfo | Select-Object -last  1

#--[ Write status to Windows event log ]--
#Write-Output $DSLeastFree #| Select-Object FreeSpacePercent
#Write-Output $DSMostFree
Write-EventLog -LogName Application -Source PowerShellScripts -EntryType Information -EventId $EventID -Message "`n $(Get-Date) - The $(($DSLeastFree).Name) Datastore has the least free space and The $(($DSMostFree).Name) Datastore has the most free space available.`n"

#--[ Pick the largest VM on the datastore to relocate that does not match the exclusion ]--
#--[ NOTE: Swap these lines to switch to using a datastore targeted from a VirtualCenter alarm. ]--
$SourceVMToMove = Get-VM -Datastore $DSLeastFree | Where-Object {$_.Name -notlike "P*"} | select Name, @{ Name="Disks"; Expression={ ($_ | get-harddisk | measure-object -property CapacityKB -sum).Sum }} | sort Disks -descending | Select -first 1 
#$SourceVMToMove = Get-VM -Datastore $env:VMWARE_ALARM_TARGET_NAME | Where-Object {$_.Name -notlike "P*"} | select Name, @{ Name="Disks"; Expression={ ($_ | get-harddisk | measure-object -property CapacityKB -sum).Sum }} | sort Disks -descending | Select -first 1 

#--[ Write status to Windows event log ]--
#Write-Output "`n $(Get-Date)- Moving $($SourceVMToMove.Name) from $(($DSTLeastFree).Name) to $(($DSTMostFree).Name)`n"
Write-EventLog -LogName Application -Source PowerShellScripts -EntryType Information -EventId $EventID -Message "`n $(Get-Date) - Moving $($SourceVMToMove.Name) from $(($DSLeastFree).Name) to $(($DSMostFree).Name)`n"

#--[ svMotion the VM to the datastore with the most free space ]--
Move-VM -VM $SourceVMToMove.Name -Datastore ($DSMostFree).Name -Confirm:$false -whatif  #--[ Comment out the WHATIF to enable the move ]--

#--[ Write status to Windows event log ]--
#Write-Output "`n$(Get-Date)- Script finished`n"
Write-EventLog -LogName Application -Source PowerShellScripts -EntryType Information -EventId $EventID -Message "`n $(Get-Date) - VMWare Datastore balancing script completed`n"


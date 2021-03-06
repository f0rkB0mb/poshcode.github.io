# Note, the code for the Import function below must be in the same Directory as this powershell script.
# Function that gets Advanced VM settings in .VMX file
Import-Module ./Get-AdvancedVM.ps1

# Function that fixes an issue with Appending to a .csv file
Import-Module ./Export-Csv.ps1

# Change as needed to connnect to a different Virtual Center
Connect-VIserver <#Insert vCenter Server Name Here#>

#Define Which Cluster to scan
$Cluster = <#Insert Clustername Here #>

Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"tools.guestlib.enableHostInfo"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "tools.guestlib.enableHostInfo").Value }} | Export-Csv C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.ghi.autologon.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.ghi.autologon.disable").Value }} | Export-Csv  -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.bios.bbs.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.bios.bbs.disable").Value }} | Export-Csv  -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.getCreds.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.getCreds.disable").Value }} | Export-Csv  -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.ghi.launchmenu.change"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.ghi.launchmenu.change").Value }} | Export-Csv  -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.memSchedFakeSampleStats.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.memSchedFakeSampleStats.disable").Value }} | Export-Csv  -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.ghi.protocolhandler.info.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.ghi.protocolhandler.info.disable").Value }} | Export-Csv   -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.ghi.host.shellAction.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.ghi.host.shellAction.disable").Value }} | Export-Csv   -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.dispTopoRequest.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.dispTopoRequest.disable").Value }} | Export-Csv   -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.trashFolderState.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.trashFolderState.disable").Value }} | Export-Csv   -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.ghi.trayicon.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.ghi.trayicon.disable").Value }} | Export-Csv   -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.unity.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.unity.disable").Value }} | Export-Csv   -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.unityInterlockOperation.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.unityInterlockOperation.disable").Value }} | Export-Csv   -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.unity.push.update.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.unity.push.update.disable").Value }} | Export-Csv   -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.unity.taskbar.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.unity.taskbar.disable").Value }} | Export-Csv   -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.unityActive.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.unityActive.disable").Value }} | Export-Csv   -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.unity.windowContents.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.unity.windowContents.disable").Value }} | Export-Csv   -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.vmxDnDVersionGet.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.vmxDnDVersionGet.disable").Value }} | Export-Csv -Append C:\powershell\AdvancedVMsettings\Output.csv
Get-Cluster $Cluster | Get-VM  |Select Name, @{N="Key";E={"isolation.tools.guestDnDVersionSet.disable"}}, @{N="Setting";E={($_ | Get-VMAdvancedConfiguration -key "isolation.tools.guestDnDVersionSet.disable").Value }} | Export-Csv   -Append C:\powershell\AdvancedVMsettings\Output.csv


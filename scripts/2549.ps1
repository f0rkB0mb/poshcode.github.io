
#======================================================================================
#              File Name : FixInvalidVMs.ps1
#        Original Author : Kenneth C. Mazie 
#            Description : Resets all "invald" or "inaccessible" virtual machines
#                        : 
#                  Notes : Will cycle through an entire Virtual Center instance and 
#                        :   identify any virtual machines that are "invald" or
#                        :   "inaccessible" as a result of a host crash where running
#                        :   VMs were left with lock files in place.  The script must 
#                        :   have PUTTY installed and configured.  A local status echo
#                        :   as well as a date and time stamped log file is written
#                        :   in the folder that this script is executed from if the 
#                        :   options are set below.
#                Process : VMs that are processed are removed from inventory, then
#                        :   the ESX host is connected to and the associated lock files
#                        :   are deleted. ONLY files named ".lckxxxxxxx" are deleted, and
#                        :   ONLY in the specific folder and datastore that the target
#                        :   VM resides in. The VM is then re-registered in Virtual 
#                        :   Center and moved back into the original folder it came
#                        :   from.
#                        : 
#               Testing  : The only way I found to simulate invalid VMs is to rename 
#                        :   the VM folder on the datastore and then restart the ESX host.  
#                        :
#               Warnings : The script connects to an ESX host and performs delete 
#                        :   operations on hidden lock files.  You were warned.
#                        :   NOTE: all harmfull operations are commented out by default
#                        :   via the "LIVEOPS" variable.  This script was written for
#                        :   and tested in my environment, yours may require significant
#                        :   changes to the script to function properly.
#                        :  
$LiveOps = $False    #--[ Change to $True to enable all destructive operations ]-- 
#                        :  
#                  Legal : Script provided "AS IS" without warranties or guarantees of any
#                        :   kind.  USE AT YOUR OWN RISK.  Public domain, no rights reserved.
#                        :   Please keep this header in tact if at all possible.
#                        : 
#                Credits : Code snippets and/or ideas came from many sources including but 
#                        :   not limited to the following:
#                        : Kevin Markwardt: http://www.kevinmarkwardt.com/script.php?id=15
#                        : LucD: http://communities.vmware.com/thread/213290
#                        : Anders Mikkelsen: http://www.amikkelsen.com/?p=357
#                        : 
#                  Legal : Script provided "AS IS" without warranties or guarantees of any
#                        :   kind.  USE AT YOUR OWN RISK.  Public domain, no rights reserved.
#                        : 
#         Last Update by : Kenneth C. Mazie 
#        Version History : v1.0 - 03-04-11 - Original 
#         Change History : v1.1 - 00-00-00 - 
#                        :
#=======================================================================================

#--[ Clear the screen, disable error notification ]--
Clear-Host 
$ErrorActionPreference = "SilentlyContinue"

#--[ Load the VMWare snapin if not already ]--
$out = Get-PSSnapin | Where-Object {$_.Name -like "vmware.vimautomation.core"}
if ($out -eq $null){Add-PSSnapin vmware.vimautomation.core}

#--[ Connect to the Virtual Center server ]--
Connect-VIServer -Server <YOUR-VC-SERVER> -User <VC-USER> -Password <PASSWORD> | out-null

#--[ Get Current Script Path ]--
$ScriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition

#--[ Set status / logging options ]--
$StatEcho = $True  #--[ True to echo to screen ]--
$StatLog = $True   #--[ True to write a log file ]--

#--[ Get VM Folder Function ]--
filter Get-FolderPath {
    $_ | Get-View | % {
        $row = "" | select Name, Path
        $row.Name = $_.Name
 
        $current = Get-View $_.Parent
        #$path = $_.Name # Uncomment out this line if you do want the VM Name to appear at the end of the path
        $path = ""
        do {
            $parent = $current
            if($parent.Name -ne "vm"){$path = $parent.Name + "\" + $path}
            $current = Get-View $current.Parent
        } while ($current.Parent -ne $null)
        $row.Path = $path
        $row
    }
}

function BldPuttyCmd ($x)
{
#--[ The linked commands that PUTTY executes ]--
#--[ This is called from 2 places.  Alter the commands to change what is done by PUTTY  ]--
#--[ As written it runs 2 chained Linux commends that will CD into the target VM folder ]--
#--[ and delete higgen lock files.                                                      ]--
return "`"cd $x && rm â€“rf .lck*`""
}

#--[ Initialize Variables ]--
$Target = ""
$Plink = "`"C:\Program Files (x86)\PuTTY\plink.exe`""              #--[ Complete path to PUTTY ]--
$PuttyUsername = "root"                                            #--[ Set to your ESX host username ]--
$PuttyHostname = "192.168.1.1"                                     #--[ Set to the hostname/Ip of an appropriate ESX host ]--
$PuttyPassword = "PASSWORD"                                        #--[ Set to your ESX host user password ]--
$PuttyLogon = $PuttyUsername +"@"+ $PuttyHostname
$PuttyCommand = BldPuttyCmd "<FullPathToVMX>"                      #--[ Inserts temporary text into the PUTTY command string ]--

#--[ Initailize Status Log ]--
If ($StatEcho -eq $True){
Write-Host "Starting run..."
Write-Host "============================================"
Write-Host "ESX Logon = $PuttyUsername"
Write-Host "ESX Host = $PuttyHostname" 
Write-Host "Putty executable path = $Plink"
Write-Host "Putty command = $PuttyCommand"
Write-Host "Script executed from: `"$ScriptPath`""
Write-Host "============================================"}
If ($StatLog -eq $True){
$LogFile = $ScriptPath+"\LogFile-{0:dd-MM-yyyy_HHmm}.log" -f (Get-Date)  
add-content $LogFile "Starting run..."
add-content $LogFile "============================================"
add-content $LogFile "ESX Logon = $PuttyUsername"
add-content $LogFile "ESX Host = $PuttyHostname" 
add-content $LogFile "Putty executable path = $Plink"
add-content $LogFile "Putty command = $PuttyCommand"
Add-Content $LogFile "Script executed from: `"$ScriptPath`""
add-content $LogFile "============================================"}

#--[ Do It ]--
$Invalid = Get-View -ViewType VirtualMachine | Where {-not $_.Config.Template} | Where{$_.Runtime.ConnectionState -eq â€œinvalidâ€ -or $_.Runtime.ConnectionState -eq â€œinaccessibleâ€} | sort Name
foreach ($vm in $Invalid){
   If ($StatLog -eq $True){add-content $LogFile "--------------------------------------------"}
   If ($StatEcho -eq $True){Write-Host "--------------------------------------------"}
   
   #--[ Gather Target Info ]--
   $Target = get-vm $vm.name 
   $TargetDataCenter = Get-Datacenter -VM $Target
   $TargetView = $Target | Get-View
   $TargetESXHost = $Target.host.name
   $TargetCluster = Get-Cluster -VM $Target
   $Datastores = Get-Datastore | select Name, Id
   $TargetDatastore = ($Datastores | where {$_.ID -match (($TargetView.Datastore | Select -First 1) | Select Value).Value} | Select Name).Name
   $TargetVCFolder = ($Target | Get-Folderpath).Path.Split("\")
   $VmxFullPath = "/vmfs/volumes/"+$TargetDatastore+"/"+$vm.name+"/"
   $TargetESX = Get-VMHost $TargetESXhost | Get-View
   $TargetResourcePool = Get-VMHost $TargetESXHost | Get-ResourcePool | Get-View
   $TargetFolder = Get-View (Get-Datacenter -Name $TargetDatacenter | Get-Folder -Name "vm").id
   $vmx = "[$TargetDatastore] "+$Target+"/"+$Target+".vmx"

   If ($StatEcho -eq $True){
   Write-Host "Identified $Target as INVALID or INACCESSIBLE"
   Write-Host "ESX Host = " $TargetESXhost
   Write-Host "DataCenter = $TargetDataCenter"
   Write-Host "Cluster = " $TargetCluster
   Write-Host "vCenter Folder = " $TargetVCFolder[1]  
   Write-Host "Datastore = "$TargetDatastore 
   Write-Host Full path to virtual disk = $VmxFullPath}
   If ($StatLog -eq $True){
   add-content $LogFile "Identified $Target as INVALID or INACCESSIBLE" 
   add-content $LogFile "ESX Host = $TargetESXhost"
   add-content $LogFile "DataCenter = $TargetDataCenter"
   add-content $LogFile "Cluster = $TargetCluster"
   add-content $LogFile "vCenter Folder = $TargetVCFolder[1]"
   add-content $LogFile "Datastore = [$TargetDatastore]"
   Add-Content $LogFile "Full path to virtual disk = $VmxFullPath"}
      		  
   #--[ Remove the VM from inventory ]-- 
   If ($LiveOps -eq $True){
      If ($StatEcho -eq $True){write-host "Removing $Target from vCenter inventory..."}
      If ($StatLog -eq $True){add-content $LogFile "Removing $Target from vCenter inventory..."}
      Get-vm -Name $Target | remove-vm -Confirm:$false 
   }else{	     
      If ($StatEcho -eq $True){write-host `t"LiveOps disabled: Simulating Removing $Target from vCenter inventory..."}
      If ($StatLog -eq $True){add-content $LogFile `t"LiveOps disabled: Simulating Removing $Target from vCenter inventory..."}
	  Get-vm -Name $Target | remove-vm -Confirm:$false -WhatIf 
   }
   #--[ Delete lock files ]--  
   $PuttyCommand = BldPuttyCmd $VmxFullPath #--[ Regenerate the PUTTY comand line ]--
   If ($LiveOps -eq $True){
      If ($StatEcho -eq $True){write-host "Invoking PUTTY, Deleting all `".lck`" files in folder..."}
      If ($StatLog -eq $True){add-content $LogFile "Invoking PUTTY, Deleting all `".lck`" files in folder..."}
	  Start-Process $plink -ArgumentList "$PuttyLogon","-pw $PuttyPassword","$PuttyCommand" | Out-Null 
   }else{
	  If ($StatEcho -eq $True){write-host `t"LiveOps disabled: " $plink -ArgumentList "$PuttyLogon","-pw $PuttyPassword","$PuttyCommand"}
      If ($StatLog -eq $True){add-content $LogFile `t"LiveOps disabled: " $plink -ArgumentList "$PuttyLogon","-pw $PuttyPassword","$PuttyCommand"}
   }
   
   #--[ Re-register the target VM ]--
   If ($LiveOps -eq $True){
      if((Get-VM $Target -ea SilentlyContinue) -eq $null){  #--[ Check if VM is already registered ]-- 
	     If ($StatEcho -eq $True){Write-Host "Registering $Target into Virtual Center..."}
	     If ($StatLog -eq $True){add-content $LogFile "Registering $Target into Virtual Center..."}
		 $Task1 = $TargetFolder.RegisterVM_Task($vmx,$Target,$FALSE,$TargetResourcePool.MoRef,$TargetESX.MoRef)
         #--[ Wait untill VM is registered ]--
         $Task2 = Get-View $Task1
         while($Task1.info.state -eq "running" -or $Task1.info.state -eq "queued"){
            $Task2 = Get-View $Task1
            }
         #--[ Test the return code of the RegisterVM_Task for error state ]--
         if($Task1.info.error -eq $null){		 
		    #--[ No error ]--
		 }else{ 
		    #--[ error ]--
            If ($StatEcho -eq $True){Write-Host "Registration of $Target errored out!!!  Something went wrong!!!"}
 	        If ($StatLog -eq $True){add-content $LogFile "Registration of $Target errored out!!!  Something went wrong!!!"}
		    # break  #--[ Optional break ]--
		 }
      }else{
	     If ($StatEcho -eq $True){Write-Host "$Target VM Already Registered!!!  Something went wrong!!!"}
 	     If ($StatLog -eq $True){add-content $LogFile "$Target VM Already Registered!!!  Something went wrong!!!"}
	     # break  #--[ Optional break ]--
	  }
	}else{
	   If ($StatEcho -eq $True){
	   write-host `t"LiveOps disabled: Registration bypassed"}
       write-host `t"Command line would have been: `"TargetFolder.RegisterVM_Task  `" $vmx,$Target,FALSE,$TargetResourcePool.name ,$TargetESX.name" 
	   If ($StatLog -eq $True){add-content $LogFile `t"LiveOps disabled: Registration bypassed"}
    }

   #--[ Move the VM to the proper folder ]--	
   If ($LiveOps -eq $True){
      If ($StatEcho -eq $True){write-host "Moving $Target back into proper folder..."}
      If ($StatLog -eq $True){add-content $LogFile "Moving $Target back into proper folder..." }
	  move-vm -VM $(get-vm $Target) -Destination $(Get-Folder -Name $TargetVCFolder[1] -Location $(Get-Datacenter $TargetDataCenter))
   }else{
      If ($StatEcho -eq $True){write-host "LiveOps disabled: Folder Move bypassed"}
      If ($StatLog -eq $True){add-content $LogFile "LiveOps disabled: Folder Move bypassed"}
	  move-vm -VM $(get-vm $Target) -Destination $(Get-Folder -Name $TargetVCFolder[1] -Location $(Get-Datacenter $TargetDataCenter)) -WhatIf
   }

   #--[ Optional VM Power On ]--	
   if ((get-vm -name $Target).PowerState -eq "PoweredOff"){
      If ($LiveOps -eq $True){
         If ($StatEcho -eq $True){Write-Host "Powering on $Target..."}
         If ($StatLog -eq $True){add-content $LogFile "Powering on $Target..."}
	     Start-VM -VM $Target -Confirm:$false -RunAsync
     }else{
         If ($StatEcho -eq $True){write-host `t"LiveOps disabled: Power On bypassed"}
         If ($StatLog -eq $True){add-content $LogFile `t"LiveOps disabled: Power On bypassed"}
	     Start-VM -VM $Target -whatif
     }
   }
}
If ($StatLog -eq $True){add-content $LogFile "============================================"
add-content $LogFile "Completed..."}
If ($StatEcho -eq $True){Write-Host  "============================================"
write-host "Completed..."}
$fullpath = $null

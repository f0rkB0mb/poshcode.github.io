Param (
	$viServer,
	$bakVM,
	$lxDest,
)

#region check
if (!$viServer) { $viServer = Read-Host -Prompt "VI Server " }
if (!$bakVM) { $bakVM = Read-Host -Prompt "VM to Backup " }
if (!$lxDest) { $lxDest = Read-Host -Prompt "Backup Path (ex. /srv/backup) " }
#endregion

#region globalvars
$encoding = "OEM"
$version = "0.4"
$scriptout = @()
#endregion

#region stkmvars
$viUser = "vmware"
$viPass = "vmware"
#endregion

Write-Host "viBackup Script Generator - " $version
Write-Host "--------------------------------------------"

if (($vmCon = Connect-VIServer -Protocol https $viServer) -eq "") { exit }
$vm = Get-VM $bakVM -Server $vmCon -ErrorAction SilentlyContinue

if (!$vm) {
	Write-Host "No VM found."
	Write-Host "Enter the Display Name from the VI Center:" -NoNewline
	$tvm = Read-Host
	if (!($vm=Get-VM $tvm -ErrorAction SilentlyContinue)) {
		return $false
		exit
	}
	Write-Host "You have entered 2 different Names. Please check that the VMX and the VM Name are the same!"
	Write-Host -ForegroundColor yellow "Entered VMX Name: {$bakVM}"
	Write-Host -ForegroundColor yellow "Entered VM Name: {$tvm}"
	Write-Host -ForegroundColor yellow "Returned VM Name: {$vm}"
	Write-Host -ForegroundColor yellow "IS THIS CORRECT (Yes/No)?:" -NoNewline
	$sure = Read-Host
	if ($sure -ne "yes") { exit }
}

#check Snapshots
if ((Get-Snapshot -VM $vm -Server $vmCon | Measure-Object | select count).Count -ne "0") {
	Write-Host "VM has Snapshots. No Backup possible."
	return $false
	exit
}

#write script
$scriptname = $vm.name + ".sh"
$vmname = $vm.Name
$vmhost = $vm.Host

#generate Text

$header = "#!/bin/bash"
$user = "USER=`"${viUser}`""
$pass = "PASS=`"${viPass}`""
$dest = "DEST=`"${lxDest}`""
$lxVM = "VM=`"${vmname}`""

#region writefile

$scriptout += $header 
$scriptout += $user 
$scriptout += $pass 
$scriptout += $dest 
$scriptout += $lxvm 
$scriptout += "" 
$scriptout += "BKUP=``vmrun -h https://${viserver}/sdk -u `${USER} -p `${PASS} list | grep `${VM}`` " 
$scriptout += "SNAPCHECK=``vmware-cmd -H ${viserver} -T ${vmhost} -U `${USER} -P `${PASS} `"`${BKUP}`" hassnapshot`` "
$scriptout += "if [ `"`$SNAPCHECK`" != `"hassnapshot () =`" ]; then `n echo 'VM has a Snapshot. Arborting...' `n exit `n fi" 
$scriptout += "vmrun -T esx -h https://${viserver}/sdk -u `${USER} -p `${PASS} snapshot `"`${BKUP}`" vmBackup"

# Hard Disk
foreach ($hd in $vm.Harddisks) {
	$hdname = $hd.Filename
	$vifs = "vifs --server ${viserver} --dc 'KM' --username `${USER} --password `${PASS}  --get `"``echo $hdname | sed 's/.vmdk/-flat.vmdk/g'```" `${DEST}/`${VM}.vmdk "
	$scriptout += $vifs
}

$scriptout += "vmrun -T esx -h https://${viserver}/sdk -u `${USER} -p `${PASS} deleteSnapshot `"`${BKUP}`" vmBackup" 

$scriptout | Out-File $scriptname -Encoding $encoding
#endregion

Write-Host "Finished"
Write-Host "Don't forget to convert the script under *nix/Linux with dos2unix!"


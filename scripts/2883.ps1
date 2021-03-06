#############################################################
# Deploy-VM.ps1 v1.1
# David Summers 2011/8/2
# Script to deploy VM(s) from Template(s) and set appropriate
# IP config for Windows VMs.  Also sets # of CPUs, MemoryMB,
# port group, and several custom attributes.
# Moves deployed VM to specific VMs/Template blue folder.
# Assumptions:
# not connected to viserver before running
# Customization spec and templates in place and tested
#############################################################

# Syntax and sample for CSV File:
# template,datastore,diskformat,vmhost,custspec,vmname,ipaddress,subnet,gateway,pdns,sdns,pwins,swins,datacenter,folder,dvpg,memsize,cpucount,appgroup,owner,techcontact,vmdescription,createdate,reviewdate,creator
# template.2008ent64R2sp1,DS1,thick,host1.domain.com,2008r2CustSpec,Guest1,10.50.35.10,255.255.255.0,10.50.35.1,10.10.0.50,10.10.0.51,10.10.0.50,10.10.0.51,DCName,FldrNm,dvpg.10.APP1,2048,1,Monitoring,Road Runner,WE Coyote,App1 Prod Web,2011.07.28,2014.07.28,Elmer Fudd

# 
$vmlist = Import-CSV "H:\Flats\Scripts\Input\deployVMserverinfo.csv"


# Load PowerCLI
$psSnapInName = "VMware.VimAutomation.Core"
if (-not (Get-PSSnapin -Name $psSnapInName -ErrorAction SilentlyContinue))
{
     # Exit if the PowerCLI snapin can't be loaded
     Add-PSSnapin -Name $psSnapInName -ErrorAction Stop
}

connect-viserver virtualcenter.yourdom.com

foreach ($item in $vmlist) {

	# Map variables
	$template = $item.template
	$datastore = $item.datastore
	$diskformat = $item.diskformat
	$vmhost = $item.vmhost
	$custspec = $item.custspec
	$vmname = $item.vmname
	$ipaddr = $item.ipaddress
	$subnet = $item.subnet
	$gateway = $item.gateway
	$pdns = $item.pdns
	$pwins = $item.pwins
	$sdns = $item.sdns
	$swins = $item.swins
	$datacenter = $item.datacenter
	$destfolder = $item.folder
	$dvpg = $item.dvpg
	$memsize = $item.memsize
	$cpucount = $item.cpucount
	$appgroup = $item.appgroup
	$owner = $item.owner
	$technicalcontact = $item.techcontact
	$description = $item.vmdescription
	$createdate = $item.createdate
	$reviewdate = $item.reviewdate
	$creator = $item.creator


	#Configure the Customization Spec info
	Get-OSCustomizationSpec $custspec | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $ipaddr -SubnetMask $subnet -DefaultGateway $gateway -Dns $pdns,$sdns -Wins $pwins,$swins

	#Deploy the VM based on the template with the adjusted Customization Specification
	New-VM -Name $vmname -Template $template -Datastore $datastore -DiskStorageFormat $diskformat -VMHost $vmhost | Set-VM -OSCustomizationSpec $custspec -Confirm:$false

	#Move VM to Application Group's folder
	Get-vm -Name $vmname | move-vm -Destination $(Get-Folder -Name $DestFolder -Location $(Get-Datacenter $Datacenter))

	#Set the Port Group Network Name (Match PortGroup names with the VLAN name)
	Get-VM -Name $vmname | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $dvpg -Confirm:$false

	#Set the number of CPUs and MB of RAM
	Get-VM -Name $vmname | Set-VM -MemoryMB $memsize -NumCpu $cpucount -Confirm:$false

	#Set the Custom Attribute Annotations
	#Comment out or adjust to fit your environment
	Set-annotation -Entity $vmname -CustomAttribute "App Group" -Value $AppGroup -Confirm:$false
	Set-annotation -Entity $vmname -CustomAttribute "Owner" -Value $Owner -Confirm:$false
	Set-annotation -Entity $vmname -CustomAttribute "Technical Contact" -Value $TechnicalContact -Confirm:$false
	Set-annotation -Entity $vmname -CustomAttribute "Description" -Value $Description -Confirm:$false
	Set-annotation -Entity $vmname -CustomAttribute "Create Date" -Value $CreateDate -Confirm:$false
	Set-annotation -Entity $vmname -CustomAttribute "Review Date" -Value $ReviewDate -Confirm:$false
	Set-annotation -Entity $vmname -CustomAttribute "Creator" -Value $Creator -Confirm:$false
	Set-annotation -Entity $vmname -CustomAttribute "Timeline" -Value "New" -Confirm:$false
	Set-annotation -Entity $vmname -CustomAttribute "Datacenter" -Value $item.datacenter -Confirm:$false
}

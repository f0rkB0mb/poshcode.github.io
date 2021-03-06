#The PowerShell Talk
#Building a HyperVisor Independent Script
#
#This script will take a VM (or host) object from the pipline, 
#and from that determine if you're connected to XenServer 
#or VMware, and return the apropriate UUID.

Begin { 
	#VMware VM Host (ESX) UUID
	$VMHost_UUID = @{ 
        Name = "VMHost_UUID" 
        Expression = { $_.Summary.Hardware.Uuid } 
    }
	#XenServer Host UUID
	$XenHost_UUID = @{
		Name = "XenHost_UUID"
		Expression = { $_.Uuid }
	} 
}

Process { 
    #Get the type of object we have
	$InputTypeName = $_.GetType().Name 
    
	#Do something with that object
	#is it VMware?
	if ( $InputTypeName -eq "VMHostImpl" ) { 
        $output = $_ | Get-View | Select-Object $VMHost_UUID 
    #is it Xen?
	} elseif ($InputTypeName -eq "Host"){
		$output = $_ | Select-Object $XenHost_UUID 
	#Otherwise throw an error
	} else { 
        Write-Host "`nPlease pass this script either a VMHost or VM object on the pipeline.`n" 
    }
	$output
}

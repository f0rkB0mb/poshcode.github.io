Begin {

	$disableCopy = "isolation.tools.copy.enable"
	$disableCopy_value = "false"
	$disablePaste = "isolation.tools.paste.enable"
	$disablePaste_value = "false"
	$disableGUI = "isolation.tools.setGUIOptions.enable"
	$disableGUI_vsalue = "false"
}

Process {
    #Make Sure it's a VM
	if ( $_ -isnot [VMware.VimAutomation.Client20.VirtualMachineImpl] ) { continue }
	
	#Setup our Object
	$vm = Get-View $_.Id
	$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
	$vmConfigSpec.extraconfig += New-Object VMware.Vim.optionvalue
	$vmConfigSpec.extraconfig[0].Key=$disableCopy
	$vmConfigSpec.extraconfig[0].Value=$disableCopy_value
	$vmConfigSpec.extraconfig[1].Key=$disablePaste
	$vmConfigSpec.extraconfig[1].Value=$disablePaste_value
	$vmConfigSpec.extraconfig[2].Key=$disableGUI
	$vmConfigSpec.extraconfig[2].Value=$disableGUI_value
	#Run the change
	$vm.ReconfigVM($vmConfigSpec)
}

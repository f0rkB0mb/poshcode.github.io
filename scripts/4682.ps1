Function Get-DeviceChassis () {
	[CmdletBinding()]
    Param($ComputerName = 'localhost')
 
	PROCESS { 
        $Output = New-Object PsObject -property @{ComputerName = $ComputerName;Chassis=''}
		try {
			$Model = (Get-WmiObject -Query "SELECT Model FROM Win32_ComputerSystem" -ComputerName $ComputerName).Model;
			if (($Model -like 'hp t*') -and ($Model -notlike 'hp touchsmart*')) {
	        	Write-Verbose "Found chassis to be thin client via WMI";
	        	$Output.Chassis = 'Thin Client'
	    	} else {
	        	Write-Verbose "Found chassis to be desktop via WMI";
	        	$Output.Chassis = 'Desktop'
	    	}##endif
	    } catch {
	    	if ((Get-Item "\\$ComputerName\admin$\explorer.exe").Attributes -match 'Compressed') {
				Write-Verbose "Found chassis to be thin client via compressed files";
				$Output.Chassis = 'Thin Client'
			} else {
				Write-Verbose "Found chassis to be desktop via compressed files";
				$Output.Chassis = 'Desktop'
			}
	    } finally {
            $Output
        }
	}
}

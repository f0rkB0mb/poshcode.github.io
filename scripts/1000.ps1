Add-PSSnapin "VMware.VimAutomation.Core"
Add-PSSnapIn "VMware.VumAutomation" 

# Connect to vCenter
$VC = Connect-VIServer (Read-Host "Enter vCenter server")

$vumConfig = Get-VumConfig
$EsxHost = Get-Inventory -Name (Read-Host "Enter ESX Host")
$CriticalHost = Get-Baseline -Name "Critical Host Updates"
$NonCriticalHost = Get-Baseline -Name "Non-critical Host Updates"

  # Enter Maintenance mode
  Set-VMHost $EsxHost -State Maintenance 

  # Attach baseline
  Attach-Baseline -Entity $EsxHost -Baseline $CriticalHost, $NonCriticalHost 
		
  # Check Compliance
  $ScanTask = Scan-Inventory $EsxHost -RunAsync
  Wait-Task -Task $ScanTask

  Get-Compliance -Entity $EsxHost

  # Remediate the ESX Host
  $RemediateTask = Remediate-Inventory -Entity $EsxHost -Baseline $CriticalHost, $NonCriticalHost -HostFailureAction $vumConfig.HostFailureAction -Confirm:$false
		
  Wait-Task -Task $RemediateTask		
				
  # Detach Baseline
  Detach-Baseline -Baseline $CriticalHost, $NonCriticalHost -Entity $EsxHost
		
  # Exit Mantenance mode
  Set-VMHost $EsxHost -State Connected	
	
# Disconnect from vCenter
Disconnect-VIServer -Confirm:$False	

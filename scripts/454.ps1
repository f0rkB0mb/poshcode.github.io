## Get-ActiveRules grabs the workflows running on the specified server
## Author: Jeremy D. Pavleck - Jeremy@Pavleck.NET
## Requires: The Microsoft.SystemCenter.Internal.Tasks.mp on the SP1 CD
## Notes: You can find this task inside the console by going to monitoring, computers and under "Windows Computer Tasks" run
##  "Show Running Rules and Monitors" for this object.
function Get-ActiveRules ([string]$server, [string]$location) {
If (!$location) { $location = "C:\$server-Rules.xml" }
# Create the Task object
$taskobj = Get-Task | Where-Object {$_.Name -eq "Microsoft.SystemCenter.GetAllRunningWorkflows"}
# Make sure we have it, if not, the MP isn't installed.
If (!$taskobj) {
Write-Host "Unable to find required monitoring tasks - MS System Center Internal Tasks MP needs to be installed." -ForeGroundColor Magenta;
break;
}
# Grab HealthService class object
$hsobj = Get-MonitoringClass -name "Microsoft.SystemCenter.HealthService"
# Find HealthService object defined for named server
$monobj = Get-MonitoringObject -MonitoringClass $hsobj | Where-Object {$_.DisplayName -match $server}
# Now actually proceed with the task. I have mine formatted like this version, but I've added some light
# error checking for the 'public' version.
#(Start-Task -task $taskobj -TargetMonitoringObject $monobj).Output | Out-File C:\$server-Rules.xml
$taskOut = Start-Task -Task $taskobj -TargetMonitoringObject $monobj 
# See if it worked, if it did, export out the OutPut part and save as an XML file, then display some items.
If ($taskOut.ErrorCode -eq 0) {
[xml]$taskXML = $taskOut.OutPut 
$ruleCount = $taskXML.DataItem.Count
Write-Host "Succeeded in gathering rules for $server" -ForeGroundColor Green
Write-Host "Currently $ruleCount rules active." -ForeGroundColor Green
Write-Host "Exporting to $location" -ForeGroundColor Green
$taskOut.OutPut | Out-File $location
} else {
Write-Host "Error gathering rules for $server" -ForeGroundColor Magenta
Write-Host "Error Code: " + $taskOut.ErrorCode -ForeGroundColor Magenta
Write-Host "Error Message: " + $taskOut.ErrorMessage -ForeGroundColor Magenta
}

} # End Get-ActiveRules
#######################

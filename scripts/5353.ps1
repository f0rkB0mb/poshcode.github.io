Function Stop-ServiceandProcess
# daniel.cheng@thomsonreuters.com
# Function: Stop service and associated Pid. Sometimes homegrown services has its Pid still terminating gracefully in the background.
{
    param (
        [string[]]$servers = 'localhost',
        [parameter(Mandatory)][string[]]$services,
        [int]$InterrogateServiceDelay = 1, # seconds
        [int]$killDelay = $null
    )

    $serviceState = @{
        00 = 'The request was accepted.';
        01 = 'The request is not supported.';
        02 = 'The user did not have the necessary access.';
        03 = 'The service cannot be stopped because other services that are running are dependent on it.';
        04 = 'The requested control code is not valid, or it is unacceptable to the service.';
        05 = 'The requested control code cannot be sent to the service because the state of the service (Win32_BaseService State property) is equal to 0, 1, or 2.';
        06 = 'The service has not been started.';
        07 = 'The service did not respond to the start request in a timely fashion.';
        08 = 'Unknown failure when starting the service.';
        09 = 'The directory path to the service executable file was not found.';
        10 = 'The service is already running.';
        11 = 'The database to add a new service is locked.';
        12 = 'A dependency this service relies on has been removed from the system.';
        13 = 'The service failed to find the service needed from a dependent service.';
        14 = 'The service has been disabled from the system.';
        15 = 'The service does not have the correct authentication to run on the system.';
        16 = 'This service is being removed from the system.';
        17 = 'The service has no execution thread.';
        18 = 'The service has circular dependencies when it starts.';
        19 = 'A service is running under the same name.';
        20 = 'The service name has invalid characters.';
        21 = 'Invalid parameters have been passed to the service.';
        22 = 'The account under which this service runs is either invalid or lacks the permissions to run the service.';
        23 = 'The service exists in the database of services available from the system.';
        24 = 'The service is currently paused in the system.'
    }

    foreach ($server in $servers) {foreach ($service in $services) {
        $currentService = gwmi -ComputerName $server -Class win32_service -Filter "name='$($service)'" -ea SilentlyContinue
        if ($currentService -isnot [object]) {
            throw "Error with creating object for $($server):$('$service')!"
        } else {
            switch ($currentService) {
                {
                    $_.StartMode -ne 'Disabled' -and `
                    $_.State -ne 'Stopped' -and `
                    $_.ProcessId -ne 0
                } {
                    Write-Output "$(Get-Date -Format s): $($env:computername): Service ('$($service)', Pid=$($currentService.ProcessId)) stop command sent to $($server)."
                    Write-Output "$(Get-Date -Format s): $($server): StopService('$($service)', Pid=$($currentService.ProcessId)): $($serviceState.$([int]$currentService.StopService().ReturnValue))"
                    $timeElapsed = [System.Diagnostics.Stopwatch]::StartNew()
                    do
                    {
                        switch ($exitCode = $([int]$currentService.InterrogateService().ReturnValue)){
                            4 {Write-Host -NoNewline '.'}
                            default {Write-Output "$(Get-Date -Format s): $($server): InterrogateService('$($service)', Pid=$($currentService.ProcessId)): (exit code=$($exitCode)) $($serviceState.$exitCode)"}
                        }

                        if ($killDelay -ne 0 -and $timeElapsed.Elapsed.Seconds -ge $killDelay) {
                            Write-Output "$(Get-Date -Format s): $($env:computername): Process ('$($service)', Pid=$($currentService.ProcessId)) kill command sent to $($server)."
                            Stop-Process -Id $currentService.ProcessId -Force
                        }
                        Start-Sleep -Seconds $InterrogateServiceDelay
                    } until ([bool]!$(Get-Process -ComputerName $server -Id $currentService.ProcessId -ea SilentlyContinue).Id)
                    $timeElapsed.Stop()
                    Write-Output "Operation took $($timeElapsed.Elapsed.Seconds) seconds."
                }
                default {Write-Output "No stop operation necessary (stopped already) or possible (disabled)."}
            }
            gwmi -ComputerName $server -Class win32_service -Filter "name='$($service)'" | select PSComputerName, Name, ServiceType, StartMode, State, ProcessId, PathName | ft -AutoSize
        }
    }}
}

Stop-ServiceandProcess -servers dc2 -services 'Bonjour Service', w32time, spooler -killDelay 3

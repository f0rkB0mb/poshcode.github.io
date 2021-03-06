#########################################################################
## DuckDNS Powershell                                                  ##
## This script needs to be run from an Administrator Powershell prompt ##
## Otherwise it won't be able to create the Eventlog entry to post     ##
## problems to.                                                        ##
#########################################################################

# Make your changes here!
[string]$MyDomain       = "YOURDOMAIN"
[string]$MyToken        = "YOURTOKEN"
# Update interval in minutes
[int]$MyUpdateInterval  = 5

# Leave $MyIP alone unless you know what you're doing :)
$MyIP     = ""

# DON'T MAKE CHANGES BELOW THIS LINE

# This scriptblock is the code which does the actual update call to the
# DuckDNS web service.
[scriptblock]$UpdateDuckDns = {
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$strUrl
    )
    $Encoding = [System.Text.Encoding]::UTF8;

    # Run the call to DuckDNS's website
    $HTTP_Response = Invoke-WebRequest -Uri $duckdns_url;

    # Turn the response into english ;)
    $Text_Response = $Encoding.GetString($HTTP_Response.Content);

    # If the response is anything other than 'OK' then log an error in the windows event log
    if($Text_Response -ne "OK"){
        Write-EventLog -LogName Application -Source "DuckDNS Updater" -EntryType Information -EventID 1 -Message "DuckDNS Update failed for some reason. Check your Domain or Token.";
    }
}

# This scriptblock is the code which gets run when the system starts up each time,
# and is responsible for setting up the job which will repeat every five minutes
# to update your IP address with DuckDNS
[scriptblock]$SetupRepeatingJob = {
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$strDomain,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$strToken,
        [Parameter(Mandatory=$true,Position=2)]
        [int]$iUpdateInterval,
        [Parameter(Mandatory=$false,Position=3)]
        [string]$strIP=""
    )
    # Build DuckDNS update URL using supplied domain, token and optional IP parameters
    $duckdns_url = "https://www.duckdns.org/update?domains=" + $strDomain + "&token=" + $strToken + "&ip=" + $strIP;

    # Set how often we want the job to repeat based on the interval set at the start of the script
    $RepeatTimeSpan = New-TimeSpan -Minutes $iUpdateInterval;

    # Set the time to start running this job (it will be $iUpdateInterval minutes from now)
    $At = $(Get-Date) + $RepeatTimeSpan;

    # Create the trigger to start this job
    $UpdateTrigger = New-JobTrigger -Once -At $At -RepetitionInterval $RepeatTimeSpan -RepeatIndefinitely;

    # Register the job with Windows Task scheduling system
    Register-ScheduledJob -Name "RunDuckDnsUpdate" -ScriptBlock $UpdateDuckDns -Trigger $UpdateTrigger -ArgumentList @($duckdns_url);
}

# Check to see if the script is being run under adminstrator credentials, and stop if it's not.
if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
    Write-Warning "You need to run this from an Administrator Powershell prompt"
    Break
}

# Check to see if the "DuckDNS Updater" event log source already exists,
# and if it doesn't then create it
if (!([System.Diagnostics.EventLog]::SourceExists("DuckDNS Updater"))){
    New-EventLog  -LogName "Application" -Source "DuckDNS Updater"
}

# Set the trigger for the bootup task
$StartTrigger = New-JobTrigger -AtStartup

# Check to see if the user is super advanced and supplied their own IP address or not
if($MyIP.Length -ne 0){
    # Register the job that will run when windows first starts with the Windows Task Scheduler service
    Register-ScheduledJob -Name "StartDuckDnsJob" -ScriptBlock $SetupRepeatingJob -Trigger $StartTrigger -ArgumentList @($MyDomain,$MyToken,$MyUpdateInterval,$MyIP)
    # Run the actual update job
    & $SetupRepeatingJob $MyDomain $MyToken $MyUpdateInterval $MyIP
} else {
    # Register the job that will run when windows first starts with the Windows Task Scheduler service
    Register-ScheduledJob -Name "StartDuckDnsJob" -ScriptBlock $SetupRepeatingJob -Trigger $StartTrigger -ArgumentList @($MyDomain,$MyToken,$MyUpdateInterval)
    # Run the actual update job
    & $SetupRepeatingJob $MyDomain $MyToken $MyUpdateInterval
}

Write-Host "All done - your DuckDNS will now update automatically, and will continue to do so across system restarts."
Write-Host "Have a nice day!"

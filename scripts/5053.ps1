Function Get-ServerUptime {
<#
	.SYNOPSIS
		gets Server Uptime Info

	.DESCRIPTION
		Uses Win32_ComputerSystem to get the LastBootUptime from Remote Machine.
        Creates a PSObject and writes it to pipeline
	                         

    .EXAMPLE
       
       You can pipe the computer names, take it from a text file or pass objects with ComputerName property

        PS C:\> Get-ServerUptime -ComputerName DeterDC -Verbose
        VERBOSE: Starting the Function...Checking if ErrorFile exists
        VERBOSE:  ErrorFile exists & logging time to it - C:\Users\DexterPOSH\Desktop\UpTimeError.txt
        VERBOSE: Checking if DeterDC is online
        VERBOSE: DeterDC is online

        ComputerName                                      Uptime                                            LastReboot                                      
        ------------                                      ------                                            ----------                                      
        DeterDC                                           137 Days 7 Hours 4 Min 46 sec                     11/19/2013 11:11:15 AM                          
        VERBOSE: Ending the Function

    .INPUTS
        System.String[]

	.OUTPUTS
		PSObject[]

	.NOTES
		Original Script : Bhargav Shukla MSFT
        Url - http://blogs.technet.com/b/bshukla/archive/2010/12/09/powershell-script-to-report-uptime.aspx

        Modified by - DexterPOSH
        Blog Url - http://dexterposgh.blogspot.com
#>
[CmdletBinding()]
#Requires -RunAsAdministrator
#Requires -version 3.0
Param
(
    # Specify the ComputerNames (Default is the local machine)
   	[Parameter(Position=0, Mandatory=$false,
				helpmessage="Enter the ComputerNames to check uptime on",
				ValueFromPipeline=$true,
				ValueFromPipelineByPropertyName=$true
				)]
	[String[]]$ComputerName=$env:COMPUTERNAME,

    # Error Log file , Default path User Desktop\UpTimeError.txt
    [Parameter(Mandatory=$false,helpmessage="Enter the Startup Type of the Service to be set")]
    [string]$ErrorFile="$([System.Environment]::GetFolderPath("Desktop"))\UpTimeError.txt",

    
    [Parameter(Mandatory=$false,helpmessage="Enter the Credentials to Use")]
    [System.Management.Automation.PSCredential]$Credentials = [System.Management.Automation.PSCredential]::Empty
	)

BEGIN
{
    Write-Verbose -Message "Starting the Function...Checking if ErrorFile exists" 
    #CReate the Errofile ...it will log Offline machines, Machines with issues
    if (!(Test-Path -Path $ErrorFile -PathType Leaf))
    {
        Write-Verbose -Message "Creating ErrorFile & logging time to it - $ErrorFile"
        New-Item -Path $ErrorFile -ItemType file | Out-Null
        Add-Content -Value "$("#"*40)$(Get-Date)$("#"*40)" -Path $ErrorFile
    
    }
    else
    {
            Write-Verbose -Message " ErrorFile exists & logging time to it - $ErrorFile"
             Add-Content -Value "$("#"*40)$(Get-Date)$("#"*40)" -Path $ErrorFile
    }
                      
                              
}
PROCESS 
{
	foreach ($computer in $computername )
	{
        #Create the WMI Hash here        
        $WMIHash = @{
            ComputerName = $Computer
            ErrorAction = 'Stop'
            Query= "SELECT LastBootUpTime FROM Win32_OperatingSystem"
            NameSpace='Root\CimV2'
        }

        #Remove Credentials if the machine is local
        if ($Computer -ne $env:COMPUTERNAME)
        {
            $WMIHash.Credential = $Credentials
        }
		Write-Verbose -Message "Checking if $Computer is online"
		if (Test-Connection -ComputerName $Computer -Count 2 -Quiet)
        {
            Write-Verbose -message "$Computer is online"
           
            try
            {
                        
                $wmi = Get-WmiObject @WMIHash
                $uptime = (Get-Date) -  $($wmi.ConvertToDateTime($wmi.LastBootUpTime))
                    $hash = [ordered]@{ComputerName="$computer";
                            Uptime=$("{0} Days {1} Hours {2} Min {3} sec" -f $uptime.days,$uptime.hours,$uptime.Minutes,$uptime.Seconds )
                            LastReboot= $($wmi.ConvertToDateTime($wmi.LastBootUpTime)) }
                $Object = New-Object -TypeName PSObject -Property $hash
                Write-Output -InputObject $Object
            }
            catch
            {
                Write-Warning -Message " $computer :: $_.exception"
                Add-Content -Value "$computer :: $_.exception" -Path $ErrorFile
            }
        }
        else
        {
            Write-Host -ForegroundColor Red "$computer is Offline " #Write-host is not adviced as you can't capture it 
            #can better log this into a file using 
            Add-Content -Value "$computer :: Offline" -Path $ErrorFile
        }
    }
}
End
{
    Write-Verbose -Message "Ending the Function"
}

}

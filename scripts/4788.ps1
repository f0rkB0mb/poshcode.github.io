function MapNetDrive 
{
    param(
    
    #Non-Boolean parameters (Values)
    #
    [Parameter(Position=0,Mandatory=$true)]
    [string]$DriveLetter="Z:",
    [Parameter(Position=1,Mandatory=$true)]
    [string]$Path,
    
    #Boolean switches (On/Off)
    #
    [Parameter(Position=2,Mandatory=$false)]
    [switch]$Credentials,
    [Parameter(Position=3,Mandatory=$false)]
    [switch]$Stay,
    [Parameter(Position=4,Mandatory=$false)]
    [switch]$Force
    )
    
    #Creates new WScript.Network object called "$map" and allows it to access MapNetworkDrive(), EnumNetworkDrives(),
    #and RemoveNetworkDrive() methods.
    #
    $map=New-Object -ComObject WScript.Network
    
    #Uses EnumNetworkDrives() and "-contains" operator to determine if specified drive already exists.  If so, and "$Force"
    #parameter is not present to force an override, it outputs a message to the user.  Then uses "Try/Catch" statement to 
    #catch any other general errors that might prevent removal of drive.
    #
    if($map.EnumNetworkDrives() -contains $DriveLetter) 
    {
        if(!$Force) 
        {throw "Can't map $driveLetter because it's already mapped.  Use -Force to override."}
        
        try 
        {$map.RemoveNetworkDrive($DriveLetter,$Force.ToBool(),$Stay.ToBool())}
            catch 
            {
            Write-Error -Exception $_.Exception.InnerException -Message "Error removing '$driveLetter'
                $($_.Exception.InnerException.InnerException.Message)"
            }
    }   
    
    #Maps new network drive, checking first if "$Credentials" parameter is passed.  If so, a System.Management.Automation.PSCredential object
    #called "$creds" is created and instantiated to result value of "Get-Credential" Cmdlet.  Because of its type, "$creds" has access to the
    #individual "UserName" and "Password" property values when the user submits them at the prompt.
    #
    #"$Stay" is placeholder for "bUpdateProfile" argument of the MapNetworkDrive() method, which determines whether the new
    #drive is saved as part of the user's profile.  It's value here is determined by the presence of the "$Stay" switch.
    #    
    if($Credentials) 
    {
       [System.Management.Automation.PSCredential]$creds=$(Get-Credential) #-Credential $($(Get-WmiObject -Class Win32_ComputerSystem).UserName)
       $map.MapNetworkDrive($DriveLetter,$Path,$Stay.ToBool(),$creds.UserName,$creds.GetNetworkCredential().Password)
    } 
        else {$map.MapNetworkDrive($DriveLetter,$Path,$Stay.ToBool())} 
       
    #Opens newly created drive letter in Windows Explorer   
    #
    $explore=New-Object -ComObject Shell.Application
    $explore.Open($DriveLetter)
}

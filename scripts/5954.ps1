#  /\    /\    /\    /\    /\    /\    /\    /\    /\    /\    /\    /\  
# /  \  /  \  /  \  /  \  /  \  /  \  /  \  /  \  /  \  /  \  /  \  /  \ 
#/    \/    \/    \/    \/    \/    \/    \/    \/    \/    \/    \/    \
#|----
#|----@Author:  Chris Rakowitz
#|----@Purpose: Returns a list of User Profiles from a Target Machine.
#|----				Pressing Enter without entering a PC Name or IP will
#|----				generate the information for the local machine.
#|----            Usage:  .\Single-GetUserList.ps1 <PCNAME or IP>
#|----@Date: April 15, 2015
#|----@Version: 1
#|----
#\    /\    /\    /\    /\    /\    /\    /\    /\    /\    /\    /\    /
# \  /  \  /  \  /  \  /  \  /  \  /  \  /  \  /  \  /  \  /  \  /  \  / 
#  \/    \/    \/    \/    \/    \/    \/    \/    \/    \/    \/    \/  

[cmdletbinding()]
param
(
	[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
	$ComputerName = $env:computername
)        
$ErrorActionPreference = 'silentlycontinue'	#Skip all the annoying Error Messages

# For each Profile on the PC, extract information
$Profiles = Get-WmiObject -Class Win32_UserProfile -Computer $ComputerName -ea 0
foreach ($Profile in $Profiles)
{
	# Skip NetworkService, LocalService and SystemProfile. No need to process.
	if($Profile.localpath -like 'C:\Windows\*') 
	{
		continue
	}
	else
	{
		$objSID = New-Object System.Security.Principal.SecurityIdentifier($Profile.sid)
		$objuser = $objSID.Translate([System.Security.Principal.NTAccount])

		$OutputObj = New-Object -TypeName PSobject
		$OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.toUpper()
		$OutputObj | Add-Member -MemberType NoteProperty -Name ProfileName -Value $objuser.value
		$OutputObj | Add-Member -MemberType NoteProperty -Name ProfilePath -Value $Profile.localpath
		
		$OutputObj
	}
}

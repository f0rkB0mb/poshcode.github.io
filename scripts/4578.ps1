<#   
.SYNOPSIS   
	Recreates shares and copies share permissions. 
.DESCRIPTION 
	Recreates shares and copies share permissions. 
.NOTES   
	Name: Copy-Shares
	Author: Sysiphus
	DateCreated: 2013:03:06
	Inspiration: http://poshcode.org/935
		http://gallery.technet.microsoft.com/scriptcenter/a231026a-3fdb-4190-9915-38d8cd827348
		http://serverfault.com/questions/9011/creating-a-share-with-permissions-with-windows-powershell
	Info: This script "copies" shares and share permissions from one computer to another. The drive
		letter can change between computers, but the path(s) on the drive may not. This script does not
		copy the data; for that you will need another solution, such as xcopy or a decent SAN that can
		do it for you. It works on OSes as old as Windows 2000, and at least as new as Server 2008 R2.
		It probably has a hundred possible improvements.
	
.EXAMPLE   
    Copy-Shares -SourceComputer Oldbox -SourceDrive E -DestComputer Newbox -DestDrive K
#>  
Param (
	[Parameter(
		Position=0,
		ValueFromRemainingArguments=$true,
		HelpMessage="Name of computer to get shares from, with no domain or slashes."
		)]
	[Alias("Old")]
	[ValidatePattern("^[^\\]")]
	[ValidateNotNullOrEmpty()]
	[String]$SourceComputer = "OldAndBusted",
	
	[Parameter(
		Position=1,
		ValueFromRemainingArguments=$true,
		HelpMessage="Source drive letter, with no colon or slash."
		)]
	[ValidatePattern('[^:]$')]
	[ValidateNotNullOrEmpty()]
	[String]$SourceDrive = "D",
	
	[Parameter(
		Position=2,
		ValueFromRemainingArguments=$true,
		HelpMessage="Name of computer to create shares on, with no domain or slashes."
		)]
	[Alias("New")]
	[ValidatePattern("^[^\\]")]
	[ValidateNotNullOrEmpty()]
	[String]$DestComputer = "NewHotness",
	
	[Parameter(
		Position=3,
		ValueFromRemainingArguments=$true,
		HelpMessage="Destination drive letter, with no colon or slash."
		)]
	[ValidatePattern('[^:]$')]
	[ValidateNotNullOrEmpty()]
	[String]$DestDrive = "F"
	)


#Format the drives to include ":\". I know there's a much better way to do it out there.
$SourceDrive = $SourceDrive + ":\"
$DestDrive =  $DestDrive + ":\"

#Some early WMI queries to establish what needs to be done
[Array]$SourceShares = Get-WmiObject -ComputerName $SourceComputer -Class Win32_Share -Filter "Type = '0'" # To eliminate all admin and non-disk shares
[Array]$SourcePerms  = Get-WmiObject -ComputerName $SourceComputer -Class Win32_LogicalShareSecuritySetting
[Array]$DestShares   = Get-WmiObject -ComputerName $DestComputer   -Class Win32_Share -Filter "Type = '0'" # see http://msdn.microsoft.com/en-us/library/windows/desktop/aa394435%28v=vs.85%29.aspx
[Array]$DestPerms    = Get-WmiObject -ComputerName $DestComputer   -Class Win32_LogicalShareSecuritySetting


#Region Limit to shares on specified source drive, warn on others
$SourceShareWrongDrive = $SourceShares | Where {$_.Path -notlike "$SourceDrive*"}
[Array]$SourceShares = $SourceShares | Where {$_.Path -like "$SourceDrive*"}
If ($SourceShareWrongDrive) {
	Write-Host -Fore Cyan -No "`nThe following shares are on a different source drive than the one you specified ($SourceDrive):"
	$SourceShareWrongDrive
	Write-Host -Fore Cyan "You will need to either do these shares manually, skip them, or re-run the script again for each additional drive.`n"	
	}
#EndRegion

#Region Limit to shares with security settings
#This little line of voodoo gets just the names of $SourceShares, and selects only those which are not in just the names of $SourcePerms
#Feel free to pick it apart and make it cleaner, I just didn't want four more free variables running amok.
#I also confess that I do these lines sometimes just to see if they really work...
[Array]$MissingPerms = $SourceShares | %{$_.Name} | %{ if (($SourcePerms | %{$_.Name}) -notcontains $_) {$_} }
If ($MissingPerms) {
	Write-Host -Fore Yellow -No "`nThe following shares do not have share permissions that can be read by a script:"
	$SourceShares | Where {$MissingPerms -contains $_.Name}
	Write-Host -Fore Yellow "These shares cannot be processed and will be skipped. To fix this, for each share" `
	"listed, manually open the Share permissions on the source computer, uncheck and recheck any box, and apply." `
	"Rerun this script and it will read the share permissions and work properly. Sadly, I'm not sure why this works.`n"
		#Update, it works because http://qa.social.technet.microsoft.com/Forums/en-US/winserverpowershell/thread/e9e9c619-ef54-4ce6-a520-202c7a3ffabc
		#and could probably be scripted around. Ah, well.
	$SourceShares = $SourceShares | Where {$MissingPerms -notcontains $_.Name}
	}
#EndRegion

#Region Don't create shares that already exist
#Like above, just go with the voodoo...
[Array]$DuplicateShares = $SourceShares | %{$_.Name} | %{if (($DestShares | %{$_.Name}) -contains $_) {$_} }
If ($DuplicateShares) {
	Write-Host -Fore Green "`nDuplicate share(s) found on source and destination computers. You need to fix these manually if this is a problem."
	ForEach ($Duplicate in $DuplicateShares) {
		Write-Host -Fore Green "           Share :" $Duplicate
		Write-Host -Fore Green "     Source path :" ($SourceShares | where {$_.Name -like $Duplicate}).Path
		Write-Host -Fore Green "Destination Path :" ($DestShares | where {$_.Name -like $Duplicate}).Path
		}
		$SourceShares = $SourceShares | where {$DuplicateShares -notcontains $_.Name}
	}
#EndRegion



#Main bit happens here
ForEach ($SourceShare in $SourceShares) {
	#Get the perms that match the share...
	$SourcePerm = $SourcePerms | Where {$_.Name -like $SourceShare.Name}
	
	#And grab its SecurityDescriptor to re-use on the destination share
	$ShareSecurity = $SourcePerm.GetSecurityDescriptor().Descriptor
	
	#Then get the share info, like the (modified) path and other stuff
	$DestPath = $SourceShare.Path -replace "$SourceDrive\", $DestDrive
		#The regex needed the extra "\" in the replacement string and that really bugs me. :-( 
	$ShareName = $SourceShare.Name
	If ($SourceShare.MaximumAllowed) {$ShareMax = $SourceShare.MaximumAllowed}
	Else {[Void]$ShareMax = $null}
	$ShareDescription = $SourceShare.Description
	
	
	
	#Then create a new share WMI object on the destination computer's runspace...
	[wmiclass]$NewShare = "\\$DestComputer\root\cimv2:win32_share"
	#And create the share there! (Oh, and snag the return value...)
	Write-Host "Attempting to create the share $ShareName..."
	$Return = $NewShare.Create($DestPath, $ShareName, 0, $ShareMax, $ShareDescription, $null, $ShareSecurity)
	#Hint about that line, it is Path, Name, Type (Disk Drive is 0), Max connections, Description,
	#	Password (null because using user-level security), and Access (a Win32_SecurityDescriptor)
	
	#Filter the return value into something readable...
    Switch ($return.returnvalue) {
        0 {$ReturnVal = "Success"}
        2 {$ReturnVal = "Access Denied"}
        8 {$ReturnVal = "Unknown Failure"}
        9 {$ReturnVal = "Invalid Name"}
        10 {$ReturnVal = "Invalid Level"}
        21 {$ReturnVal = "Invalid Parameter"}
        22 {$ReturnVal = "Duplicate Share"}
        23 {$ReturnVal = "Redirected Path"}
        24 {$ReturnVal = "Unknown Device or Directory"}
        25 {$ReturnVal = "Net Name Not Found"}
    	}
	
	If ($Return.ReturnValue -eq 0) {
		Write-Host -Fore Green "Success!"
		}
	Else {
		Write-Host -Fore Yellow "Error" $ReturnVal "creating share" $ShareName "on $DestComputer. Good luck."
		}
	
	
	}

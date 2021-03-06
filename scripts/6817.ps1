function New-ACE{
    [CmdletBinding()]
    param (
      [Parameter(Mandatory=$True)]
      [string[]]$Users,

      [Parameter(Mandatory=$True)]
      [ValidateSet('DeleteSubdirectoriesAndFiles','ReadAttributes','WriteAttributes','Write','Delete','ReadPermissions','Read',
        'ReadAndExecute','Modify','ChangePermissions','TakeOwnership','Synchronize','FullControl')]
      [string[]]$FileSystemRights,
  
      [Parameter()]
      [ValidateSet('None','ContainerInherit','ObjectInherit')]
      [string[]]$InheretenceFlags=@('ContainerInherit','ObjectInherit'),

      [Parameter()]
      [ValidateSet('None','NoPropagateInherit','InheritOnly')]
      [string]$PropogationFlag='None',

      [Parameter()]
      [ValidateSet('Allow','Deny')]
      [string]$AccessControlType='Allow'
    )
    foreach ($user in $users){
        $colRights = [System.Security.AccessControl.FileSystemRights]$FileSystemRights
        $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]$InheretenceFlags
        $PropFlag = [System.Security.AccessControl.PropagationFlags]::$PropogationFlag

        $objType =[System.Security.AccessControl.AccessControlType]::$AccessControlType
        $objUser = New-Object System.Security.Principal.NTAccount($user)
        New-Object System.Security.AccessControl.FileSystemAccessRule($objUser, $colRights, $InheritanceFlag, $PropFlag, $objType)
    }
}



$ACEArr = @()
$folder = "C:\ScriptTemp\testFolder1\subfolder"
#$testGroups = (Get-LocalGroups).tolower() | where {$_.startswith("test")}

$objACL = Get-Acl $folder
$objACL.Access | % {$objacl.purgeaccessrules($_.IdentityReference)} #Purge Inital Permissions
#$objACL.access | % {$objACL.AddAccessRule($_)} #retain current permissions

#Set user, and build an ACL for each one.

$ACEArr += New-ACE -user "L06557\TestG1","L06557\TestG2" -FileSystemRights ReadAndExecute -PropogationFlag NoPropagateInherit
$ACEArr += New-ACE -user "L06557\TestG3","L06557\TestG4" -fileSystemRights FullControl
$ACEArr += New-ACE -user 'NT AUTHORITY\SYSTEM' -fileSystemRights FullControl
$ACEArr += New-ACE -user "ADMINISTRATORS" -fileSystemRights FullControl -InheretenceFlags ObjectInherit
 
$ACEArr | foreach-object {$objACL.AddAccessRule($_)}
$objACL.SetAccessRuleProtection($true,$false)

Set-ACL $folder $objACL



#$testACL.Access


<# for propogating the validation, should the options ever change (they most likely never will)
[System.Enum]::GetNames('System.Security.AccessControl.FileSystemRights')
[System.Enum]::GetNames('System.Security.AccessControl.InheritanceFlags')
[System.Enum]::GetNames('System.Security.AccessControl.PropagationFlags')
[System.Enum]::GetNames('System.Security.AccessControl.AccessControlType')
#>

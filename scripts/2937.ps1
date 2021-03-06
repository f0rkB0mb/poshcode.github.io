$NumDays = 90
$LogDir = ".\Disabled-User-Accounts.log"

$currentDate = [System.DateTime]::Now
$currentDateUtc = $currentDate.ToUniversalTime()
$lltstamplimit = $currentDateUtc.AddDays(- $NumDays)
$lltIntLimit = $lltstampLimit.ToFileTime()
$adobjroot = [adsi]''
$objstalesearcher = New-Object System.DirectoryServices.DirectorySearcher($adobjroot)
$objstalesearcher.filter = "(&(objectCategory=person)(objectClass=user)(lastLogonTimeStamp<=" + $lltIntLimit + "))"
$users = $objstalesearcher.findall()

Write-Output `n`n"----------------------------------------" "ACCOUNTS OLDER THAN "$NumDays" DAYS" "PROCESSED ON:" $currentDate "----------------------------------------" `
| Out-File $LogDir -append

if ($users.Count -eq 0)
{
       Write-Output "  No account needs to be disabled." | Out-File $LogDir -append
}
else
{
       foreach ($user in $users)
       {
              # Read the user properties
              [string]$adsPath = $user.Properties.adspath
              [string]$displayName = $user.Properties.displayname
              [string]$samAccountName = $user.Properties.samaccountname
              [string]$lastLogonInterval = $user.Properties.lastlogontimestamp
 
              # Disable the user
              $account=[ADSI]$adsPath
              $account.psbase.invokeset("AccountDisabled", "True")
              $account.setinfo()
 
              # Convert the date and time to the local time zone
              $lastLogon = [System.DateTime]::FromFileTime($lastLogonInterval)
             
              Write-Output "  Disabled user " $displayName" | Username: "$samAccountName" | Last Logon: "$lastLogon"`n" `
			  | Out-File $LogDir -append
       }
}

###################################################################################################
#    Script Name                 -    CommArchive.ps1
#    Script Description            -    Exports Lync and mailbox data for members of security group
#    Last Modified                -    04/31/2014
#    Created By                    -    phreakin@gmail.com
#   Powershell Modules Required    -    Quest ActiveRoles AD Management, Exchange, ActiveDirectory Lync
###################################################################################################
 
###################################################################################################
# Load all required powershell modules.
###################################################################################################
 
if ((get-pssnapin | % { $_.name }) -notcontains "Quest.ActiveRoles.ADManagement")
{ Add-PSSnapin Quest.ActiveRoles.ADManagement }
 
if ((get-pssnapin | % { $_.name }) -notcontains "Microsoft.Exchange.Management.PowerShell.E2010")
{ Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 }
 
if ((get-module | % { $_.name }) -notcontains "ActiveDirectory")
{ Import-Module activedirectory }
# Lync 2013 module doesn't REQUIRE full path but I have seen issues where it could require the full path
if ((get-module | % { $_.name }) -notcontains "Lync")
{ Import-Module 'C:\Program Files\Common Files\Microsoft Lync Server 2013\Modules\Lync\Lync.psd1' }
###################################################################################################
#Script Variables
###################################################################################################
 
#Universal security group in Active Directory that contains users to be exported
$holdgroup = "ExportGroup"
 
# Worfile of detailed user information
$workfile = "workfile.csv"
 
# Name of log file to create
$logfile = "exportlog.txt"
 
# User to give mailbox permissions to for export to PST. Needs to have full access to Exchange mailbox
$MBUserPerm = "Domain\User"
 
# Amount of allowed bad items to ignore in a mailbox to PST export. Can be anywhere from 0 to 2147483647.
$BadItems = "10"
 
# Destination path to put the exported data. Can be network share or local directory
$destpath = "\\server.domain.com\Exports"
 
# Path to temporarily store PST's. Keep local to script for speed
$locpst = "D:\PST"
 
# Get's current date in 1-1-14-6-30 format
$dt = get-date -uformat "%m-%d-%Y-%H-%M"
 
# Get's current date in APR-31-2014 format
$date = Get-Date -format MMM-dd-yyyy
 
# Pulls Lync archive data 90 days back from current date
$LyncDateStart = (get-date).addDays(-90).ToString("MM/dd/yyy")
 
# End date is current date when script is ran
$LyncDateEnd = (get-date).ToString("MM/dd/yyy")
 
# SQL server hostname for Lync archive database. Does not need instance name
$LyncSQL = "ArchivingDatabase:sqlserver.domain.com"
 
#Collect user information using Quest PowerShell module from Active Directory
get-qadgroupmember $holdgroup | get-qaduser | Select-Object FirstName, LastName, SamAccountName, HomeDirectory, PrimarySMTPAddress | Export-Csv -NoTypeInformation $workfile
 
 
######################################################################################################
#Do not make changes below this line
######################################################################################################
#Create folder path if needed and copy directories
$copypath = Import-Csv $workfile
ForEach ($User in $copypath)
{
    $strA = $destpath
    $strB = $user.Firstname
    $strC = $user.LastName
    $strD = $strA + "\" + $strB + "_" + $strC
    $strE = $locpst
    $strF = $strE + "\" + $strB + "_" + $strC
    $pathcheck0 = Test-Path $strD
    $pathcheck1 = Test-Path $strF\mailbox\*
    $pathcheck2 = Test-Path $strF
    
    #######################################################################################################
    # Export Lync archived data for users
    #######################################################################################################
    
    Export-CsArchivingData -Identity "$LyncSQL" -StartDate "$lyncdateStart" -EndDate $LyncDateEnd -UserUri $User.PrimarySMTPAddress -OutputFolder "$strD\Lync_Archive\$date"
    
    
    #######################################################################################################
    # Export mailbox to PST and copt to specified shared directory. Also removes users from group once done
    #######################################################################################################
    if ($pathcheck1 -eq $True)
    {
        robocopy $strF\mailbox\ $strD\mailbox /Copy:DAT /E /XO /ZB /MT /R:2 /W:2 /V /TS /FP /LOG+:$logfile
        remove-QADGroupMember $holdgroup $User.SamAccountName
        Remove-Item -Recurse -Force $strF
    }
    else
    {
        if ($pathcheck2 -eq $true)
        {
            Write-Host "PST export pending."
        }
        else
        {
            mkdir $strF\Mailbox
            Add-MailboxPermission $User.SamAccountName -accessrights fullaccess -user $MBUserPerm -confirm:$False
            New-MailboxExportRequest -Mailbox $User.SamAccountName -Name "ExportToPST-$dt" -FilePath "$strF\mailbox\Mailbox--$Date.pst" -badItemLimit $BadItems -confirm:$False
            Remove-MailboxPermission $User.SamAccountName -accessrights fullaccess -user $MBUserPerm -confirm:$False
        }
    }
    
    Start-Sleep 120
    
    #######################################################################################################
    # Remove temporary files used by script
    #######################################################################################################
    
    del $workfile
    del $logfile

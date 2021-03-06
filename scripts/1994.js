###########################################################################"
#
# NAME: Set-OutlookSignature.ps1
#
# AUTHOR: Jan Egil Ring
#
# COMMENT: Script to create an Outlook signature based on user information from Active Directory.
#          Adjust the variables in the "Custom variables"-section
#          Create an Outlook-signature from an Outlook-client based on your company template (logo, fonts etc) and copy this signature to the path defined in the $SigSource variable
#          See the following blog-post for more information: http://blog.crayon.no/blogs/janegil/archive/2010/01/09/outlook-signature-based-on-user-information-from-active-directory.aspx
#
#          Tested on Office 2003,2007 and 2010 beta
#
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the creator, owner above has no warranty, obligations,
# or liability for such use.
#
# VERSION HISTORY:
# 1.0 09.01.2010 - Initial release
#
###########################################################################"

#Custom variables
$CompanyName = 'Company Name'
$DomainName = 'domain.local'
$SigVersion = '1.0' #When the version number are updated the local signature are re-created
$SigSource = "\\$DomainName\netlogon\sig_files\$CompanyName"
$ForceSignatureNew = '1' #When the signature are forced the signature are enforced as default signature for new messages the next time the script runs. 0 = no force, 1 = force
$ForceSignatureReplyForward = '0' #When the signature are forced the signature are enforced as default signature for reply/forward messages the next time the script runs. 0 = no force, 1 = force

#Environment variables
$AppData=(Get-Item env:appdata).value
$SigPath = '\Microsoft\Signatures'
$LocalSignaturePath = $AppData+$SigPath

#Get Active Directory information for current user
$UserName = $env:username
$Filter = "(&(objectCategory=User)(samAccountName=$UserName))"
$Searcher = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.Filter = $Filter
$ADUserPath = $Searcher.FindOne()
$ADUser = $ADUserPath.GetDirectoryEntry()
$ADDisplayName = $ADUser.DisplayName
$ADEmailAddress = $ADUser.mail
$ADTitle = $ADUser.title
$ADTelePhoneNumber = $ADUser.TelephoneNumber

#Setting registry information for the current user
$CompanyRegPath = "HKCU:\Software\"+$CompanyName

if (Test-Path $CompanyRegPath)
{}
else
{New-Item -path "HKCU:\Software" -name $CompanyName}

if (Test-Path $CompanyRegPath'\Outlook Signature Settings')
{}
else
{New-Item -path $CompanyRegPath -name "Outlook Signature Settings"}

$ForcedSignatureNew = (Get-ItemProperty $CompanyRegPath'\Outlook Signature Settings').ForcedSignatureNew
$ForcedSignatureReplyForward = (Get-ItemProperty $CompanyRegPath'\Outlook Signature Settings').ForcedSignatureReplyForward
$SignatureVersion = (Get-ItemProperty $CompanyRegPath'\Outlook Signature Settings').SignatureVersion
Set-ItemProperty $CompanyRegPath'\Outlook Signature Settings' -name SignatureSourceFiles -Value $SigSource
$SignatureSourceFiles = (Get-ItemProperty $CompanyRegPath'\Outlook Signature Settings').SignatureSourceFiles


#Forcing signature for new messages if enabled
if ($ForcedSignatureNew -eq '1')
{
#Set company signature as default for New messages
$MSWord = New-Object -com word.application
$EmailOptions = $MSWord.EmailOptions
$EmailSignature = $EmailOptions.EmailSignature
$EmailSignatureEntries = $EmailSignature.EmailSignatureEntries
$EmailSignature.NewMessageSignature=$CompanyName
$MSWord.Quit()
}

#Forcing signature for reply/forward messages if enabled
if ($ForcedSignatureReplyForward -eq '1')
{
#Set company signature as default for Reply/Forward messages
$MSWord = New-Object -com word.application
$EmailOptions = $MSWord.EmailOptions
$EmailSignature = $EmailOptions.EmailSignature
$EmailSignatureEntries = $EmailSignature.EmailSignatureEntries
$EmailSignature.ReplyMessageSignature=$CompanyName
$MSWord.Quit()
}

#Copying signature sourcefiles and creating signature if signature-version are different from local version
if ($SignatureVersion -eq $SigVersion){}
else
{
#Copy signature templates from domain to local Signature-folder
Copy-Item "$SignatureSourceFiles\*" $LocalSignaturePath -Recurse -Force

#Insert variables from Active Directory to rtf signature-file
$MSWord = New-Object -com word.application
$MSWord.Documents.Open($LocalSignaturePath+'\'+$CompanyName+'.rtf')
($MSWord.ActiveDocument.Bookmarks.Item("DisplayName")).Select()
$MSWord.Selection.Text=$ADDisplayName
($MSWord.ActiveDocument.Bookmarks.Item("Title")).Select()
$MSWord.Selection.Text=$ADTitle
($MSWord.ActiveDocument.Bookmarks.Item("TelephoneNumber")).Select()
$MSWord.Selection.Text=$ADTelePhoneNumber
($MSWord.ActiveDocument.Bookmarks.Item("EmailAddress")).Select()
$MSWord.Selection.Text=$ADEmailAddress
($MSWord.ActiveDocument).Save()
($MSWord.ActiveDocument).Close()
$MSWord.Quit()

#Insert variables from Active Directory to htm signature-file
$MSWord = New-Object -com word.application
$MSWord.Documents.Open($LocalSignaturePath+'\'+$CompanyName+'.htm')
($MSWord.ActiveDocument.Bookmarks.Item("DisplayName")).Select()
$MSWord.Selection.Text=$ADDisplayName
($MSWord.ActiveDocument.Bookmarks.Item("Title")).Select()
$MSWord.Selection.Text=$ADTitle
($MSWord.ActiveDocument.Bookmarks.Item("TelephoneNumber")).Select()
$MSWord.Selection.Text=$ADTelePhoneNumber
($MSWord.ActiveDocument.Bookmarks.Item("EmailAddress")).Select()
$MSWord.Selection.Text=$ADEmailAddress
($MSWord.ActiveDocument).Save()
($MSWord.ActiveDocument).Close()
$MSWord.Quit()


#Insert variables from Active Directory to txt signature-file
(Get-Content $LocalSignaturePath'\'$CompanyName'.txt') | Foreach-Object {$_ -replace "DisplayName", $ADDisplayName -replace "Title", $ADTitle -replace "TelePhoneNumber", $ADTelePhoneNumber -replace "EmailAddress", $ADEmailAddress} | Set-Content $LocalSignaturePath'\'$CompanyName'.txt'
}


#Stamp registry-values for Outlook Signature Settings if they doesn`t match the initial script variables. Note that these will apply after the second script run when changes are made in the "Custom variables"-section.
if ($ForcedSignatureNew -eq $ForceSignatureNew){}
else
{Set-ItemProperty $CompanyRegPath'\Outlook Signature Settings' -name ForcedSignatureNew -Value $ForceSignatureNew}

if ($ForcedSignatureReplyForward -eq $ForceSignatureReplyForward){}
else
{Set-ItemProperty $CompanyRegPath'\Outlook Signature Settings' -name ForcedSignatureReplyForward -Value $ForceSignatureReplyForward}

if ($SignatureVersion -eq $SigVersion){}
else
{Set-ItemProperty $CompanyRegPath'\Outlook Signature Settings' -name SignatureVersion -Value $SigVersion}

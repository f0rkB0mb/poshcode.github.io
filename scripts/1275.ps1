## This is the first version of a Growl module (just dot-source to use in PowerShell 1.0)
## Initially it only supports a very simple notice, and I haven't gotten callbacks working yet
## Coming soon: 
## * Send notices to other PCs directly
## * Wrap the registration of new messages
## * Figure out the stupid 

## Change these to whatever you like, at least the first one, since it should point at a real ico file
$appName = "PowerGrowler"

[Reflection.Assembly]::LoadFrom("$(Split-Path (gp HKCU:\Software\Growl).'(default)')\Growl.Connector.dll") | Out-Null

if(!(Test-Path Variable:Global:PowerGrowlerNotices)) {
   $global:PowerGrowlerNotices = @{}
}

## We can safely recreate these, they don't do much
[Growl.Connector.Application]$script:GrowlApp = $appName
$script:GrowlApp.Icon = Convert-Path (Resolve-Path "$PSScriptRoot\default.ico")
$script:PowerGrowler = New-Object "Growl.Connector.GrowlConnector"


function Set-GrowlPassword { 
#.Synopsis
#  Set the Growl password
#.Description
#  Set the password and optionally, the encryption algorithm, for communicating with Growl
#.Parameter Password
#  The password for Growl
#.Parameter Encryption
#  The algorithm to be used for encryption (defaults to AES)
#.Parameter KeyHash
#  The algorithm to be used for key hashing (defaults to SHA1)
PARAM( 
   [Parameter(Mandatory=$true,Position=0)]
   [String]$Password
,
   [Parameter(Mandatory=$false,Position=1)]
   [ValidateSet( "AES", "DES", "RC2", "TripleDES", "PlainText" )]
   [String]$Encryption = "AES"
,   
   [Parameter(Mandatory=$false,Position=2)]
   [ValidateSet( "MD5", "SHA1", "SHA256", "SHA384", "SHA512" )]
   [String]$KeyHash = "SHA1"
)   
   $script:PowerGrowler.EncryptionAlgorithm = [Growl.Connector.Cryptography+SymmetricAlgorithmType]::"$Encryption"
   $script:PowerGrowler.KeyHashAlgorithm = [Growl.Connector.Cryptography+SymmetricAlgorithmType]::"$KeyHash"
   $script:PowerGrowler.Password = $Password
}

function Register-GrowlType {
#.Synopsis
#  Register a new Type name for growl notices from PowerGrowl
#.Description
#  Creates a new type name that can be used for sending growl notices
#.Parameter Name
#  The type name to be used sending growls
#.Parameter DisplayName
#  The test to use for display (defaults to use the same value as the type name)
#.Parameter Icon
#  Overrides the default icon of the message (accepts .ico, .png, .bmp, .jpg, .gif etc)
#.Parameter MachineName
#  The name of a remote machine to register remotely instead of locally.
#.Parameter Priority
#  Overrides the default priority of the message (use sparingly)
#.Example
#  Register-GrowlType "Command Completed"
#  
#  Registers the type "Command Completed," using the default icon, for sending notifications to the local PC
#
PARAM(
   [Parameter(Mandatory=$true,Position=0)]
   [ValidateScript( {!$global:PowerGrowlerNotices.ContainsKey($_)} )]
   [String]$Name
,
   [Parameter(Mandatory=$false,Position=1)]
   [String]$Icon
,
   [Parameter(Mandatory=$false,Position=2)]
   [String]$DisplayName = $NoticeName
,
   [Parameter(Mandatory=$false,Position=3)]
   [String]$MachineName
)
  
   [Growl.Connector.NotificationType]$Notice = $Name
   $Notice.DisplayName = $DisplayName
   if($Icon) {
      $Notice.Icon = Convert-Path (Resolve-Path $Icon)$Icon
   }
   if($MachineName) {
      $Notice.MachineName = $MachineName
   }
   
   $global:PowerGrowlerNotices.Add( $Name, $Notice )
   $script:PowerGrowler.Register( $script:GrowlApp, @($global:PowerGrowlerNotices.Values) )
}



## Register the "Default" notice type, just so everything works out of the box
Register-GrowlType "Default"

function Register-GrowlCallback {
#.Synopsis
#  Register a script to be called when each notice is finished. 
#.Description
#  Registers a scriptblock as a handler for the NotificationCallback event. You should accept two parameters, a Growl.Connector.Response and a Growl.Connector.CallbackData object.
#  
#  The NotificationCallback only happens when a callback is requested, which in this Growl library only happens if you pass both CallbackData and CallbackType to the Send-Growl function.
#.Example
#  Register-GrowlCallback { PARAM( $response, $context )
#    Write-Host "Response $($response|out-string)" -fore Cyan
#    Write-Host "Context $($context|gm|out-string)" -fore Green
#    Write-Host $("Response Type: {0}`nNotification ID: {1}`nCallback Data: {2}`nCallback Data Type: {3}`n" -f $context.Result, $context.NotificationID, $context.Data, $context.Type) -fore Yellow
#  }
#
#  Registers an informational debugging-style handler. 
#
PARAM(
[Parameter(Mandatory=$true)]
[Scriptblock]$Handler
)
   Register-ObjectEvent $script:PowerGrowler NotificationCallback -Action $Handler
}

function Send-Growl {
#.Synopsis
#  Send a growl notice
#.Description
#  Send a growl notice with the scpecified values
#.Parameter Caption
#  The short caption to display
#.Parameter Message
#  The message to send (most displays will resize to accomodate)
#.Parameter NoticeType
#  The type of notice to send. This MUST be the name of one of the registered types, and senders should bear in mind that each registered type has user-specified settings, so you should not abuse the types, but create your own for messages that will recur.
#  For example, the user settings allow certain messages to be disabled, set to a different "Display", or to have their Duration and Stickyness changed, as well as have them be Forwarded to another device, have Sounds play, and set different priorities.
#.Parameter Icon
#  Overrides the default icon of the message (accepts .ico, .png, .bmp, .jpg, .gif etc)
#.Parameter Priority
#  Overrides the default priority of the message (use sparingly)
#.Example
#  Send-Growl "Greetings" "Hello World!"
#
#  The Hello World of Growl.
#.Example
#  Send-Growl "You've got Mail!" "Message for you sir!" -icon ~\Icons\mail.png
#
#  Displays a message with a couple of movie quotes and a mail icon.
#
PARAM (
   [Parameter(Mandatory=$true, Position=0)]
   [string]$Caption
,
   [Parameter(Mandatory=$true, Position=1)]
   [string]$Message
,  
   [Parameter(Mandatory=$false, Position=2)]
   [string]$CallbackData
,  
   [Parameter(Mandatory=$false, Position=3)]
   [string]$CallbackType
,
   [Parameter(Mandatory=$false)][Alias("Type")]   
   [ValidateScript( {$global:PowerGrowlerNotices.ContainsKey($_)} )]
   [string]$NoticeType="Default"
,
   [string]$Icon
,
   [Growl.Connector.Priority]$Priority = "Normal" 
)

   $notice = New-Object Growl.Connector.Notification $appName, $NoticeType, (Get-Date).Ticks.ToString(), $caption, $Message
   
   if($Icon) { $notice.Icon = Convert-Path (Resolve-Path $Icon) }
   if($Priority) { $notice.Priority = $Priority }
   
   if($DebugPreference -gt "SilentlyContinue") { Write-Output $notice }
   if( $CallbackData -and $CallbackType ) {
      $context = new-object Growl.Connector.CallbackContext
      $context.Data = $CallbackData
      $context.Type = $CallbackType
      $script:PowerGrowler.Notify($notice, $context)
   } else {
      $script:PowerGrowler.Notify($notice)
   }
}

Export-ModuleMember -Function Send-Growl, Set-GrowlPassword, Register-GrowlCallback, Register-GrowlType


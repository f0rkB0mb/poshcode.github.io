## Send-SmtpMessage -- a special implementation to show how to send via GMail
## GMail is a bit more complicated than most....
###################################################################################################
## Examples:
## Send-SmtpMessage "receiver@gmail.com" "Hello there" "This is an important email"
##       sends a message after prompting you for your login credentials... 
##       notice this will use your login as the FROM email (gmail will force that anyway)
## 
## Send-SmtpMessage "receiver@gmail.com" "Hello there" "This is an important email" `
##   $(New-Object Net.NetworkCredential "Username","Password") `
##   "Sender@Server.com" "smtp.Server.com" $null
##       sends a message without prompting, and specifies the sender and server address...
###################################################################################################
## Revision History
## 1.2 - Works for gmail now
## 1.0 - Works for me
###################################################################################################
param (
   [Net.Mail.MailAddress]$to = $(Read-Host "Email address to send to (eg: receiver@hotmail.com)")
  ,[string]$Subject = $(Read-Host "Email Subject")
  ,[string]$Body = $(Read-Host "Main Email Body")
  ## Note your login name for gmail is: user@gmail.com
  ,[Net.NetworkCredential]$credentials = $(Get-Credential)

  ,[Net.Mail.MailAddress]$from = $null
  ,[string]$Server="smtp.gmail.com"  # Change this to your server address
  ,[int]$Port=587                    # Does anyone other than gmail use this port?
)
## Fix up the credentials for Gmail
## (gmail requires user@gmail.com in the username, and NOTHING in the domain)
$credentials.UserName += "@" + $credentials.Domain
$credentials.Domain = ""

if(!$from) { 
  $from = $credentials.UserName
}

## Most (not gmail) servers will not need to specify a port
if($Port) {
   $mail = new-object Net.Mail.SmtpClient $Server,$Port
} else {
   $mail = new-object Net.Mail.SmtpClient $Server
}

$mail.Credentials = $credentials
## Gmail _requires_ Ssl -- most others seem to have it as an option, nowadays
$mail.EnableSsl = $true

## And finally ....
$mail.Send($From,$To,$Subject,$Body)

#Connection Strings
$Database = "Database"
$Server = "SQLServer"
#SMTP Relay Server
$SMTPServer = "smtp.domain.com"
#Export File
$AttachmentPath = "C:\SQLData.csv"
# Connect to SQL and query data, extract data to SQL Adapter
$SqlQuery = "SELECT * FROM dbo.Test_Table"
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Data Source=$Server;Initial Catalog=$Database;Integrated Security = True"
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = $SqlQuery
$SqlCmd.Connection = $SqlConnection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$nRecs = $SqlAdapter.Fill($DataSet)
$nRecs | Out-Null
#Populate Hash Table
$objTable = $DataSet.Tables[0]
#Export Hash Table to CSV File
$objTable | Export-CSV $AttachmentPath
#Send SMTP Message
$Mailer = new-object Net.Mail.SMTPclient($SMTPServer)
$From = "email1@domain.com"
$To = "email2@domain.com"
$Subject = "Test Subject"
$Body = "Body Test"
$Msg = new-object Net.Mail.MailMessage($From,$To,$Subject,$Body)
$Msg.IsBodyHTML = $False
$Attachment = new-object Net.Mail.Attachment($AttachmentPath)
$Msg.attachments.add($Attachment)
$Mailer.send($Msg)

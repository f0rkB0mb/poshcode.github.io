#############################################################################
#
# Title : Get O365 users with admin rights
# Version : 1.0
# Creator : Julien LABALME
# Input : $office365Account and $Office365Password
#
#############################################################################

##################################VARIABLES##################################

$Date=get-date
$Date = $Date.Year.tostring() + "-" + $Date.Month.tostring() + "-" + $Date.Day.tostring() + "_" + $Date.Hour.tostring() + "-" + $Date.Minute.tostring()
$LogFilePath = "$env:USERPROFILE\Desktop\O365UsersWithAdminRights - $Date.csv"
$ExcelLogFilePath = "$env:USERPROFILE\Desktop\O365UsersWithAdminRights - $Date.xlsx"

$Office365Account = ""
$Office365Password = ""

##################################FUNCTIONS##################################
#Write in Log
function writelog ([string]$text, [int] $color=0)
{
	Write-Output  $text | Out-File -Append -FilePath $LogFilePath -Encoding "UTF8"
	if ($color -eq 0) {write-host $text}
	if ($color -eq 1) {write-host $text -foregroundcolor green}
	if ($color -eq 2) {write-host $text -foregroundcolor yellow}
	if ($color -eq 3) {write-host $text -foregroundcolor red}
	if ($color -eq 4) {write-host $text -foregroundcolor cyan}
}	

#Function to connect to Office 365
Function ConnectOffice365
{
	$Connected = $false
	#if($Script:Onlinecred = $host.ui.PromptForCredential("Enter Office 365 Credentials ","Enter Office 365 Credentials","",""))
	#{
		try
		{
			$secstr = New-Object -TypeName System.Security.SecureString -ea stop
			$Office365Password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)} -ea stop
			$Onlinecred = new-object -typename System.Management.Automation.PSCredential -argumentlist $Office365Account, $secstr -ea Stop
			Import-Module MSOnline
			Connect-MsolService -Credential $Onlinecred
			#Writelog "INFO,N/A,ConnectOffice365,Connected to Office365" 1
			$Connected = $true
		}
		catch{writelog "ERROR,N/A,ConnectOffice365,$($ERROR[0])" 3}
	#}
	return $Connected
}

#Convert csv to xlsx file
Function Convert-CSVToExcel
{
	[CmdletBinding()]
	Param
	(
		[Parameter(ValueFromPipeline=$True, Position=0, Mandatory=$True, HelpMessage="Name of CSV/s to import")]
		[ValidateNotNullOrEmpty()]
		[string]$Inputfile,

		[Parameter(ValueFromPipeline=$False, Position=1, Mandatory=$True, HelpMessage="Name of excel file output")]
		[ValidateNotNullOrEmpty()]
		[string]$Outputfile
	)

    Begin
	{
        If (!(Test-Path -Path $Inputfile))
        {
	        write-host "CSV file not found:  {0}"
	        Exit
        } 
		
        #Create Excel Com Object
        $Excel = new-object -com excel.application
        # Excel options
        $Excel.DisplayAlerts = $False 
        $Excel.ScreenUpdating = $False 
        $Excel.Visible = $False 
        $Excel.UserControl = $False 
        $Excel.Interactive = $False
        #Add workbook
        $workbook = $Excel.workbooks.Add()
    }

    Process
	{
        #Use the first worksheet in the workbook (also the newest created worksheet is always 1)
        $worksheet = $workbook.worksheets.Item(1)
        #Add name of CSV as worksheet name
        #$worksheet.name = "$((GCI $input).basename)"
        #Open the CSV file in Excel
        $tempcsv = $Excel.Workbooks.Open($Inputfile) 
        # Select the first sheet
        $tempsheet = $tempcsv.Worksheets.Item(1)
        #Copy contents of the CSV file
        $tempSheet.UsedRange.Copy() | Out-Null
        #Paste contents of CSV into existing workbook
        $worksheet.Paste()
        #Close temp workbook
        $tempcsv.close()

        # Rename the 1st sheet
        $worksheet.Name = 'O365 Admin Rights';
        # format sheet policy
        $range = $worksheet.Range("A1:C1");
        $range.Interior.ColorIndex = 43;
        $range.Font.ColorIndex = 1;
        $range.Font.Bold = $True;
        $range = $worksheet.UsedRange;
		$range.EntireColumn.AutoFit() | out-null
		$range.Cells.EntireColumn.AutoFilter();
    }        
	
    End
	{
        #Save spreadsheet
        $workbook.saveas("$Outputfile")
        # Wait 2 seconds
        $Null = Start-sleep -Seconds 2
		$OutputFile = $OutputFile.Substring(($OutputFile.LastIndexOf("\")+1),($OutputFile.Length-$OutputFile.LastIndexOf("\")-1))
		write-host "CSV file $OutputFile successfully converted to XLSX"
		
		#Quit Excel
        $Excel.Quit()
		
		#Release processes for Excel
		while( [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel)){}
		Remove-Variable Excel
    }
}

###################MAIN########################

# Launch connection to O365
if (ConnectOffice365)
{
	writelog "ROLE;DISPLAYNAME;EMAILADDRESS"

	# Get O365 roles list
	$roles = Get-MsolRole | select ObjectId,Name
	
	Foreach ($role in $roles)
	{
		# For each roles get members
		$roleMembers = Get-MSOLRoleMember -RoleObjectId $role.ObjectId | select EmailAddress,DisplayName
		
		Foreach ($roleMember in $roleMembers)
		{
			writelog "$($role.Name);$($roleMember.DisplayName);$($roleMember.EmailAddress)"
		}
	}
}
	
#Convert CSV to xlsx file
$Null = Convert-CSVToExcel -Inputfile $LogFilePath -Outputfile $ExcelLogFilePath

#Clean temp csv file
Remove-Item -Path $LogFilePath -Force -Confirm:$False

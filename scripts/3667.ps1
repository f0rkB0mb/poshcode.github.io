# Get User/Pass
$Cred = Get-Credential
# Add Quest CMDLETS
Add-PSSnapin Quest.ActiveRoles.ADManagement -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
# Get Computer's from AD
$Computers = Get-QADComputer -SearchRoot "OU=Workstations,DC=Domain,DC=com" -Credential $Cred
# Import BITS for the file transfers
Import-Module BitsTransfer

# Let's Copy the files!
Function Deploy {
Clear-Host
	$Computers | ForEach-Object {
	# Format Computer Name
	$Computer = $_.name
	$FileToCopy = "C:\Users\Public\File.Here"
	# Check to see if the computer is online
	$Online = Test-Connection -Quiet -ComputerName $Computer
	IF ($Online -eq $true) {
		# If Online discover if system is 32 or 64 bit
		$WMI = Get-WmiObject -Credential $Cred -Class Win32_OperatingSystem -ComputerName $Computer
		$OSArch = $WMI.OSArchitecture
		IF ($OSArch -eq '64-bit') {
      		# 64 bit systems
			Start-BitsTransfer -Source $FileToCopy -Credential $cred -Description "$Computer - Patch" -Destination "\\$Computer\C$\Program Files (x86)\APPFOLDER\SubFolder\File.Here"
			}
		ELSE {
			# 32 bit systems
			Start-BitsTransfer -Source $FileToCopy -Credential $cred -Description "$Computer - Patch" -Destination "\\$Computer\C$\Program Files\APPFOLDER\SubFolder\File.Here"
			}
		}
	}
}

<# For finding MD5 hash of files
Taken from: author:fuhj(powershell@live.cn ,http://txj.shell.tor.hu)
In hind sight I guess I could have used get-sha1 from powershell powerpack.
#>
function Get-MD5 ([System.IO.FileInfo] $file = $(throw 'Usage: Get-MD5 [System.IO.FileInfo]')) { 
	$stream = $null; 
	$cryptoServiceProvider = [System.Security.Cryptography.MD5CryptoServiceProvider]; 
	$hashAlgorithm = new-object $cryptoServiceProvider 
	$stream = $file.OpenRead(); 
	$hashByteArray = $hashAlgorithm.ComputeHash($stream); 
	$stream.Close(); 
	# We have to be sure that we close the file stream if any exceptions are thrown. 
	trap {if ($stream -ne $null) {$stream.Close();} 
    break;} 
	return [string]$hashByteArray; 
} 

# Let's check the versions!
# This is called in the logging function
Function GetFileInfo {
	# Check's to see if the system is online
	$Online = Test-Connection -Quiet -ComputerName $Computer
	IF ($Online -eq $true) {
		# If Online discover if system is 32 or 64 bit
		$WMI = Get-WmiObject -Credential $Cred -Class Win32_OperatingSystem -ComputerName $Computer
		$OSArch = $WMI.OSArchitecture
		IF ($OSArch -eq '64-bit') {
      		# 64 bit systems
			$File = "\\$Computer\C$\Program Files (x86)\APPHERE\SubFolder\File.here"
			IF ((Test-Path $file) -eq $true) {
				$MD5 = Get-MD5 $File
				IF ($MD5 -eq "71 138 251 146 147 253 178 99 136 67 73 107 206 247 60 235"){
					$c.Cells.Item($intRow,2)  = "PATCHED"}
				ELSE {$c.Cells.Item($intRow,2)  = "NOT PATCHED"}
				}
			ELSE {$c.Cells.Item($intRow,2)  = "FILE MISSING OR ACCESS DENIED"}
			}
		ELSE {
			# 32 bit systems
			$File = "\\$Computer\C$\Program Files\APPHERE\SubFolder\File.here"
			IF ((Test-Path $file) -eq $true) {
				$MD5 = Get-MD5 $File
				IF ($MD5 -eq "71 138 251 146 147 253 178 99 136 67 73 107 206 247 60 235"){
					$c.Cells.Item($intRow,2)  = "PATCHED"}
				ELSE {$c.Cells.Item($intRow,2)  = "NOT PATCHED"}
				}
			ELSE {$c.Cells.Item($intRow,2)  = "FILE MISSING OR ACCESS DENIED"}
			}	
		}
	# If Offline mark as such
	ELSE {$c.Cells.Item($intRow,2)  = "OFFLINE"}
}

# Let's log this with... EXCEL!
Function LogIT {
	# Generate Excel Document
	$a = New-Object -comobject Excel.Application
	# Let's the document be seen otherwise it would run the the background
	$a.visible = $True
	# Adds the workbook
	$b = $a.Workbooks.Add()
	# Sets up the Sheet
	$c = $b.Worksheets.Item(1)
	# Make the Headers
	$c.Cells.Item(1,1) = "Machine Name"
	$c.Cells.Item(1,2) = "Version"
	$c.Cells.Item(1,3) = "Report Time Stamp"
	# Set Font & Color
	$d = $c.UsedRange
	$d.Interior.ColorIndex = 19
	$d.Font.ColorIndex = 11
	# I like my headers to be bold. 
	$d.Font.Bold = $True
	# Starts writing in the next row
	$intRow = 2
	# Get the data
	$Computers | ForEach-Object {
		# Format the computer Name
		$Computer = $_.name
		# Input the computer name
		$c.Cells.Item($intRow,1)  = $Computer
 		# Get the file info
		GetFileInfo
		# Put's in the date
		$c.Cells.Item($intRow,3) = Get-date
		# Got to the next row
		$intRow = $intRow + 1
		}
	# Formats the data
	$d.EntireColumn.AutoFit()
}

# Oh Crap, bad things are happening! Need to backout of this NOW!
Function DangerWillRobinson {
	$Computers | ForEach-Object {
	# Format Computer Name
	$Computer = $_.name
	# Check to see if the computer is online
	$Online = Test-Connection -Quiet -ComputerName $Computer
	IF ($Online -eq $true) {
		# If Online discover if system is 32 or 64 bit
		$WMI = Get-WmiObject -Credential $Cred -Class Win32_OperatingSystem -ComputerName $Computer
		$OSArch = $WMI.OSArchitecture
		IF ($OSArch -eq '64-bit') {
      		# 64 bit systems
			$FILE = Get-WMIObject -computer $Computer -Credential $Cred -query "Select * From CIM_DataFile Where Name ='C:\\Program Files (x86)\\YOUAPP\\APPSSUBFOLDER\\FILE.HERE'"
			$FILE.Delete()
			}
		ELSE {
			# 32 bit systems
			$FILE = Get-WMIObject -computer $Computer -Credential $Cred -query "Select * From CIM_DataFile Where Name ='C:\\Program Files\\YOUAPP\\APPSSUBFOLDER\\FILE.HERE'"
			$FILE.Delete()
			}
		}
	}
}

Deploy
LogIT

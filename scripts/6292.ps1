#Get the OEM product key from WMI
$ProductKey = $(wmic path softwarelicensingservice get OA3xOriginalProductKey)[2]
#Get the Operating System SKU (Edition) from WMI
$OSSKU = (Get-WMIObject Win32_OperatingSystem).OperatingSystemSKU

IF ($ProductKey -like "*error*") {
<# Keys used in this section are generic keys for installation. None of these
keys can be activated. 

Reference: http://pastebin.com/SyeWcnKq
Reference: https://technet.microsoft.com/en-us/library/jj612867.aspx 

These keys are used if Line 2 returns an error. #>

	# Version: Windows 8.1 Core
	IF ($OSSKU -eq 101) {
		cscript C:\Windows\System32\slmgr.vbs -ipk 334NH-RXG76-64THK-C7CKG-D3VPT
		EXIT }

	# Version: Windows 8.1 Core Single Language
	ELSEIF ($OSSKU -eq 100) {
		cscript C:\Windows\System32\slmgr.vbs -ipk Y9NXP-XT8MV-PT9TG-97CT3-9D6TC
		EXIT }

	# Version: Windows 8.1 Professional
	ELSEIF ($OSSKU -eq 48) {
		cscript C:\Windows\System32\slmgr.vbs -ipk GCRJD-8NW9H-F2CDX-CCM8D-9D6T9
		EXIT }

	# Version: Windows 8.1 Professional with Windows Media Center
	ELSEIF ($OSSKU -eq 103) {
		cscript C:\Windows\System32\slmgr.vbs -ipk GBFNG-2X3TC-8R27F-RMKYB-JK7QT
		EXIT }

	# Version: Windows 8.1 Enterprise
	ELSEIF ($OSSKU -eq 4) {
		cscript C:\Windows\System32\slmgr.vbs -ipk FHQNR-XYXYC-8PMHT-TV4PH-DRQ3H
		EXIT }

	# Version: Other or Not Defined
	ELSE {
		ECHO "The edition of the operating system either does not match a defined edition in the script, or is not defined in WMI. The script will end."
		EXIT }
	}

ELSE {
<# This block will apply the OEM product key from the MSDM table of ACPI and activate it. #>

	cscript C:\Windows\System32\slmgr.vbs -ipk $ProductKey
	cscript C:\Windows\System32\slmgr.vbs -ato
	EXIT }

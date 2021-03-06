# The script is using a csv file in the following format
#
#	Domain,GPOName,PrinterName,PrinterPath,Order,GroupName
#	domain.local,TestGP,TestPrinter1,\\server1\printer1,1,group1
#	domain.local,TestGP,TestPrinter2,\\server1\printer2,2,group2
#	domain.local,TestGP,TestPrinter3,\\server1\printer3,3,group3
#
# Importing the SDM module into Powershell

Import-Module SDM-GroupPolicy

# Read the csv file

$PrinterList=Import-CSV C:\scripts\printers.csv

foreach ($entry in $PrinterList)
{

#Set the variables

$Domain=$entry.Domain
$GPOName=$entry.GPOName
$PrinterName=$entry.PrinterName
$PrinterPath=$entry.PrinterPath
$Order=$entry.Order
$GroupName=$entry.GroupName

# Opening the Group Policy object

$gpo = Get-SDMgpobject -gpoName "gpo://$Domain/$GPONAME" -openByName

# Open the Printer hive within the GP

$container = $gpo.GetObject("User Configuration/Preferences/Control Panel Settings/Printers/Shared Printer")

# Creating the printers

$printer = $container.Settings.AddNew("$PrinterName")

$printer.Put("Action",[GPOSDK.EAction]"Create")

$printer.Put("Share path","$PrinterPath")

# Setup the order of the printers

$printer.Put("Order",$Order)

# If you don't want to use item-level Targeting you use the following command
# $printer.Save()

# Ignore this part if you don't want item-level targeting
# Creating the Item-Level targeting

$iilt = $gpo.CreateILTargetingList()

$itm = $iilt.CreateIILTargeting([GPOSDK.Providers.ILTargetingType]"FilterGroup")

# Set the group for filtering, the printer setting will apply to this group

$itm.Put("Group","$GroupName")

$itm.Put("UserInGroup", $true)

$iilt.Add($itm)

# Saving the filter

$printer.put("Item-level targeting", $iilt)

# Save the GP

$printer.Save()
}

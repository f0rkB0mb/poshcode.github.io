<#=====================================================
SYNOPSIS
Create an Excel workbook for a teacher.
The workbook contains a worksheet for each class.
=====================================================#>

<#=====================================================
RETRIEVE CURRENT USER'S LOGON
Prefer API to $env:username.
http://www.leeholmes.com/blog/2009/...lkthrough/
http://www.pinvoke.net/
LOCAL:
    $signature
    $type
IN:
OUT:
    $logon
=====================================================#>
$signature = @' 
[DllImport("mpr.dll", CharSet=CharSet.Auto, SetLastError=true)]
    public static extern int WNetGetUser(
            [MarshalAs(UnmanagedType.LPTStr)] string lpName, 
            [MarshalAs(UnmanagedType.LPTStr)] StringBuilder lpUserName, 
            ref int lpnLength); 
'@
$type = Add-Type -MemberDefinition $signature -Name GetLogonString -Namespace WNetGetUser -Using System.Text -PassThru   
$logon = New-Object System.Text.StringBuilder 32 # Current user's logon is returned as a null-terminated string in this buffer.

$type::WNetGetUser("", $logon, [ref]$logon.Capacity)

<#=====================================================
RETRIEVE CURRENT USER'S SFKEY
The SFKey is the database UID - four chars.
Test current user's logon first.
If OK, open a .NET connection and get the SFKey that matches the logon.
Allows identity impersonation.
LOCAL:
    $cmdSFKey
IN:
    $logon
OUT:
    $cnnNET
    $sfkey 
=====================================================#>
Switch($logon.Length) {
    0 {throw "Error retrieving Windows logon."}
    default { 
        $cnnNET = New-Object System.Data.SqlClient.SqlConnection
        $cnnNET.ConnectionString = "Server=HOMEPC\SQLEXPRESS;Database=Keeper;Integrated Security=SSPI"
        $cnnNET.Open()

        $cmdSFKey = New-Object System.Data.SqlClient.SqlCommand
        $cmdSFKey.Connection = $cnnNET
        $cmdSFKey.CommandType = [System.Data.CommandType]"StoredProcedure"
        $cmdSFKey.CommandText = "SELMainSFKey"

        $cmdSFKey.Parameters.Add("@LogonName",[System.Data.SqlDbType]"varchar",30)
        $cmdSFKey.Parameters["@LogonName"].Value = $logon.ToString()

        $cmdSFKey.Parameters.Add("@SFKey",[System.Data.SqlDbType]"varchar",4)
        $cmdSFKey.Parameters["@SFKey"].Direction = [System.Data.ParameterDirection]"Output" 

        $cmdSFKey.ExecuteNonQuery()

        [string] $sfkey = $cmdSFKey.Parameters["@SFKey"].Value
        
<#=====================================================
RETRIEVE TIMETABLE PERIOD AND WORKBOOK SAVE LOCATION
Test current user's SFKey first.
If OK, retrieve two values from single-row lookup table:
    1. $ttperiod is reqd to look up teacher's classes.
    2. $xlpath is required to save the Excel workbook.
Nested switch statements end in this block.
LOCAL:
    $cmdAdmin
    $adpAdmin
    $tblAdmin
    $rowAdmin
IN:
    $sfkey
    $cnnNET
OUT:
    $ttperiod
    $xlpath
=====================================================#>
        Switch($sfkey.Length) {
            0 {throw "Error retrieving teacher key."}
            default {
                $cmdAdmin = New-Object System.Data.SqlClient.SqlCommand
                $cmdAdmin.Connection = $cnnNET
                $cmdAdmin.CommandType = [System.Data.CommandType]"StoredProcedure"
                $cmdAdmin.CommandText = "SELMainAdmin"

                $adpAdmin = New-Object System.Data.SqlClient.SqlDataAdapter
                $adpAdmin.SelectCommand = $cmdAdmin
    
                $tblAdmin = New-Object System.Data.DataTable
                $adpAdmin.Fill($tblAdmin)
                $rowAdmin = $tblAdmin.Rows

                foreach ($rowAdmin in $tblAdmin) {
                    [string] $ttperiod = $rowAdmin.Item("CurrentTTPeriod")
                    [string] $xlpath = $rowAdmin.Item("KeeperPath")
                } # End foreach 
                                        
            } # End Switch $sfkey default    
        } # End Switch $sfkey.length
    } # End Switch $logon default
} # End Switch $logon.length

<#=====================================================
RETRIEVE CURRENT USER'S CLASSES
Test Admin values first.
If OK, retrieve teacher's classes into a DataTable.
A "class" has two pieces:
    1. subject key (e.g., 08ENG1).
    2. class number (e.g., 6).
LOCAL:
    $test
    $cmdClasses
    $adpClasses
IN:
    $ttperiod
    $xlpath    
    $cnnNET
    $sfkey
OUT:
    $rowClasses
    $tblClasses
=====================================================#>
[int] $test = 0
$test = $ttperiod.Length
if ($test = 0) {throw "Error retrieving timetable period."}
$test = $xlpath.Length
if ($test = 0) {throw "Error retrieving XL pathname."}

$cmdClasses = New-Object System.Data.SqlClient.SqlCommand
$cmdClasses.Connection = $cnnNET
$cmdClasses.CommandType = [System.Data.CommandType]"StoredProcedure"
$cmdClasses.CommandText = "SELKeeperClassesForTeacher"

$cmdClasses.Parameters.Add("@ttperiod",[System.Data.SqlDbType]"varchar",6)
$cmdClasses.Parameters["@ttperiod"].Value = $ttperiod

$cmdClasses.Parameters.Add("@SFKey",[System.Data.SqlDbType]"varchar",4)
$cmdClasses.Parameters["@SFKey"].Value = $sfkey

$adpClasses = New-Object System.Data.SqlClient.SqlDataAdapter
$adpClasses.SelectCommand = $cmdClasses

$tblClasses = New-Object System.Data.DataTable
$adpClasses.Fill($tblClasses)
$rowClasses = $tblClasses.Rows

<#=====================================================
CREATE EXCEL OBJECTS
Application and workbook.
Create workbook with a worksheet for each class.
LOCAL:
    $xl
IN:
    $tblClasses
OUT:
    $wb
=====================================================#>
$xl = New-Object -ComObject Excel.Application
$xl.SheetsInNewWorkbook = $tblClasses.Rows.Count
$wb = $xl.Workbooks.Add()
$xl.Visible = $True

<#=====================================================
CREATE ADODB OBJECTS
An ADODB recordset is reqd by Excel's CopyFromRecordset.
LOCAL:
    $ad [int] constants
    $cnnADO
    $prmTTPeriod
IN:
    $ttperiod
OUT:
    $prmSUKey
    $prmClass
    $cmdStudents
    $rstStudents
=====================================================#>
[int] $adCmdStoredProc = 4

[int] $adVarChar = 200
[int] $adSmallInt = 2
[int] $adParamInput = 1

[int] $adOpenForwardOnly = 0 # Default.
[int] $adOpenStatic = 3

[int] $adLockReadOnly = 1 # Default.
[int] $adLockOptimistic = 3

[int] $adUseServer = 2 # Default.
[int] $adUseClient = 3

$cnnADO = New-Object -ComObject ADODB.Connection
$cnnADO.Open("Provider=SQLOLEDB; Data Source=HOMEPC\SQLEXPRESS; Initial Catalog=Keeper; Integrated Security=SSPI")

$cmdStudents = New-Object -ComObject ADODB.Command
$cmdStudents.ActiveConnection = $cnnADO
$cmdStudents.CommandType = $adCmdStoredProc
$cmdStudents.CommandText = "SELKeeperStudentsForClass"

$prmTTPeriod = New-Object -ComObject ADODB.Parameter
$prmTTPeriod = $cmdStudents.CreateParameter("@ttperiod",$adVarChar,$adParamInput,6,$ttperiod) # This parameter doesn't change; assign value here.
$cmdStudents.Parameters.Append($prmTTPeriod)

$prmSUKey = New-Object -ComObject ADODB.Parameter
$prmSUKey = $cmdStudents.CreateParameter("@SUKey",$adVarChar,$adParamInput,7) # This parameter changes; assign value in ForEach.
$cmdStudents.Parameters.Append($prmSUKey)

$prmClass = New-Object -ComObject ADODB.Parameter
$prmClass = $cmdStudents.CreateParameter("@class",$adSmallInt,$adParamInput) # This parameter changes; assign value in ForEach.
$cmdStudents.Parameters.Append($prmClass)

$rstStudents = New-Object -ComObject ADODB.Recordset
$rstStudents.CursorLocation = $adUseServer
$rstStudents.CursorType = $adOpenForwardOnly
$rstStudents.LockType = $adLockReadOnly

<#=====================================================
RETRIEVE STUDENTS
Place students in separate worksheets, one for each class, in a fabricated Excel workbook.
Use an ADODB recordset to take advantage of Excel's speedy CopyFromRecordset function.
LOCAL:
    $ix: indexes worksheets.
    $subj: student's subject code.
    $class: student's class number.
    $ws: current worksheet.
    $subcode: current worksheet's new name (subj + class).
    $rangeData: Excel range for column sizing.
IN:
    $rowClasses, $tblClasses: data source for teacher's classes iterated by foreach loop.
    $prmSUKey, $prmClass: refreshed with new values during each iteration.
    $cmdStudents, $rstStudents: retrieve new class during each iteration.   
    $wb: current workbook, one per teacher.
OUT:
=====================================================#>
# Seed index for worksheets.
[int] $ix = 1

# Iterate each class.
foreach ($rowClasses in $tblClasses) {

# Assign subject and class values to typed variables.
    [string] $subj = $rowClasses.Item("subj")
    [int] $class = $rowClasses.Item("class")

# Rename worksheet.
    [string] $subcode = $subj + $class
    $ws = $wb.Sheets.item($ix)  
    $ws.Name = $subcode 

# Assign typed variables to ADODB parameters.
    $prmSUKey.Value = $subj
    $prmClass.Value = $class

# Assign result set to ADODB recordset.    
    $rstStudents = $cmdStudents.Execute()

# Copy result set to current worksheet. Adjust entry cell as reqd.
    $wb.Sheets.item($subcode).Cells.item(2,1).CopyFromRecordset($rstStudents)

# Size columns.
    $rangeData = $wb.Sheets.item($subcode).UsedRange
    [void] $rangeData.EntireColumn.Autofit()

# Increment index for worksheets.             
    $ix++
    
} # End foreach

<#=====================================================
SAVE WORKBOOK
LOCAL:
    $pathname
IN:
    $xlpath
    $sfkey
    $ttperiod
    $wb
OUT:
===================================================== #>
[string] $pathname = $xlpath + $sfkey + $ttperiod + ".xlsx"
$wb.SaveAs($pathname)

<#=====================================================
CLEANUP
=====================================================#>                            
function Release-Ref ($ref) { 
# ===================================================== 
# Author: Kent Finkle 
# http://gallery.technet.microsoft.co...8a41a680a7
# =====================================================                            
([System.Runtime.InteropServices.Marshal]::ReleaseComObject( 
[System.__ComObject]$ref) -gt 0) 
[System.GC]::Collect() 
[System.GC]::WaitForPendingFinalizers() 
}

# Close connections.
$cnnNET.Close
$cnnADO.Close

# Get rid of COM objects.
$k = Release-Ref($ws) 
$k = Release-Ref($wb) 
$k = Release-Ref($xl)
$k = Release-Ref($rstStudents)
$k = Release-Ref($cmdStudents)
$k = Release-Ref($prmTTPeriod)
$k = Release-Ref($prmSUKey)
$k = Release-Ref($prmClass)
$k = Release-Ref($cnnADO)

# Get rid of .NET objects.
$cmdSFKey.Dispose
Remove-Variable cmdSFKey

$cmdAdmin.Dispose
Remove-Variable cmdAdmin
$adpAdmin.Dispose
Remove-Variable adpAdmin
$tblAdmin.Dispose
Remove-Variable tblAdmin
$rowAdmin.Dispose
Remove-Variable rowAdmin

$cmdClasses.Dispose
Remove-Variable cmdClasses
$adpClasses.Dispose
Remove-Variable adpClasses
$tblClasses.Dispose
Remove-Variable tblClasses
$rowClasses.Dispose
Remove-Variable rowClasses

$cnnNET.Dispose
Remove-Variable cnnNET

# Get rid of Excel process.
# Idea from blub, http://www.powershellcommunity.org/...fault.aspx
$ExcelProcess=get-process excel
$ExcelProcess | foreach {stop-process ($_.id)}
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($xl) | out-null

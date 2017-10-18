function New-ODataServiceProxy {
#.Synopsis
#  Creates a proxy class for an odata web service
#  YOU NEED TO BE VERY CAREFUL NOT TO OUTPUT THE PROXY OBJECT TO THE POWERSHELL HOST!
#.Description 
#  Uses the data service client utility (DataSvcUtil.exe) to generate a proxy class (and types for all objects) for an OData web service. 
#  WARNING: Outputting this object to the PowerShell host will result in queriying all the object collections on the service.
#.Parameter URI
#  The URI for the web service
#.Parameter Passthru
#  Causes the method to output all of the types defined by the service metadata as well as the actual service object.
#.Example
#  $proxy = New-ODataServiceProxy http://odata.netflix.com/Catalog/
#  $AdventuresInOdyssey = $proxy.Titles.AddQueryOption('$filter',"substringof('Adventures in Odyssey',Name)")
#  $AdventuresInOdyssey | Format-List Name, ReleaseYear, Url, Synopsis
#.Link http://msdn.microsoft.com/en-us/library/ee383989.aspx
#.Notes
#  I can't stress enough that you should not output the object or any property that returns a System.Data.Services.Client.DataServiceQuery[T] without a filter unless you're sure that's what you want.
#
#  ADO.NET Data Service Client Utility http://msdn.microsoft.com/en-us/library/ee383989.aspx
#  AddQueryOption http://msdn.microsoft.com/en-us/library/cc646860.aspx
#  NetFlix Catalog http://developer.netflix.com/docs/oData_Catalog
#  Data Services Update for .Net 3.5 SP1 http://support.microsoft.com/kb/982307
#  
param( $URI = "http://odata.netflix.com/Catalog/", [switch]$Passthru )
## You can only use this on .Net 4 or .Net 3.5 SP1 
## For .Net 3.5 SP1 you need to download http://support.microsoft.com/kb/982307
## If you don't have it, this won't succeed
[Reflection.Assembly]::Load("System.Data.Services.Client, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089") | Out-Null

## Find the right DataSvcUtil for this version of .Net
switch($PSVersionTable.ClrVersion.Major) {
   4 { # PoshConsole and modded .Net4 PowerShell_ISE etc.
      Set-Alias Get-ODataServiceDefinition (Get-ChildItem ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())  DataSvcUtil.exe)
      break
   }
   2 { # PowerShell.exe and everyone else
      $FrameworkPath = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory() | Split-Path
      Set-Alias Get-ODataServiceDefinition (Get-ChildItem $FrameworkPath\v3.5\DataSvcUtil.exe)
      break
   }
}
## Get the service definition into a string via a temp file
$temp = [IO.Path]::GetTempFileName()
Get-ODataServiceDefinition -out:$temp -uri:$URI -nologo | Out-Null
$code = @(Get-Content $temp) -join "`n" # -Delim ([char]0)
Remove-Item $temp

$Types = Add-Type $code -Reference "System.Data.Services.Client, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" -Language CSharpVersion3 -Passthru
$ContextType = $Types | Where-Object { $_.BaseType -eq [System.Data.Services.Client.DataServiceContext] }

$ctx = new-object $ContextType $URI

Write-Output $ctx

if($Passthru) { Write-Output $types }
}



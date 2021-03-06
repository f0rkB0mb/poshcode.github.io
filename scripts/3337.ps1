<#
.SYNOPSIS
  Author:...Vidrine
  Date:.....2012/04/08
.DESCRIPTION
  Function uses the Microsoft SQL cmdlets 'Invoke-SQLcmd' to connect to a SQL database and run an UPDATE statement.
  The target record that will be updated is queried based on a table/column named 'ID'. Simply change this to query based on another value.
.PARAM server
  Hostname/IP of the server hosting the SQL database.
.PARAM database
  Name of the SQL database to connect to.
.PARAM table
  Name of the table within the specified SQL database.
.PARAM dataField
  Field/Column name from the specified table. This is the field/column that will be updated.
.PARAM dataValue
  The new value of the field/column that will be updated.
.PARAM updateID
  The ID of the target record to update.
.EXAMPLE
SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID
#>
function SQL-Update {
param(
	[string]$server,
	[string]$database,
	[string]$table,
	[string]$dataField,
	[string]$dataValue,
	[string]$updateID
)

$sqlQuery = @"
UPDATE $database.$table 
SET $dataField='$dataValue' 
WHERE id=$updateID
"@

try {
Invoke-SQLcmd -ServerInstance $server -Database $database -Query $sqlQuery
}
catch {
}
}

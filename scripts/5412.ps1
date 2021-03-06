<#

    .NOTES 
    Name: Availability Group Refresh
    Author: Rob Sewell http://sqldbawithabeard.com
    
    .DESCRIPTION 
        Refreshes an Availability group database from a backup taken from a Load Server

        YOU WILL NEED TO RESOLVE ORPHANED USERS IF REQUIRED
#> 

## http://msdn.microsoft.com/en-gb/library/hh213078.aspx#PowerShellProcedure
# http://msdn.microsoft.com/en-us/library/hh213326(v=sql.110).aspx
cls

# To Load SQL Server Management Objects into PowerShell
    [System.Reflection.Assembly]::LoadWithPartialName(‘Microsoft.SqlServer.SMO’)  | out-null
    [System.Reflection.Assembly]::LoadWithPartialName(‘Microsoft.SqlServer.SMOExtended’)  | out-null

$LoadServer = "" # The Load Server 

$Date = Get-Date -Format ddMMyy
$PrimaryServer = "" # The Primary Availability Group Server
$SecondaryServer = "" # The Secondary Availability Group Server
$TertiaryServer = "" # The Tertiary Availability Group Server
$AGName = "" # Availability Group Name
$DBName = "" # Database Name

$LoadDatabaseBackupFile = "\LoadTestDatabase" + $Date + ".bak" # Load database Backup location - Needs access permissions granted
$LogBackupFile = "\TestDatabase" + $Date + ".trn" # database Backup location - Needs access permissions granted

# Path to Availability Database Objects
$MyAgPrimaryPath = "SQLSERVER:\SQL\$PrimaryServer\DEFAULT\AvailabilityGroups\$AGName"
$MyAgSecondaryPath = "SQLSERVER:\SQL\$SecondaryServer\DEFAULT\AvailabilityGroups\$AGName"
$MyAgTertiaryPath = "SQLSERVER:\SQL\$TertiaryServer\DEFAULT\AvailabilityGroups\$AGName"

$StartDate = Get-Date
Write-Host "
##########################################
Results of Script to refresh $DBName on
$PrimaryServer , $SecondaryServer , $TertiaryServer
on AG $AGName
Time Script Started $StartDate

" -ForegroundColor Green


cd c:

# Remove old backups
If(Test-Path $LoadDatabaseBackupFile){Remove-Item -Path $LoadDatabaseBackupFile -Force}
If(Test-Path $DatabaseBackupFile){Remove-Item -Path $DatabaseBackupFile}
If(Test-Path $LogBackupFile ) {Remove-Item -Path $LogBackupFile }

Write-Host "Backup Files removed" -ForegroundColor Green

# Remove Secondary Replica Database from Availability Group to enable restore
Remove-SqlAvailabilityDatabase -Path SQLSERVER:\SQL\$SecondaryServer\DEFAULT\AvailabilityGroups\$AGName\AvailabilityDatabases\$DBName 

Write-Host "Secondary Removed from Availability Group" -ForegroundColor Green

# Remove Tertiary Replica Database from Availability Group to enable restore
Remove-SqlAvailabilityDatabase -Path SQLSERVER:\SQL\$TertiaryServer\DEFAULT\AvailabilityGroups\$AGName\AvailabilityDatabases\$DBName

Write-Host "Tertiary removed from Availability Group" -ForegroundColor Green

# Remove Primary Replica Database from Availability Group to enable restore
Remove-SqlAvailabilityDatabase -Path SQLSERVER:\SQL\$PrimaryServer\DEFAULT\AvailabilityGroups\$AGName\AvailabilityDatabases\$DBName

Write-Host "Primary removed from Availability Group" -ForegroundColor Green

# Backup Load Database
Backup-SqlDatabase -Database $DBName -BackupFile $LoadDatabaseBackupFile -ServerInstance $LoadServer

Write-Host "Load Database Backed up" -ForegroundColor Green

# Remove connections to database for Restore
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $PrimaryServer
$srv.KillAllProcesses($dbname)

# Restore Primary Replica Database from Load Database
Restore-SqlDatabase -Database $DBName -BackupFile $LoadDatabaseBackupFile  -ServerInstance $PrimaryServer -ReplaceDatabase

Write-Host "Primary Database Restored" -ForegroundColor Green

# Backup Primary Database
Backup-SqlDatabase -Database $DBName -BackupFile $LogBackupFile -ServerInstance $PrimaryServer -BackupAction 'Log'

Write-Host "Primary Database Backed Up" -ForegroundColor Green

# Remove connections to database for Restore
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $SecondaryServer
$srv.KillAllProcesses($dbname)

# Restore Secondary Replica Database 
Restore-SqlDatabase -Database $DBName -BackupFile $LoadDatabaseBackupFile-ServerInstance $SecondaryServer -NoRecovery -ReplaceDatabase 
Restore-SqlDatabase -Database $DBName -BackupFile $LogBackupFile -ServerInstance $SecondaryServer -RestoreAction 'Log' -NoRecovery  -ReplaceDatabase

Write-Host "Secondary Database Restored" -ForegroundColor Green

# Remove connections to database for Restore
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $TertiaryServer
$srv.KillAllProcesses($dbname)

# Restore Tertiary Replica Database 
Restore-SqlDatabase -Database $DBName -BackupFile $LoadDatabaseBackupFile -ServerInstance $TertiaryServer -NoRecovery -ReplaceDatabase
Restore-SqlDatabase -Database $DBName -BackupFile $LogBackupFile -ServerInstance $TertiaryServer -RestoreAction 'Log' -NoRecovery  -ReplaceDatabase

Write-Host "Tertiary Database Restored" -ForegroundColor Green

# Add database back into Availability Group
Add-SqlAvailabilityDatabase -Path $MyAgPrimaryPath -Database $DBName 
Add-SqlAvailabilityDatabase -Path $MyAgSecondaryPath -Database $DBName 
Add-SqlAvailabilityDatabase -Path $MyAgTertiaryPath -Database $DBName 

Write-Host "Database Added to Availability Group " -ForegroundColor Green

# Check Availability Group Status
 $srv = New-Object Microsoft.SqlServer.Management.Smo.Server $PrimaryServer
    $AG = $srv.AvailabilityGroups[$AGName]
    $AG.DatabaseReplicaStates|ft -AutoSize

    $EndDate = Get-Date
    $Time = $EndDate - $StartDate
Write-Host "
##########################################
Results of Script to refresh $DBName on
$PrimaryServer , $SecondaryServer , $TertiaryServer
on AG $AGName
Time Script ended at $EndDate and took
$Time

" -ForegroundColor Green

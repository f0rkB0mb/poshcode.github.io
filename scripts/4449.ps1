
#############################################################################################
#
# NAME: Drop-SQLUsers.ps1
# AUTHOR: Rob Sewell http://sqldbawithabeard.com
# DATE:06/08/2013
#
# COMMENTS: Load function to Display a list of server, database and login for SQL servers listed 
# in sqlservers.txt file and then drop the users
#
# I always recommend running the Checking for SQL Logins script after running this script to ensure all logins have been dropped
#
# Does NOT drop Users who have granted permissions
#BE CAREFUL


Function Drop-SQLUsers ($Usr)
{
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

# Suppress Error messages - They will be displayed at the end

$ErrorActionPreference = "SilentlyContinue"
# cls

# Pull a list of servers from a local text file

$servers = Get-Content 'c:\temp\sqlservers.txt'

# Create an array for the username and each domain slash username

$logins = @("DOMAIN1\$usr","DOMAIN2\$usr", "DOMAIN3\$usr" , "$usr")

				Write-Host "#################################"
                Write-Host "Dropping Logins for $Logins" 


	#loop through each server and each database and 
     Write-Host "#########################################"
     Write-Host "`n Database Logins`n"  
foreach($server in $servers)
{      	
    $srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $server
	#drop database users
	foreach($database in $srv.Databases)
	{
		if ($database -notlike "*dontwant*")
        {
            foreach($login in $logins)
		      {
			 if($database.Users.Contains($login))
			 {
			 	$database.Users[$login].Drop();
                 Write-Host " $server , $database , $login  - Database Login has been dropped" 
			 }
		      }
	   }
    }
    }
    
     Write-Host "`n#########################################"
     Write-Host "`n Servers Logins`n" 
      
    foreach($server in $servers)
{      	
    $srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $server
	#drop server logins
	foreach($login in $logins)
	{
		if ($srv.Logins.Contains($login)) 
		{ 
			$srv.Logins[$login].Drop(); 
         Write-Host " $server , $login Login has been dropped" 
		}
	}
}
Write-Host "`n#########################################"
Write-Host "Dropping Database and Server Logins for $usr - Completed "  
Write-Host "If there are no logins displayed above then no logins were found or dropped!"    
Write-Host "###########################################" 
}



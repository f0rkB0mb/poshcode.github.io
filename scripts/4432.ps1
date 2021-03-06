
  #############################################################################################
#
# NAME: Show-SQLServerPermissions.ps1
# AUTHOR: Rob Sewell http://newsqldbawiththebeard.wordpress.com
# DATE:06/08/2013
#
# COMMENTS: Load function for Enumerating Server and Database Role permissions or object permissions
#
# USAGE Show-SQLServerPermissions Server1
# ————————————————————————

Function Show-SQLServerPermissions ($SQLServer) 
{
    $server = new-object "Microsoft.SqlServer.Management.Smo.Server" $SQLServer

        $selected = "" 
        $selected = Read-Host "Enter Selection 
                                1.) Role Membership or 
                                2.) Object Permissions"
    
            Switch ($Selected)
            {
                    1{
    
                        Write-Host "####  Server Role Membership on $Server ############################################## `n`n"
                            foreach ($Role in $Server.Roles)
                                {
                                    Write-Host "###############  Server Role Membership for $role on $Server #########################`n" 
                                    $Role.EnumServerRoleMembers()

                                }
                        Write-Host "######################################################################################" 
                        Write-Host "######################################################################################`n `n `n" 


                            foreach ($Database in $Server.Databases)
                                {
                                    Write-Host "`n####  $Database Permissions on $Server ###############################################`n" 
                                        foreach($role in $Database.Roles)
                                            {
                                                Write-Host "###########  Database Role Permissions for $Database $Role on $Server ################`n"
                                                $Role.EnumMembers()

                                            }

                                }
                    } 

                   2{

                        Write-Host "##################  Object Permissions on $Server ################################`n"
                        foreach ($Database in $Server.Databases)
                            {
                            Write-Host "`n####  Object Permissions on $Database on $Server #################################`n"
                            foreach($user in $database.Users)
                                {
                                foreach($databasePermission in $database.EnumDatabasePermissions($user.Name))
                                    {
                                    Write-Host $databasePermission.PermissionState $databasePermission.PermissionType "TO" $databasePermission.Grantee
                                    }
                                foreach($objectPermission in $database.EnumObjectPermissions($user.Name))
                                    {
                                    Write-Host $objectPermission.PermissionState $objectPermission.PermissionType "ON" $objectPermission.ObjectName "TO" $objectPermission.Grantee
                                    }
                                }
                            }
                     }
            }
}


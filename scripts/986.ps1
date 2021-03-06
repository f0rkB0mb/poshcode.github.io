<#
.Synopsis
  Functions for managing SMS and SCCM.
.Notes
  NAME:      SMS.psm1
  AUTHOR:    Tim Johnson <tojo2000@tojo2000.com>
#>
#Requires -version 2.0

[string]$default_wmi_provider_server = 'myserver'
[string]$default_site = 'S00'


function Get-SmsWmi {
<#
.Synopsis
  A function for accessing the SMS WMI classes from the SMS Provider.
.Description
  This function wraps Get-WmiObject in order to provide an easy way to access
  the SMS Provider and the classes it provides.  This function keeps you from 
  having to keep entering in the long namespace and the name of the provider
  server every time you want to query the provider.

  Valid class nicknames include:

  Nickname                         WMI Class
  ==============================================================================
  AddRemovePrograms            =>  SMS_G_System_ADD_REMOVE_PROGRAMS
  AdStatus                     =>  SMS_ClientAdvertisementStatus
  Advertisement                =>  SMS_Advertisement
  Collection                   =>  SMS_Collection
  ComputerSystem               =>  SMS_G_System_COMPUTER_SYSTEM
  DistributionPoint            =>  SMS_DistributionPoint
  LogicalDisk                  =>  SMS_G_System_LOGICAL_DISK
  MembershipRule               =>  SMS_CollectionMembershipRule
  NetworkAdapter               =>  SMS_G_System_NETWORK_ADAPTER
  NetworkAdapterConfiguration  =>  SMS_G_System_NETWORK_ADAPTER_CONFIGURATION
  OperatingSystem              =>  SMS_G_System_OPERATING_SYSTEM
  Package                      =>  SMS_Package
  PkgStatus                    =>  SMS_PackageStatus
  Program                      =>  SMS_Program
  Query                        =>  SMS_Query
  Server                       =>  SMS_SystemResourceList
  Service                      =>  SMS_G_System_SERVICE
  Site                         =>  SMS_Site
  StatusMessage                =>  SMS_StatusMessage
  System                       =>  SMS_R_System
  WorkstationStatus            =>  SMS_G_System_WORKSTATION_STATUS
  User                         =>  SMS_R_User
.Parameter class
  The class or class nickname to be returned.
.Parameter computername
  The server with the SMS Provider installed.  Note: May not be the site server.
.Parameter site
  The site code of the site being accessed.
.Example
# Get all server clients
PS> Get-SmsWmi sys 'OperatingSystemNameAndVersion like "%serv%" and client = 1'
.Example
# Get the PackageID for all packages on Distribution Point Server1
PS> Get-SmsWmi dist 'ServerNALPath like "%Server1%"' | select PackageID
.Example
# Get the ResourceID for all systems with a HW Scan after 2009-03-31
PS> Get-SmsWmi work 'LastHardwareScan > "2009-03-31"' | select ResourceID
.ReturnValue
  System.Management.ManagementObject objects of the corresponding class.
.Link
  Documentation on the SMS WMI objects can be found in the SCCM SDK:
  http://www.microsoft.com/downloads/details.aspx?familyid=064a995f-ef13-4200-81ad-e3af6218edcc&displaylang=en
.Notes
  NAME:      Get-SmsWmi
  AUTHOR:    Tim Johnson <tojo2000@tojo2000.com>
  FILE:      SMS.psm1
#>
  param([Parameter(Position = 0)]
            [string]$class = $(Throw @"
`t
ERROR: You must enter a class name or nickname.
`t
Valid nicknames are:
`t
  Nickname                         WMI Class
  ==============================================================================
  AddRemovePrograms            =>  SMS_G_System_ADD_REMOVE_PROGRAMS
  AdStatus                     =>  SMS_ClientAdvertisementStatus
  Advertisement                =>  SMS_Advertisement
  Collection                   =>  SMS_Collection
  ComputerSystem               =>  SMS_G_System_COMPUTER_SYSTEM
  DistributionPoint            =>  SMS_DistributionPoint
  LogicalDisk                  =>  SMS_G_System_LOGICAL_DISK
  MembershipRule               =>  SMS_CollectionMembershipRule
  NetworkAdapter               =>  SMS_G_System_NETWORK_ADAPTER
  NetworkAdapterConfiguration  =>  SMS_G_System_NETWORK_ADAPTER_CONFIGURATION
  OperatingSystem              =>  SMS_G_System_OPERATING_SYSTEM
  Package                      =>  SMS_Package
  PkgStatus                    =>  SMS_PackageStatus
  Program                      =>  SMS_Program
  Query                        =>  SMS_Query
  Server                       =>  SMS_SystemResourceList
  Service                      =>  SMS_G_System_SERVICE
  Site                         =>  SMS_Site
  StatusMessage                =>  SMS_StatusMessage
  System                       =>  SMS_R_System
  WorkstationStatus            =>  SMS_G_System_WORKSTATION_STATUS
  User                         =>  SMS_R_User
`t
Note: You only need to type as many characters as needed to be unambiguous.
`t
"@),

        [Parameter(Position = 1)]
        [string]$filter = $null,
        [Parameter(Position = 2)]
        [string]$computername = $default_wmi_provider_server,
        [Parameter(Position = 3)]
        [string]$site = $default_site)

  $classes = @{'collection' = 'SMS_Collection';
               'package' = 'SMS_Package';
               'program' = 'SMS_Program';
               'system' = 'SMS_R_System';
               'server' = 'SMS_SystemResourceList';
               'advertisement' = 'SMS_Advertisement';
               'query' = 'SMS_Query';
               'membershiprule' = 'SMS_CollectionMembershipRule';
               'statusmessage' = 'SMS_StatusMessage';
               'site' = 'SMS_Site';
               'user' = 'SMS_R_User';
               'pkgstatus' = 'SMS_PackageStatus';
               'addremoveprograms' = 'SMS_G_System_ADD_REMOVE_PROGRAMS';
               'computersystem' = 'SMS_G_System_COMPUTER_SYSTEM';
               'operatingsystem' = 'SMS_G_System_OPERATING_SYSTEM';
               'service' = 'SMS_G_System_SERVICE';
               'workstationstatus' = 'SMS_G_System_WORKSTATION_STATUS';
               'networkadapter' = 'SMS_G_System_NETWORK_ADAPTER';
               'networkadapterconfiguration' = ('SMS_G_System_NETWORK_' +
                                                'ADAPTER_CONFIGURATION');
               'logicaldisk' = 'SMS_G_System_LOGICAL_DISK';
               'distributionpoint' = 'SMS_DistributionPoint';
               'adstatus' = 'SMS_ClientAdvertisementStatus'}

  $matches = @();

  foreach ($class_name in @($classes.Keys | sort)) {
    if ($class_name.StartsWith($class.ToLower())) {
      $matches += $classes.($class_name)
    }
  }

  if ($matches.Count -gt 1) {
    Write-Error @"
`t
Warning: Class provided matches more than one nickname.
`t
Type 'Get-SMSWmi' with no parameters to see a list of nicknames.
`t
"@
    $class = $matches[0]
  } elseif ($matches.Count -eq 1) {
    $class = $matches[0]
  }

  $query = "Select * from $class"

  if ($filter) {
    $query += " Where $filter"
  }

  # Now that we have our parameters, let's execute the command.
  $namespace = 'root\sms\site_' + $site
  gwmi -ComputerName $computerName -Namespace $namespace -Query $query
}


function Find-SmsID {
<#
.Synopsis
  Look up SMS WMI objects from the SMS Provider by SMS ID.
.Description
  This function makes it easy to look up a System Resource, Advertisement, 
  Package, or Collection by ID.  The SMS Provider is queried, and the WMI object
  that matches the ID is returned.
.Parameter AdvertisementID
  A switch indicating that the $ID is an AdvertisementID.
.Parameter CollectionID
  A switch indicating that the $ID is a CollectionID.
.Parameter PackageID
  A switch indicating that the $ID is a PackageID.
.Parameter ResourceID
  A switch indicating that the $ID is a ResourceID.
.Parameter ID
  A string with the ID to look up.
.Parameter computername
  The server with the SMS Provider installed.  Note: May not be the site server.
.Parameter site
  The site code of the site being accessed.
.Example
# Look up PackageID S000003D
PS> Find-SmsID -PackageID S000003D
.ReturnValue
  A System.Management.ManagementObject object of the corresponding class.
.Link
  Documentation on the SMS WMI objects can be found in the SCCM SDK:
  http://www.microsoft.com/downloads/details.aspx?familyid=064a995f-ef13-4200-81ad-e3af6218edcc&displaylang=en
.Notes
  NAME:      Find-SmsID
  AUTHOR:    Tim Johnson <tojo2000@tojo2000.com>
  FILE:      SMS.psm1
#>
  param([switch]$AdvertisementID,
        [switch]$CollectionID,
        [switch]$ResourceID,
        [switch]$PackageID,
        [string]$ID,
    [string]$computername = $default_wmi_provider_server,
    [string]$site = $default_site)

  $class = ''
  $Type = ''

  if ($AdvertisementID) {
    $Type = 'AdvertisementID'
    $class = 'SMS_Advertisement'
  } elseif ($CollectionID) {
    $Type = 'CollectionID'
    $class = 'SMS_Collection'
  } elseif ($PackageID) {
    $Type = 'PackageID'
    $class = 'SMS_Package'
  } elseif ($ResourceID) {
    $Type = 'ResourceID'
    $class = 'SMS_R_System'
  } else {
    Throw @"
`t
You must specify an ID type.  Valid switches are:
`t
`t-AdvertisementID
`t-CollectionID
`t-PackageID
`t-ResourceID
`t
USAGE: Find-SmsID <Type> <ID> [-computername <computer>] [-site <site>]
`t
"@
  }

  if ($ResourceID) {
    trap [System.Exception] {
      Write-Output "`nERROR: Invalid Input for ResourceID!`n"
      break
    }
    $Type = 'ResourceID'
    $class = 'System'
    [int]$ID = $ID
  } else{
    if ($ID -notmatch '^[a-zA-Z0-9]{8}$') {
      Throw "`n`t`nERROR: Invalid ID format.`n`t`n"
    }
  }

  Get-SmsWmi -class $class -filter "$Type = `"$ID`"" `
             -computername $computername `
             -site $site
}


function Get-SmsCollectionTree {
<#
.Synopsis
  Inspired by tree.com from DOS, it creates a tree of all collections in SMS.
.Description
  This function iterates recursively through all collections, showing which
  collections are under which other collections, and what their CollectionIDs
  are.
.Parameter root
  The CollectionID of the collection to start with (default COLLROOT).
.Parameter indent
  The indent level of the current interation.
.Parameter computername
  The hostname of the server with the SMS Provider
.Parameter site
  The site code of the target SMS site.
.Link
  Documentation on the SMS WMI objects can be found in the SCCM SDK:
  http://www.microsoft.com/downloads/details.aspx?familyid=064a995f-ef13-4200-81ad-e3af6218edcc&displaylang=en
.Notes
  NAME:      Get-SmsCollectionTree
  AUTHOR:    Tim Johnson <tojo2000@tojo2000.com>
  FILE:      SMS.psm1
#>
  param([string]$root = 'COLLROOT',
        [int]$indent = 0,
    [string]$computername = $default_wmi_provider_server,
    [string]$site = $default_site)

  Get-SmsWmi -class SMS_CollectToSubCollect `
             -filter "parentCollectionID = '$root'"  `
             -computername $computername `
             -site $site |
    % {$name = (Find-SmsID -c $_.subCollectionID).Name
       Add-Member -InputObject $_ -Name 'sub_name' NoteProperty $name
       $_} |
    sort sub_name |
    % {Write-Host (('    ' * $indent) +
                    "+ $($_.sub_name) : $($_.subCollectionID)")
       Get-SmsCollectionTree -root $_.subCollectionID `
                             -indent ($indent + 1) `
                             -computername $computername `
                             -site $site}
}


function Approve-Client {
<#
.Synopsis
  Approves a list of resources or all clients in a collection.
.Description
  Marks one or more clients as Approved in the SCCM DB.  A list of resources
  or a CollectionID may be passed.
.Parameter resource_list
  A list of ResourceIDs to be approved.
.Parameter collection_id
  A CollectionID whose members will be approved.
.Parameter computername
  The server with the SMS Provider installed.  Note: May not be the site server.
.Parameter site
  The site code of the site being accessed.
.Example
# Approve two systems by ResourceID
PS> Approve-Client -resource_list 33217, 4522
.Example
# Approve all members of collection S000023C
PS> Approve-Client -collection_id S000023C
.ReturnValue
  An integer with the number of clients approved.
.Link
  Documentation on the SMS WMI objects can be found in the SCCM SDK:
  http://www.microsoft.com/downloads/details.aspx?familyid=064a995f-ef13-4200-81ad-e3af6218edcc&displaylang=en
.Notes
  NAME:      Approve-Client
  AUTHOR:    Tim Johnson <tojo2000@tojo2000.com>
  FILE:      SMS.psm1
#>
  param([string[]]$resource_list,
        [string]$collection_id,
        [string]$computername = $default_wmi_provider_server,
        [string]$site = $default_site)

  $clients = @()
  $coll_class = [wmiclass]('\\{0}\root\sms\site_{1}:SMS_Collection' `
                           -f $computername, $site)

  if ($resource_list.Count) {
    $clients = $resource_list
  }elseif ($collection_id){
    $clients = @(Get-SmsWmi SMS_CollectionMember_a `
                 -filter "CollectionID = '$($collection_id)'" |
                   %{$_.ResourceID})
  }

  if ($clients.Count -eq 0) {
    Write-Error ('Error: You must supply at least one client.`n' +
                 '       (Did you enter an empty or invalid collection?)')
    break
  }
  
  return ($coll_class.ApproveClients($clients)).ReturnValue
}

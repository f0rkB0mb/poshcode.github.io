function ExecSQLcmd{
      param(
            [string]$ServerName,
            [string]$DatabaseName,
            [string]$UserN,
            [string]$Password,
            [string]$SQLCommand,
            [Boolean]$IsQuery = $False
            )     
            
      #Output Results to DataSet
      if ($IsQuery -eq $true)
            {     
                  $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
                  $SqlConnection.ConnectionString = "server=$ServerName;database=$DatabaseName;Integrated Security=sspi"
                  $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
                  $SqlCmd.CommandText = $SQLCommand
                  $SqlCmd.Connection = $SqlConnection
                  $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
                  $SqlAdapter.SelectCommand = $SqlCmd
                  $DataSet = New-Object System.Data.DataSet
                  $SqlAdapter.Fill($DataSet) | out-null
                  $SqlConnection.Close()
                  return $DataSet
         	} else  {
                  $conStr = "server=$ServerName;database=$DatabaseName;Integrated Security=sspi"
                  $cn = new-object System.Data.SqlClient.SqlConnection $conStr
                  $cn.Open()
                  $sql = $cn.CreateCommand()
                  $sql.CommandText = $SQLCommand
                  $rdr = $sql.ExecuteReader()         
                  $cn.Close()
            }
            #Close connection 
}


$adapters = get-netipconfiguration -Detailed | Select Computername,InterfaceAlias,
@{N="Status";E={$_.NetAdapter.Status}},
@{N="IP";E={"$($_.IPv4Address.IPv4Address)/$($_.IPv4Address.PrefixLength)"}},
@{N="DefaultGateway";E={$_.IPv4DefaultGateway.nexthop}},
@{N="MAC";E={$_.NetAdapter.MACAddress}},
@{N="DHCP";E={$_.NetIPv4Interface.DHCP}},
@{N="DNS";E={
($_.DNSServer | where {$_.AddressFamily -eq 2} |
select -ExpandProperty ServerAddresses) -join ","}}  

foreach ($adapter in $adapters)
{
			$sqlstr= "$sqlstr INSERT INTO MYTABLENAME"
			$sqlstr= "$sqlstr (column1"
			$sqlstr= "$sqlstr ,column2)"
			$sqlstr= "$sqlstr VALUES"
			$sqlstr= "$sqlstr ('value1'"
			$sqlstr= "$sqlstr ,'value2')"
			ExecSQLcmd -ServerName "mysqlserver01" -DatabaseName "test" -SQLCommand $sqlstr
}

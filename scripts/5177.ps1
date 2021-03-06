function Invoke-Sql {
    <#
    .SYNOPSIS
        Invokes a SQL command.
    .DESCRIPTION
        Executes a SQL command against the specified database.
    .PARAMETER Server
        The host name of the SQL server.
    .PARAMETER Database
        The name of the database against which the command will be executed.
    .PARAMETER Command
        The SQL command to execute, in Transact-SQL.
    .EXAMPLE
        None
    .OUTPUTS
        System.Data.SqlClient.SqlDataReader | System.Int64
    .NOTES
        This command returns output dependent upon the SQL command to execute. If it is a SELECT
        command, the result set is returned in the form of a SqlDataReader object. Otherwise, the
        command is executed and an integer representing the number of rows affected is returned.
    #>

	param (	
		#the host name of the SQL server
		[string]$Server,
		#the name of the database
		[string]$Database,
		#the commands to execute (name of stored procedure)
		[string]$Command
	)

	$sqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$sqlConnection.ConnectionString = "Data Source=$Server;Initial Catalog=$Database;Integrated Security=True;MultipleActiveResultSets=True;"
	$sqlCommand = New-Object System.Data.SqlClient.SqlCommand
	$sqlCommand.CommandType = [System.Data.CommandType]::Text
	$sqlCommand.CommandText = $Command
	
    try {
        $sqlConnection.Open()
	    $sqlCommand.Connection = $sqlConnection
        if ($Command -like "SELECT*") {
        	<#  if the command is a select statement, use ExecuteReader, which executes the query and returns
                the result set in an SQLDataReader object, which we return for consumption #>
            return $sqlCommand.ExecuteReader([System.Data.CommandBehavior]::CloseConnection)
        } else {
            <#  otherwise, use ExecuteNonQuery, which executes the command and returns the number of rows
                affected. #>
            $sqlCommand.ExecuteNonQuery()
        }
	    $sqlConnection.Close()
    } catch {
        throw ("Error executing command: {0}" -f $_.Message)
    }
}

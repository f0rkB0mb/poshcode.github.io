[void][system.reflection.Assembly]::LoadWithPartialName("MySql.Data")

# Open Connection
$connStr = "server=127.0.0.1;port=3306;uid=root;pwd=password;database=test;Pooling=False"
$conn    = New-Object MySql.Data.MySqlClient.MySqlConnection($connStr)
$conn.Open()


# write the info
$sql = "INSERT INTO table1 (name) VALUES ('billy')";
$cmd = New-Object MySql.Data.MySqlClient.MySqlCommand($sql, $conn)
$da  = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($cmd)

# Populate a dataset and output the query result
$ds = New-Object System.Data.DataSet


# read the info
$sql = "SELECT * FROM table1";
$cmd = New-Object MySql.Data.MySqlClient.MySqlCommand($sql, $conn)
$da  = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($cmd)

# Populate a dataset and output the query result
$ds = New-Object System.Data.DataSet
$da.Fill($ds) > $null
$result = $ds.Tables[0]
$result | Format-Table id, name -auto

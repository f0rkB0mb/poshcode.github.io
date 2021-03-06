param (
    [System.Data.SqlClient.ApplicationIntent]$ApplicationIntent,
    [string]$ApplicationName,
    [switch]$AsynchronousProcessing,
    [string]$AttachDBFilename,
    [switch]$ConnectionReset,
    [string]$ConnectionString,
    [int]$ConnectRetryCount,
    [int]$ConnectRetryInterval,
    [int]$ConnectTimeout,
    [switch]$ContextConnection,
    [string]$CurrentLanguage,
    [string]$DataSource,
    [switch]$Encrypt,
    [switch]$Enlist,
    [string]$FailoverPartner,
    [string]$InitialCatalog,
    [switch]$IntegratedSecurity,
    [int]$LoadBalanceTimeout,
    [int]$MaxPoolSize,
    [int]$MinPoolSize,
    [switch]$MultipleActiveResultSets,
    [switch]$MultiSubnetFailover,
    [string]$NetworkLibrary,
    [int]$PacketSize,
    [string]$Password,
    [switch]$PersistSecurityInfo,
    [switch]$Pooling,
    [switch]$Replication,
    [string]$TransactionBinding,
    [switch]$TrustServerCertificate,
    [string]$TypeSystemVersion,
    [string]$UserID,
    [switch]$UserInstance,
    [string]$WorkstationID
)

$builder = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder

$PSBoundParameters.Keys | % { $key = $_ -creplace '([a-z])([A-Z])', '$1 $2'; $builder[$key] = $PSBoundParameters[$_].ToString() }

$builder.ConnectionString

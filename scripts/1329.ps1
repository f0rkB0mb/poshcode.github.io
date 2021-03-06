Function Get-ExpiredCert {
<#
	.SYNOPSIS
		Reports the number of expired certificates published to a user account
		in Active Directory.

	.DESCRIPTION
		This will give you a total count of expired certs for each user account.

	.PARAMETER  InputObject
		Specifies the user object. This would be one or more DirectoryServices.DirectoryEntry object,
		DirectoryServices.SearchResult object, or ArsUserObject object.

	.EXAMPLE
		Get-ExpiredCert -InputObject (Get-QADUser testuser1)

	.EXAMPLE
		Get-QADUser | Get-ExpiredCert
		
	.EXAMPLE
		$searcher = New-Object System.DirectoryServices.DirectorySearcher
		$searcher.Filter = "(&(objectCategory=person)(objectClass=user))"
		$users = $searcher.FindAll()
		$users | Get-ExpiredCert
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
	[Object]$InputObject
	)
	
Process
  {
    foreach ($object in $InputObject) {
    $user = [adsi]$object.path
    $s = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cExpired = 0
    foreach ($i in ($user.properties["usercertificate"])) {
    	$s.import([byte[]]($i))
	If (($s.verify()) -eq $false) {
		$cExpired ++
	    }
	}
	New-Object PSObject -Property @{
	Name=$user.name[0];
	CertsExpired=$cExpired;}
	}
  }
}

# Note that this version will not descend directories.
function Publish-File {
	param (
		[parameter( Mandatory = $true, HelpMessage="URL pointing to a SharePoint document library (omit the '/forms/default.aspx' portion)." )]
		[System.Uri]$Url,
		[system.Management.Automation.PSCredential]$Credential,
		[parameter( Mandatory = $true, ValueFromPipeline = $true, HelpMessage="One or more files to publish. Use 'dir' to produce correct object type." )]
		[System.IO.FileInfo[]]$FileName
	)
	Add-Type -AssemblyName System.Web
	$wc = new-object System.Net.WebClient
	if ( $Credential ) { $wc.Credentials = $Credential }
	else { $wc.UseDefaultCredentials = $true }
	$FileName | ForEach-Object {
		$DestUrl = [system.Web.HttpUtility]::UrlPathEncode( ( "{0}{1}{2}" -f $Url.ToString().TrimEnd("/"), "/", $_.Name ) )
		Write-Verbose "$( get-date -f s ): Uploading file: $_"
		Write-Verbose "url: $DestUrl"
		$wc.UploadFile( $DestUrl , "PUT", $_.FullName )
		Write-Verbose "$( get-date -f s ): Upload completed"
	}
	
}

# Example:
# dir c:\path\files* | Publish-File -Url "https://mysharepointsite.com/personal/userID/Personal%20Documents"


# Execute-MagisterSOAP.ps1
# We are reading a list of students from a Magister SOAP webrequest.
# 20120330
# Paul Wiegmans
Clear
Set-StrictMode -Version 2

$mijnpad = Split-Path -parent $MyInvocation.MyCommand.Definition
Echo "Mijn pad is: $mijnpad "
# This is the Magister webquery URL
$layout = "Basis"
$username = "user"
$passwd = "pass"
$WebqueryUrl = "https://bonhoeffer.swp.nl:8800/doc?Function=GetData"`
	+"&Library=Data&SessionToken=$username%3B$passwd&Layout=$layout"`
	+"&Parameters=leerjaar%3D1112&Type=CSV"

function Doe-Webquery ($Url) {
	# .SYNOPSIS
	#	Voert een SOAP webquery uit
	# .DESCRIPTION
	#	Voert een SOAP webquery uit.
	#	Retourneert het resultaat van de qebquery in een array met string
	# .PARAMETER Url
	#	De URL van de webquery
	# .EXAMPLE
	#	$lines = Doe-Webquery "https://bonhoeffer.swp.nl:8800/doc?Bladibla..."
	# .NOTES
	# 	Auteur: Paul Wiegmans
	#	Datum:	30 mrt 2012
	
	$request = [System.Net.WebRequest]::Create($Url)
	$response = $request.GetResponse()
	$requestStream = $response.GetResponseStream()
	$MagisterEncoding = [System.Text.Encoding]::UTF7  
	# We must read the Magister webquery in UTF7 to preserve the accents!
	$readStream = new-object System.IO.StreamReader( $requestStream, $MagisterEncoding )

	$result = $readStream.ReadToEnd() -split "`n"  # convert to array of strings

	$readStream.Close()
	$response.Close()
	return $result
}

$lines = Doe-Webquery $WebQueryUrl
Echo "Webquery geeft $($lines.count) regels"
$velden = $lines[0] -split ";"     # list of fieldnames
$lijst = $lines[1..$lines.Count]   # 

# uitvoer naar file
$lines | Out-File -FilePath "$mijnpad\soap.csv" -Encoding utf8 # encoding is utf8 of ascii


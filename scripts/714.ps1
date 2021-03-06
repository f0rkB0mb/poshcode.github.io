function global:Get-BracketContent {
	PARAM	(
		  [string[]] $txtInput = $(Throw "Please provide input string(s)!")
		, [string] $patternString = '<.*>'
		, [switch] $caseSensitive = $false
	)
	
	# Store the pattern in a variable we can change depending on caseSensitive option.  Leave original pattern there to use in Select-String Later.
	$regexPattern = $patternString
	
	# By default, we're searching case-insensitive, so modify the regexpattern to indicate such & create the actual regex object
	if ($caseSensitive -eq $false) { $regexPattern = "(?i)$regexPattern" }
	$regex = New-Object System.Text.RegularExpressions.Regex $regexPattern
	
	# Function to find a regex match & output only the match.  All other text on the line is discarded.
	function Select-PatternMatch ([string]$inputText) {
		$index = 0 											# Start at the beginning of the line
		while ($index -lt $inputText.Length) {  			# Keep looking for matches as long as we're not at the end of the line
			$match = $regex.Match($inputText, $index)		# Beginning where we're at on the line, check to see if a match exists.
			if ($match.Success -and $match.Length -gt 0) {	# If there's a match, output it to the pipeline
				Write-Output $match.Value.ToString()
				$index = $match.Index + $match.Length		# Update our current location on the line
			}
			else { $index = $inputText.Length }				# If no match was found at all, then just say we're at the end so the while loop will stop.
		}
	}
	
	$txtInput | Select-String -pattern:$patternString | ForEach-Object { Select-PatternMatch $_.Line } | ForEach-Object { $_.SubString(1,($_.Length -2 )) }
}

Get-BracketContent "Alert from monitor: <alert@email.com>."

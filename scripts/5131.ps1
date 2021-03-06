function gather {
#.SYNOPSIS
#  Port of Perl 6's gather/take (which itself is a port of Mathematica's Reap/Sow)
#.PARAMETER Using
#  An already existing ArrayList to append to
#.EXAMPLE
#  gather { 1 ; take 2 ; 3 ; take 4 5 }
#  2
#  4
#  5
#.NOTES
#  PowerShell doesn't really need this since the pipeline does this by default
#  (and does a much better job since it works by using a push streaming model)
#  but it's useful in the rare cases that it's necessary.
	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[scriptblock]$Script
,
		[ValidateNotNull()]
		[System.Collections.IList]$Using
	)
	try {
		${function:take} = (New-Object System.Management.Automation.PSModuleInfo $true).NewBoundScriptBlock({
			foreach ($null in $args) { $null = $script:acc.Add([string]$foreach.Current) }
		})
		& ${function:take}.Module { $script:acc = $args[0] } $(if ($PSBoundParameters.ContainsKey('Using')) { ,$Using } else { ,[System.Collections.ArrayList]@() })
	} catch {
		throw
	}
	$null = & $Script
	if (-not $PSBoundParameters.ContainsKey('Using')) {
		& ${function:take}.Module { $script:acc }
	}
}

## ExceptionHandling.ps1
##############################################################################################################
## .Net style exception handling
##############################################################################################################
## Usage:
##    . .\ExceptionHandling.ps1
##############################################################################################################
## v 1.0 - First release
##############################################################################################################

if (-not ($MyInvocation.line -match '^\. .')) {
	Write-Error 'No Functions were loaded - you need to invoke with . scriptname'
	return
}

# .SYNOPSIS 
# Facilitates exception handling as used to under C# or Java
#
# .PARAMETER Command
# Contains the guarded code that may cause the exception. The block is executed until an exception is thrown or it is completed successfully.
# .INPUTS
# None. You cannot pipe objects to try().
#
# .EXAMPLE
# function simpleException() {
#     try {
#         "Guarded code"
#         throw New-Object [System.Exception]
#     } -catch {
#         "Catched " + $_.Exception
#     } -finally {
#         "All done with trying and catching"
#     }
# }
#
# .EXAMPLE
# function multiDivByZeroSpecified() {
#     try {
#         [int32]1/[int32]0
#     } -catch @{[System.DivideByZeroException] = {
#         "Catched DivideByZeroException"
#     }} -catch1 @{[System.Exception] = {
#         "Catched Exception"
#     }} -finally {
#         "All done with trying and catching"
#     }
# }
#
# .EXAMPLE
# function multiDivByZero() {
#     try {
#         [int32]1/[int32]0
#     } -catch @{[System.DivideByZeroException] = {
#         "Catched DivideByZeroException"
#     }} -catch1 {
#         "Catched Exception"
#     } -finally {
#         "All done with trying and catching"
#     }
# }
#
# .LINK
# trap
# .LINK
# http://huddledmasses.org/trap-exception-in-powershell/
# .LINK
# http://weblogs.asp.net/adweigert/archive/2007/10/10/powershell-try-catch-finally-comes-to-life.aspx
function try {
	param (
		[ScriptBlock] $command = $( throw "The parameter -Command is required." ),
		[Object]      $catch,
		[Object]      $catch1,
		[Object]      $catch2,
		[Object]      $catch3,
		[Object]      $catch4,
		[Object]      $catch5,
		[Object]      $catch6,
		[Object]      $catch7,
		[Object]      $catch8,
		[Object]      $catch9,
		[ScriptBlock] $finally = {}
	)
	
	# merge all catches to one single hashtable
	$catches = @{}
	($catch,$catch1,$catch2,$catch3,$catch4,$catch5,$catch6,$catch7,$catch8,$catch9) | ? { $_ -ne $null } | % {
		if ($_ -is [System.Collections.Hashtable]) {
			$catches += $_
		} elseif ($_ -is [ScriptBlock]) {
			if ($catches.Contains([System.Exception])) {
				$catches.set_Item([System.Exception], $_)
			} else {
				$catches.Add([System.Exception], $_)
			}
		} else {
			throw New-Object Exception("Unknown catch argument type'" + $_.GetType() + "'")
		}
	}
	
	& {
		$local:ErrorActionPreference = "SilentlyContinue"
		trap {
			trap {
				& {
					trap { throw $_ }
					&$finally
				}
				throw $_
			}
			$exType = $_.Exception.GetType()
			$catch  = $null
			do {
				$catches.GetEnumerator() | ? { $exType -eq $_.Key } | % { $catch = $_.Value }
				if ($catch -ne $null) {
					break
				}
				$exType = $exType.BaseType
			} while ($exType -ne $null)
			if ($catch -eq $null) { throw $_ }
			$_ | & { &$catch }
		}
		&$command
	}
	& {
		trap { throw $_ }
		&$finally
	}
}


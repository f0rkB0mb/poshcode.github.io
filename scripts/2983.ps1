function Test-EmptyFolder {
<#
	.SYNOPSIS
		Tests for empty folders.

	.DESCRIPTION
		The Test-EmptyFolder function tests if a specified folder is empty by checking if it
		contains files or folders. The function returns the folder path and a boolean value for empty.

	.PARAMETER Path
		Specifies the path of the folder to test.

	.EXAMPLE
		Test-EmptyFolder
		Returns if the current path is an empty folder.

	.EXAMPLE
		Test-EmptyFolder C:\temp
		Returns if the path C:\temp is an empty folder.

	.EXAMPLE
		dir $env:TEMP -Recurse | Test-EmptyFolder
		Gets a directory listing of the TEMP folder including recursive items and
		passes each object into the pipeline testing for empty folders.

	.INPUTS
		System.String

	.OUTPUTS
		PSObject

	.NOTES
		Name: Test-EmptyFolder
		Author: Rich Kusak
		Created: 2011-09-25
		LastEdit: 2011-10-03 10:44
		Version: 1.0.0.0

	.LINK
		http://msdn.microsoft.com/en-us/library/kx74h1k4.aspx

#>

	[CmdletBinding()]
	param (
		[Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateScript({
			if (Test-Path -LiteralPath $_) {$true} else {
				throw "The argument '$_' does not specify an existing path."
			}
		})]
		[Alias('FullName')]
		[string]$Path = '.'
	)
	
	begin {
	
		$properties = 'Path','IsEmpty'

	} # begin
	
	process {
	
		if (Test-Path -LiteralPath $Path -PathType Leaf) {
			return Write-Verbose "The path '$Path' is a file. Only folders are tested."
		}
		
		try {
			$folder = Get-Item $Path -Force -ErrorAction Stop
		} catch {
			return Write-Error $_
		}

		try {
			$isEmpty = ($folder.GetFiles().Count -eq 0) -and ($folder.GetDirectories().Count -eq 0)
		} catch {
			return Write-Error $_.Exception.InnerException.Message
		}
			
		New-Object PSObject -Property @{
			'Path' = $folder.FullName
			'IsEmpty' = $isEmpty
		} | Select $properties

	} # process
} # function Test-EmptyFolder


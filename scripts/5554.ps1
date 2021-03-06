function Write-Log {
  #.Synopsis
  #  Write to a rotating log file
  #.Example
  #  Get-ChildItem C:\ -Recurse | Select FullName, CreationTimeUtc, LastWriteTimeUtc | Write-Log Files.txt -Rotate 5mb
  #
  #  Writes a file list to disc, breaking it into multiple files of approximately 5MB of data each
  [CmdletBinding()]
  param(
    # The file path to log to
    [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory=$true, Position=0)]
    [Alias("PSPath")]
    $FilePath,

    [Parameter(Position=1)]
    [ValidateSet('unknown','string','unicode','bigendianunicode','utf8','utf7','utf32','ascii','default','oem')]
    [ValidateNotNullOrEmpty()]
    [string]
    ${Encoding} = 'utf8',

    [ValidateRange(2, 2147483647)]
    [int]
    ${Width},

    # A max file size at which to rotate the log file
    [Parameter()]
    [Alias("Rotate","Length")]
    [int]$SizeLimit = 10MB,

    # A max file size at which to rotate the log file
    [Parameter()]
    [Alias("Count")]
    [int]$FileCountLimit = 6,
	
	[Parameter(Mandatory=$false)]
	[string]$Header,

    # The data to log
    [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
    $InputObject
  )
  begin { 
	
    try {
        if($PSBoundParameters.ContainsKey('OutBuffer')) {
          $null = $PSBoundParameters.Remove('OutBuffer')
        }
        if($PSBoundParameters.ContainsKey('SizeLimit')) {
          $null = $PSBoundParameters.Remove('SizeLimit')
        }
        if(!$PSBoundParameters.ContainsKey('Encoding')) {
          $null = $PSBoundParameters.Add('Encoding', $Encoding)
        }
		
		if ($PSBoundParameters.ContainsKey('Header')) {
			$null = $PSBoundParameters.Remove('Header')
		}
		
		if ($PSBoundParameters.ContainsKey('FileCountLimit')) {
			$null = $PSBoundParameters.Remove('FileCountLimit')
		}
	
        # Pipeline-bound parameters will be set on $PSBoundParameters later (in the process block)
        # Since we have to (re)create the steppablePipeline, we need a copy of them as they are now        		
		$Parameters = @{} + $PSBoundParameters		
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand(
                          'Microsoft.PowerShell.Utility\Out-File',
                          [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @Parameters -Append }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)				
    } catch {
        throw
    }
  }
  process {	
    try {
	  
	  #If header enabled, write it out after out-file creates the empty file on very first run.
	  if (((Get-Item $FilePath).Length -eq 0) -and $Header)
		{			
			$steppablePipeline.Process($Header)
		}
		
      $steppablePipeline.Process($_)
	
      # If the file triggers rotation:
      if(($file = Get-Item $FilePath) -and $file.Length -gt $SizeLimit) {
        # Remove the last item if it would go over the limit
        $steppablePipeline.End()
		
		        
		if(Test-Path "$FilePath.$FileCountLimit") {          
		  Write-Verbose "Removing $FilePath.$FileCountLimit"
          Remove-Item "$FilePath.$FileCountLimit"
        }
        foreach($i in ($FileCountLimit)..1) {			
          if(test-path "$FilePath.$($i-1)") {
            Move-Item "$FilePath.$($i-1)" "$FilePath.$i"
          }
        }
        Move-Item $FilePath "$FilePath.$i"
        $null = New-Item $FilePath -Type File
		
		# Inject header into new file if passed in, otherwise ignore it.
		if ($Header) {			
			$steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
			$steppablePipeline.Begin($PSCmdlet)
			$steppablePipeline.Process($Header)
			$steppablePipeline.End()
		}

        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
      }
    } catch {
        throw
    }    
  }
  end
  {
    try {
      $steppablePipeline.End()
    } catch {
      throw
    }
  }
}


## Bonus: the log rotation logic as a stand alone function...
function Rotate-Log {
  #.Synopsis
  #   Rotate a log file if it's gotten too big
  [CmdletBinding()]
  param(
    # The file of the path to test and rotate
    [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory=$true, Position=0)]
    [Alias("PSPath")]
    $FilePath,

    # When a log file goes over this size, rotate it
    $SizeLimit = 10MB,

    # How many backup logs (besides the primary log file) to keep
    $LogLimit  = 5
  )
  process {
    foreach($LogFile in Resolve-Path $FilePath) {
      # If the file triggers rotation:
      if(($file = Get-Item $LogFile) -and $file.Length -gt $SizeLimit) {
        # Remove the last item if it would go over the limit
        if(Test-Path "$LogFile.$LogLimit") { Remove-Item "$LogFile.$LogLimit" }
        foreach($i in $LogLimit..1) {
          if(test-path "$LogFile.$($i-1)") {
            Move-Item "$LogFile.$($i-1)" "$LogFile.$i"
          }
        }
        Move-Item $LogFile "$LogFile.$i"
        $null = New-Item $LogFile -Type File
      }
    }
  }
}

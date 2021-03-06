#requires -version 2.0
Set-Alias od Get-HexDump

function Get-HexDump {
  [CmdletBinding(DefaultParameterSetName="FileName", SupportsShouldProcess=$true)]
  param(
    [Parameter(Mandatory=$true,
               Position=0,
               ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$FileName,
    
    [Parameter(Mandatory=$false,
               Position=1)]
    [ValidateRange(0, 65535)]
    [Int32]$BytesToProcess = -1
  )
  
  begin {
    $ofs = ''
    [Int32]$line = 0
  }
  process {
    switch ((Test-Path $FileName)) {
      $true{
        if ($PSCmdlet.ShouldProcess($FileName, "Get hex dump of")) {
          gc -ea 0 -enc Byte $FileName -re 16 -to $BytesToProcess | % {
            '{0:X8} {1, -49} {2}' -f $line++, [String](
              $_ | % {' ' + ('{0:x}' -f $_).PadLeft(2, "0")}
            ), [String](
              $_ | % {
                if ([Char]::IsLetterOrDigit($_) -or [Char]::IsSymbol($_) `
                  -or [Char]::IsPunctuation($_)) {[Char]$_}
                else {'.'}
              }
            )
          }
        }
      }
      default{Write-Warning "file not found or does not exist."}
    }
  }
  end {}
}

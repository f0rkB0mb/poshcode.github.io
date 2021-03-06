#==============================================================================================
# Usage:
#  tail -f foo     -  watch for changes of foo
#  tail foo -n 25  -  show last 25 lines of foo
#
# Report me about bugs on gregzakh@gmail.com (my account on twitter not accessible any more)
#==============================================================================================

Set-Alias tail Get-FileTail

function Get-FileTail {
  [CmdletBinding(SupportsShouldProcess=$true)]
  param(
    [Parameter(Mandatory=$true,
               ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$PathName,
    
    [Parameter(Mandatory=$false,
               ValueFromPipeline=$false)]
    [Int64]$NumberOfLines = 10,
    
    [Parameter(Mandatory=$false,
               ValueFromPipeline=$false)]
    [Text.Encoding]$Encoding = [Text.Encoding]::Default,
    
    [Parameter(Mandatory=$false,
               ValueFromPipeline=$false)]
    [String]$Delims = "`r`n",
    
    [Parameter(Mandatory=$false,
               ValueFromPipeline=$false)]
    [Switch]$FlagOnWatch = $false
  )
  
  begin {
    function str_tail([String]$path, [Int64]$tokens, [Text.Encoding]$enc, [String]$delims) {
      [Int32]$szChar = $enc.GetByteCount("`n")
      [Byte[]]$buff = $enc.GetBytes($delims)
      
      try {
        $fs = New-Object IO.FileStream($path, [IO.FileMode]::Open)
        [Int64]$tknCount = 0
        [Int64]$endReads = $fs.Length / $szChar
        
        for ([Int64]$pos = $szChar; $pos -lt $endReads; $pos += $szChar) {
          [void]$fs.Seek(-$pos, [IO.SeekOrigin]::End)
          [void]$fs.Read($buff, 0, $buff.Length)
          
          if ($enc.GetString($buff) -eq $delims) {
            $tknCount++
            if ($tknCount -eq $tokens) {
              [Byte[]]$retBuff = New-Object Byte[]($fs.Length - $fs.Position)
              [void]$fs.Read($retBuff, 0, $retBuff.Length)
              return $enc.GetString($retBuff)
            }
          }
        }
        
        $fs.Seek(0, [IO.SeekOrigin]::Begin)
        $buff = New-Object Byte[] $fs.Length
        [void]$fs.Read($buff, 0, $buff.Length)
        return $enc.GetString($buff)
      }
      finally {
        $fs.Close()
      }
    }
  }
  process {
    switch ((Test-Path $PathName)) {
      $true{
        switch ($FlagOnWatch) {
          $true{
            if ($PSCmdlet.ShouldProcess("Watch for changes in " + $PathName)) {cat $PathName -Wait}
          }
          $false{
            if ($PSCmdlet.ShouldProcess("Reads last N strings of " + $PathName)) {
              str_tail $PathName $NumberOfLines $Encoding $Delims
            }
          }
        }
      }
      $false{
        throw "Probably file " + $PathName + " does not exist."
      }
    }
  }
  end {}
}

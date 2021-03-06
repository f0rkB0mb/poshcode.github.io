#requires -version 2.0
Set-Alias strings Get-Strings

function Get-Strings {
  <#
    .NOTES
        Author: greg zakharov
  #>
  [CmdletBinding(DefaultParameterSetName="FileName")]
  param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateScript({Test-Path $_})]
    [String]$FileName,
    
    [Alias("b")]
    [UInt32]$BytesToProcess = 0,
    
    [Alias("f")]
    [UInt32]$BytesOffset = 0,
    
    [Alias("n")]
    [UInt32]$StringLength = 3,
    
    [Alias("o")]
    [Switch]$StringOffset,
    
    [Alias("u")]
    [Switch]$Unicode
  )
  
  begin {
    $FileName = cvpa $FileName
    
    switch ($Unicode) {
      $true   {$enc = [Text.Encoding]::Unicode}
      default {$enc = [Text.Encoding]::UTF7}
    }
    
    function get([Byte[]]$Bytes) {
      ([Regex]"[\x20-\x7E]{$StringLength,}").Matches(
        $enc.GetString($Bytes)
      ) | % {if ($StringOffset) {'{0}: {1}' -f $_.Index, $_.Value} else {$_.Value}}
    }
  }
  process {
    try {
      $fs = [IO.File]::OpenRead($FileName)
      #offset
      if ($BytesOffset -ge $fs.Length) {
        throw (New-Object IO.IOException("Out of stream."))
      }
      else {[void]$fs.Seek($BytesOffset, [IO.SeekOrigin]::Begin)}
      #bytes process
      if ($BytesToProcess -gt 0) {
        $buf = New-Object "Byte[]" ($fs.Length - ($fs.Length - $BytesToProcess))
      }
      else {$buf = New-Object "Byte[]" $fs.Length}
      [void]$fs.Read($buf, 0, $buf.Length)
      get $buf
    }
    catch [IO.IOException] {Write-Host $_.Exception.Message -fo Red}
    finally {
      if ($fs -ne $null) {$fs.Close()}
    }
  }
  end {''}
}

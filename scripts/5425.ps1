#requires -version 2.0
Set-Alias junction Set-JunctionPoint

$script:ini = @'
[.ShellClassInfo]
CLSID2={0AFACED1-E828-11D1-9187-B532F1E9575D}
'@

function Set-JunctionPoint {
  <#
    .SYNOPSIS
        Create junction point for specified directory.
    .DESCRIPTION
        This technique works well on Win2k3 system and has not been tested
        on higher versions of Windows systems (if it works then let me know
        please).
    .EXAMPLE
        PS C:\> junction C:\junction "D:\Documents and Settings\User\Images"
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateScript({-not (Test-Path $_)})]
    [String]$JunctionPoint,
    
    [Parameter(Mandatory=$true, Position=1)]
    [ValidateScript({Test-Path $_})]
    [String]$TargetFolder
  )
  
  begin {
    function Add-File([String]$File) {
      return (Join-Path $JunctionPoint $File)
    }
  }
  process {
    [void](ni $JunctionPoint -Type Directory)
    if (!(Test-Path $JunctionPoint)) {
      Write-Warning "could not create junction point."
      break
    }
    
    Out-File (Add-File Desktop.ini) -InputObject $ini -Encoding ASCII
    
    $wsh = New-Object -ComObject WScript.Shell
    $lnk = $wsh.CreateShortcut((Add-File target.lnk))
    $lnk.TargetPath = $(cvpa $TargetFolder)
    $lnk.Save()
    
    attrib +s $JunctionPoint /s /d
  }
  end {}
}

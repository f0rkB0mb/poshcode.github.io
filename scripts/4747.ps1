Set-Alias gmt Get-MachineType

function Get-MachineType {
  param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [String]$FileName
  )
  
  begin {
    #machine and PE pointer offsets
    $mo = 4; $po = 60
    
    $MachineType = @{0x0 = 'Native'; 0x14c = '32-bit'; 0x200 = 'Itanium'; 0x8664 = '64-bit'}
    
    $raw = New-Object "Byte[]" 1024
    $itm = cvpa $FileName
  }
  process {
    try {
      $fs = New-Object IO.FileStream($itm, [IO.FileMode]::Open, [IO.FileAccess]::Read)
      [void]$fs.Read($raw, 0, 1024)
    }
    catch {
      if ($fs -ne $null) {$fs.Close()}
    }
    $res = '0x{0:x}' -f [BitConverter]::ToInt16($raw, ([BitConverter]::ToInt32($raw, $po) + $mo))
  }
  end {
    Write-Host $itm':' -fo Yellow
    Write-Host "`tMachineType: " -no
    Write-Host $MachineType[[Int32]$res] -fo Magenta
  }
}

Set-Alias hex2dec Convert-Hex2Dec

function Convert-Hex2Dec {
  <#
    .LINK
        Follow me on twitter @gregzakharov
  #>
  param(
    [Parameter(Mandatory=$true,
               ValueFromPipeline=$true)]
    [String]$Number
  )
  
  if ($Number.Substring(0, 1) -eq 'x') {
    '0x{0} = {1}' -f $Number.Substring(1, $Number.Length - 1).ToUpper(), [Int32]('0' + $Number)
  }
  elseif ($Number.Substring(0, 2) -eq '0x') {
    '0x{0} = {1}' -f $Number.Substring(2, $Number.Length - 2).ToUpper(), [Int32]$Number
  }
  else {
    $arr = $Number.ToCharArray() | % {[Char]::IsDigit($_)}
    $pos = [Array]::LastIndexOf($arr, 'False')
    
    if ($arr[$pos]) {
      '{0} = 0x{1:X}' -f $Number, [Int32]$Number
    }
    else {
      try {'0x{0} = {1}' -f $Number.ToUpper(), [Int32]('0x' + $Number)} catch {}
    }
  }
}

#Examples:
#PS C:\> hex2dec 23
#23 = 0x17
#PS C:\> hex2dec x17
#x17 = 23
#PS C:\> hex2dec 0xff
#0xFF = 255
#PS C:\> hex2dec fa
#0xFA = 250

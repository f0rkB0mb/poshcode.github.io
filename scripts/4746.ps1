Set-Alias mfdump  Get-Manifest
Set-Alias strings Get-Strings

function Get-Manifest {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true,
               Position=0,
               ValueFromPipeline=$true)]
    [ValidateScript({Test-Path $_})]
    [String[]]$PathName
  )
  
  $PathName | % {
    [String]$man = Get-Strings $_ -s 125 | ? {$_ -match '\<assembly'}
    [RegEx]::Replace((-join $man[0..$man.LastIndexOf('>')]), '\>\s', '>$').Split('$')
  }
}

function Get-Strings {
  [CmdletBinding(DefaultParameterSetName="PathName")]
  param(
    [Parameter(Mandatory=$true,
               Position=0,
               ValueFromPipeline=$true)]
    [ValidateScript({Test-Path $_})]
    [String[]]$PathName,
    
    [UInt32]$StringLength = 3,
    
    [ValidateSet('Ascii', 'Unicode')]
    [String]$Encoding = 'Ascii'
  )
  
  $PathName | % {
    if ($Encoding -eq 'Ascii') {
      ([RegEx]"[\x20-\x7E]{$StringLength,}").Matches((cat -enc UTF7 $_)) | % {$_.Value}
    }
    elseif ($Encoding -eq 'Unicode') {
      ([RegEx]"[\u0020-\u007E]{$StringLength,}").Matches((cat -enc Unicode $_)) | % {$_.Value}
    }
  }
}

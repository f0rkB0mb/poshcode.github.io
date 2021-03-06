function Test-Hash { 
#.Synopsis
#   Test the HMAC hash(es) of a file
#.Description
#   Takes the HMAC hash of a file using specified algorithm, and optionally, compare it to a baseline hash
#.Example
#   C:\PS>ls .\Bin\Release -recurse | Test-Hash -BasePath .\Bin\Release -Type SHA256 | Export-CSV ~\Hashes.csv
#   C:\Program Files\MyProduct>Import-CSV ~\Hashes.csv | Test-Hash
#
#   This example shows how to take the hash of a collection of files and store them in a csv file, and then later verify that the files in a secondary location match the originals exactly.
#
#.Example
#   Test-Hash npp.5.3.1.Installer.exe -HashFile npp.5.3.1.release.md5
# 
#   Searches the provided hash file for a line matching the "npp.5.3.1.Installer.exe" file name
#   and take the hash of the file (using the extension of the HashFile as the Type of Hash).
#
#.Example
#   Test-Hash npp.5.3.1.Installer.exe 360293affe09ffc229a3f75411ffa9a1 MD5
#
#   Takes the MD5 hash and compares it to the provided hash
#
#.Example
#   Test-Hash npp.5.3.1.Installer.exe 5e6c2045f4ddffd459e6282f3ff1bd32b7f67517 
#
#   Tests all of the hashes against the provided (Sha1) hash
[CmdletBinding(DefaultParameterSetName="NoExpectation")]
PARAM(
   # The path to the file to hash
   [Parameter(Position=0,Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
   [Alias("PSPath")]
   [string]$Path,
   
   # When hashing many files in folders, use this to convert to relative paths (so you can compare again in a different location)
   [Parameter(Position=2,Mandatory=$false,ParameterSetName="NoExpectation")]
   [string]$BasePath,
   
   # Supports hashing against a .md5 or .sha1 file such as frequently found on open source servers or torrent sites
   [Parameter(Position=1,Mandatory=$true,ParameterSetName="FromHashFile")]
   [string]$HashFileName,
   
   # Supports passing in the expected hash (particularly useful when piping input from a previous run)
   [Parameter(Position=2,Mandatory=$true,ParameterSetName="ManualHash", ValueFromPipelineByPropertyName=$true)]
   [Parameter(Position=2,Mandatory=$false,ParameterSetName="FromHashFile")]
   [ALias("Hash")]
   [string]$ExpectedHash = $(if($HashFileName){  ((Get-Content $HashFileName) -match $Path)[0].split(" ")[0]  }),
   
   # The algorithm to use when hashing
   [Parameter(Position=1,Mandatory=$true,ParameterSetName="ManualHash", ValueFromPipelineByPropertyName=$true)]
   [Parameter(Position=1,Mandatory=$false,ParameterSetName="NoExpectation")]
   [ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
   [string[]]$Algorithm = $(if($HashFileName){ [IO.Path]::GetExtension((Convert-Path $HashFileName)).Substring(1) } else { "SHA256" })
)

begin {
   $ofs=""
   if($BasePath) {
      Push-Location $BasePath
   }
}  

process {
   if($BasePath) {
      $Path = Resolve-Path $Path -Relative
   }
   if(Test-Path $Path -Type Container) {
      # I'd like to support recursing all the files, but for now, just skip
      Write-Warning "Cannot calculate hash for directories: '$Path'"
      return
   }

   $Hashes = @(
      foreach($Type in $Algorithm) {
         # Take the Hash without storing the bytes (ouch)
         [string]$hash = [Security.Cryptography.HashAlgorithm]::Create( $Type ).ComputeHash( [IO.File]::ReadAllBytes( (Convert-Path $Path) ) ) | ForEach { "{0:x2}" -f $_ }
         # Output an object with the hash, algorithm and path
         New-Object PSObject -Property @{ Path = $Path; Algorithm = $Type; Hash = $Hash }
      }
   )

   if($ExpectedHash) {
      # Check all the hashes to see if any of them match
      if( $Match = $Hashes | Where { $_.Hash -eq $ExpectedHash } ) {
         Write-Verbose "Matched hash:`n$($Match | Out-String)"
         # Output an object with the hash, algorithm and path
         New-Object PSObject -Property @{ Path = $Match.Path; Algorithm = $Match.Algorithm; Hash = $Match.Hash; Matches = $True }
      } else {
         Write-Verbose "Failed to match hash:`n$($PSBoundParameters | Out-String)"
         # Output an object with the first hash, algorithm and path
         New-Object PSObject -Property @{ Path = $Hashes[0].Path; Algorithm = $Hashes[0].Algorith; Hash = $Hashes[0].Hash; Matches = $False }
      }         
   } else {
      Write-Output $Hashes  
   }
}
end {  
   if($BasePath) {
      Pop-Location
   }
}
}

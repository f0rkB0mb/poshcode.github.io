## Start-Encryption
##################################################################################################
## Rijndael symmetric key encryption ... with no passes on the key. Very lazy.
## USAGE:
## $encrypted = Encrypt-String "Oisin Grehan is a genius" "P@ssw0rd"
## Decrypt-String $encrypted "P@ssw0rd"
##
## You can choose to return an array by passing -arrayOutput to Encrypt-String
## I chose to use Base64 encoded strings because they're easier to save ...

[Reflection.Assembly]::Load("System.Security, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")

function Encrypt-String($String, $Passphrase, $salt="My Voice is my P455W0RD!", $init="Yet another key", [switch]$arrayOutput)
{
   $r = new-Object System.Security.Cryptography.RijndaelManaged
   $pass = [Text.Encoding]::UTF8.GetBytes($Passphrase)
   $salt = [Text.Encoding]::UTF8.GetBytes($salt)

   $r.Key = (new-Object Security.Cryptography.PasswordDeriveBytes $pass, $salt, "SHA1", 5).GetBytes(32) #256/8
   $r.IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15]
   
   $c = $r.CreateEncryptor()
   $ms = new-Object IO.MemoryStream
   $cs = new-Object Security.Cryptography.CryptoStream $ms,$c,"Write"
   $sw = new-Object IO.StreamWriter $cs
   $sw.Write($String)
   $sw.Close()
   $cs.Close()
   $ms.Close()
   $r.Clear()
   [byte[]]$result = $ms.ToArray()
   if($arrayOutput) {
      return $result
   } else {
      return [Convert]::ToBase64String($result)
   }
}

function Decrypt-String($Encrypted, $Passphrase, $salt="My Voice is my P455W0RD!", $init="Yet another key")
{
   if($Encrypted -is [string]){
      $Encrypted = [Convert]::FromBase64String($Encrypted)
   }

   $r = new-Object System.Security.Cryptography.RijndaelManaged
   $pass = [System.Text.Encoding]::UTF8.GetBytes($Passphrase)
   $salt = [System.Text.Encoding]::UTF8.GetBytes($salt)

   $r.Key = (new-Object Security.Cryptography.PasswordDeriveBytes $pass, $salt, "SHA1", 5).GetBytes(32) #256/8
   $r.IV = (new-Object Security.Cryptography.SHA1Managed).ComputeHash( [Text.Encoding]::UTF8.GetBytes($init) )[0..15]

   $d = $r.CreateDecryptor()
   $ms = new-Object IO.MemoryStream @(,$Encrypted)
   $cs = new-Object Security.Cryptography.CryptoStream $ms,$d,"Read"
   $sr = new-Object IO.StreamReader $cs
   Write-Output $sr.ReadToEnd()
   $sr.Close()
   $cs.Close()
   $ms.Close()
   $r.Clear()
}

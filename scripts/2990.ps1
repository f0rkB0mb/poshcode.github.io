#requires -Version 3.0
function Join-Hashtable {
param(
   [Hashtable]$First,
   [Hashtable]$Second,
   [Switch]$Force
)
   $Firsts = $First.Keys
   $Output = @{} + $First
   
   foreach($key in $Second.Keys) {
      if($Firsts -notcontains $Key) {
         $Output.$Key = $Second.$Key
      } elseif($Force) {
         $Output.$Key = $Second.$Key
      }
   }
   $Output
}

function Export-DefaultParameterValues {
param(
   $Path = "DefaultParameterValues.ps1xml",
   [Switch]$AllUsers
)
   if((Split-Path $Path -Leaf) -eq $Path) {
      if($AllUsers) {
         $Path = Join-Path (Split-Path $Profile.AllUsersAllHosts) $Path
      } else {
         $Path = Join-Path (Split-Path $Profile.CurrentUserAllHosts) $Path
      }
   }
   Export-Clixml -InputObject $PSDefaultParameterValues -Path $Path
}

function Import-DefaultParameterValues {
param(
   $Path = "DefaultParameterValues.ps1xml",
   [Switch]$AllUsers,
   [Switch]$Force
)
   if((Split-Path $Path -Leaf) -eq $Path) {
      if($AllUsers) {
         $Path = Join-Path (Split-Path $Profile.AllUsersAllHosts) $Path
      } else {
         $Path = Join-Path (Split-Path $Profile.CurrentUserAllHosts) $Path
      }
   }
   if($PSDefaultParameterValues.Count -eq 0) {
      $Global:PSDefaultParameterValues = Import-Clixml -Path $Path
   } else {
      $PSD = Import-Clixml -Path $Path

      $Global:PSDefaultParameterValues = Join-Hashtable $PSDefaultParameterValues $PSD -Force:$Force
   }
}


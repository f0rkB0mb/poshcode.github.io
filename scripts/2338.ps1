$primes = 2,3,5 #,7,11,13,17,19,23
$primeIndex = 0
function Get-NextPrime {
   [CmdletBinding(DefaultParameterSetName="KnownPrime")]
   param(
      [Parameter(Position=0,ParameterSetName="KnownPrime")]
      $knownPrime = $(if($primeIndex -lt $primes.Count){ $primes[$primeIndex] } else { $primes[-1] } )
   , 
      [Parameter(ParameterSetName="FromTwo")]
      [switch]$reset
   )
   ## Hack: to allow you to start over at 2, even though we cache the values, 
   ##       we keep a primeIndex, and just reset it to -1
   if($reset) { 
      $global:primeIndex = -1 
   } elseif($PSBoundParameters.ContainsKey("KnownPrime")){
      ## Hack: allow you to specify any number to start at:
      $global:primeIndex = [array]::BinarySearch($primes,$knownPrime)
      if($primeIndex -lt 0) { 
         Write-Verbose "We don't have a prime like $knownPrime"
         $primeIndex = (-1 * $primeIndex) -1
      } else {
         Write-Verbose "Looking for the first prime LARGER than $($primes[$primeIndex])"
         $global:primeIndex += 1
      }
   }
   
   Write-Verbose "Looking for a prime gt $knownPrime at index $primeIndex"
   ## If we have a cached "next" value, return that
   if($primeIndex -lt $primes.Count) {
      $primes[$primeIndex]
      $global:primeIndex += 1
      return 
   }
   
   ## Otherwise, calculate the next largest prime by ...
   ## checking every number greater than the current largest prime
   $p = $primes[-1]
   while($p = $p+2){
      ## To see if they're divisible by any known prime
      if(!$(
         foreach($i in $primes){ if($p % $i -eq 0) { $i } }
      )){
         ## If they're not, then they're a new prime. Cache them, and return
         $global:primes += $p
         $global:primeIndex += 1
         if($p -gt $knownPrime) {
            return $p
         }
      }
   }
}


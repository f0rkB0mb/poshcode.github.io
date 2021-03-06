function Restart-IISAppPool {
   [CmdletBinding(SupportsShouldProcess=$true)]
   #.Synopsis
   #  Restarts an IIS AppPool
   #.Parameter ComputerName
   #  The name of a web server to restart the AppPool on
   #.Parameter Pool
   #  The name of the AppPool to recycle (if you include wildcards, results in an initial call to list all app pools)
   param(
      [Parameter(ValueFromPipelineByPropertyName=$true)]
      [Alias("CN","Server","__Server")]
      [String]$ComputerName
   ,
      [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory= $true)]
      [Alias("Name","Pool")]
      [String[]]$AppPool
   ,
      [Parameter()]
      [System.Management.Automation.Credential()]
      $Credential = [System.Management.Automation.PSCredential]::Empty
   )
   
   begin {
      if ($Credential -and ($Credential -ne [System.Management.Automation.PSCredential]::Empty)) {
         $Credential = $Credential.GetNetworkCredential()
      }
      Write-Debug ("BEGIN:`n{0}" -f ($PSBoundParameters | Out-String))

      $Skip = $false
      ## Need to test for AppPool existence (it's not defined in BEGIN if it's piped in)
      if($PSBoundParameters.ContainsKey("AppPool") -and $AppPool -match "\*") {
        $null = $PSBoundParameters.Remove("AppPool")
        $null = $PSBoundParameters.Remove("WhatIf")
        $null = $PSBoundParameters.Remove("Confirm")

        Get-WmiObject IISApplicationPool -Namespace root\MicrosoftIISv2 -Authentication PacketPrivacy @PSBoundParameters | 
        Where-Object { @(foreach($pool in $AppPool){ $_.Name -like $Pool -or $_.Name -like "W3SVC/APPPOOLS/$Pool" }) -contains $true } |
        Restart-IISAppPool
        $Skip = $true
      }
      $ProcessNone = $ProcessAll = $false;
   }
   process {
      Write-Debug ("PROCESS:`n{0}" -f ($PSBoundParameters | Out-String))
   
      if(!$Skip) {
        $null = $PSBoundParameters.Remove("AppPool")
        $null = $PSBoundParameters.Remove("WhatIf")
        $null = $PSBoundParameters.Remove("Confirm")
         foreach($pool in $AppPool) {
            Write-Verbose "Restarting $Pool"
            if($PSCmdlet.ShouldProcess("Would restart the AppPool '$Pool' on the '$(if($ComputerName){$ComputerName}else{'local'})' server.", "Restart $AppPool?", "Restarting IIS App Pools on $ComputerName")) {
               # if($PSCmdlet.ShouldContinue("Do you want to restart $Pool?", "Restarting IIS App Pools on $ComputerName", [ref]$ProcessAll, [ref]$ProcessNone)) {
                 Invoke-WMIMethod Recycle -Path "IISApplicationPool.Name='$Pool'" -Namespace root\MicrosoftIISv2 -Authentication PacketPrivacy @PSBoundParameters
               # }
            }
         }
      }
   }

}
       

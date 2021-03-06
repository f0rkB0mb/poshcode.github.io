## This script requires ...\WindowsPowerShell\Libraries\Meebey.SmartIrc4net.dll
## You can get Meebey.SmartIrc4net.dll from 
## http://voxel.dl.sourceforge.net/sourceforge/smartirc4net/SmartIrc4net-0.4.0.bin.tar.bz2
## And the docs are at http://smartirc4net.meebey.net/docs/0.4.0/html/
############################################################################################
## Configure with a .psd1 file for the module, with Private data like:
## FunctionsToExport = 'Start-PowerBot', 'Resume-PowerBot', 'Stop-PowerBot'
## RequiredAssemblies = 'Meebey.SmartIrc4net.dll', 'Starksoft.Net.Proxy.dll'
## PrivateData = @{
##    Nick = @('ABot', 'PowershellBot')
##    RealName = 'Jaykul''s PowerShell Bot'
##    Pass = 'bot'
##    Server = "irc.freenode.net"
##    Port = 8001
##    Channels = @('#PowerShell')
## #  ProxyServer = "www.proxy.com"
## #  ProxyPort = "8000"
## }
############################################################################################
## Add-Type -path $ProfileDir\Libraries\Meebey.SmartIrc4net.dll
## $null = [Reflection.Assembly]::LoadFrom("$ProfileDir\Libraries\Meebey.SmartIrc4net.dll")

function Start-PowerBot {
[CmdletBinding()]
PARAM(
  [Parameter(Position=0)]
  [string[]]$channels = $ExecutionContext.SessionState.Module.PrivateData.Channels
,
  [Parameter(Position=1)]
  [string[]]$nick     = $ExecutionContext.SessionState.Module.PrivateData.Nick
,
  [Parameter(Position=2)]
  [string]$password   = $ExecutionContext.SessionState.Module.PrivateData.Password
,
  [Parameter(Position=5)]
  [string]$server     = $ExecutionContext.SessionState.Module.PrivateData.Server
,
  [Parameter(Position=6)]
  [int]$port          = $ExecutionContext.SessionState.Module.PrivateData.Port
,
  [Parameter(Position=10)]
  [string]$realname   = $ExecutionContext.SessionState.Module.PrivateData.RealName
,
  [Parameter(Position=5)]
  [string]$ProxyServer= $ExecutionContext.SessionState.Module.PrivateData.ProxyServer
,
  [Parameter(Position=6)]
  [int]$ProxyPort     = $ExecutionContext.SessionState.Module.PrivateData.ProxyPort
)

   Write-Host "Private Data:`n`n$( $ExecutionContext.SessionState.Module.PrivateData | Out-String )" -Fore Cyan
   Write-Host "Proxy Server: $ProxyServer, $ProxyPort" -Fore Yellow

   if(!$global:irc) {  
      $global:irc = New-Object Meebey.SmartIrc4net.IrcClient
      
      if($ProxyServer) {
         $global:proxy = New-Object Starksoft.Net.Proxy.HttpProxyClient $ProxyServer, $ProxyPort
         Write-Host "Creating Proxy: ${global:proxy}"
         $global:irc.Proxy = $global:proxy
      }
      # $irc.Encoding = [Text.Encoding]::UTF8
      # $irc will track channels for us
      $irc.ActiveChannelSyncing = $true   
      $irc.Add_OnError( {Write-Error $_.ErrorMessage} )
      $irc.Add_OnQueryMessage( {OnQueryMessage_ProcessCommands} )
      $irc.Add_OnChannelMessage( {OnChannelMessage_ProcessCommands} )
      $irc.Add_OnChannelMessage( {OnChannelMessage_ResolveUrls} )
   }
   
   $irc.Connect($server, $port)
   $irc.SendDelay = 300
   $irc.Login($nick, $realname, 0, $nick[0], $password)
   ## $channels | % { $irc.RfcJoin( $_ ) }
   foreach($channel in $channels) { $irc.RfcJoin( $channel ) }

   $global:PBC = Get-BotCommands

   Resume-PowerBot # Shortcut so starting this thing up only takes one command
}

## Note that PowerBot stops listening if you press a key ...
## You'll have to re-run Resume-Powerbot to get him to listen again
function Resume-PowerBot {
   while(!$Host.UI.RawUI.KeyAvailable) { $irc.Listen($false) }
}

function Stop-PowerBot {
[CmdletBinding()]
PARAM(
  [Parameter(Position=0)]
  [string]$QuitMessage = "If people listened to themselves more often, they would talk less."
)
   $irc.RfcQuit($QuitMessage)
   sleep 2
   $irc.Disconnect()
}


function Resolve-Parameters {
Param($command)
   $Tokens = [System.Management.Automation.PSParser]::Tokenize($command,[ref]$null)
   for($t = $Tokens.Count; $t -ge 0; $t--) {
      # DEBUG $token | fl * | out-host
      if($Tokens[$t].Type -eq "CommandParameter") {
         $token = $Tokens[$t]
         for($c = $t; $c -ge 0; $c--) {
            if( $Tokens[$c].Type -eq "Command" ) {
               $cmd = which $Tokens[$c].Content
               # if($cmd.CommandType -eq "Alias") {
                  # $cmd = @(which $cmd.Definition)[0]
               # }
               $short = $token.Content -replace "^-?","^"
               Write-Debug "Parameter $short"
               $parameters = $cmd.ParameterSets | Select -expand Parameters
               $param = @($parameters | Where-Object { $_.Name -match $short -or $_.Aliases -match $short} | Select -Expand Name -Unique)
               if("Verbose","Debug","WarningAction","WarningVariable","ErrorAction","ErrorVariable","OutVariable","OutBuffer","WhatIf","Confirm" -contains $param ) {
                  $command = $command.Remove( $token.Start, $token.Length )
               } elseif($param.Count -eq 1) {
                  $command = $command.Remove( $token.Start, $token.Length ).Insert( $token.Start, "-$($param[0])" )
               }
               break
            }
         }
      }
   }
   return $command
}

function Bind-Parameters {
Param([string[]]$params)
   $bound = @{}
   $unbound = @()

   while($params) {
      Write-Host "$params"
      [string]$name, [string]$value, $params = @($params)
      if($name.StartsWith("-")) {
         $name = $name.trim("-"," ")
         if($value.StartsWith("-")) {
            $bound[$name.trim("-"," ")] = New-Object System.Management.Automation.SwitchParameter $true
            $params = @($value) + $params
         } else {            
            $bound[$name] = $value      
         }
      } else {
         $unbound += "$name"
         if($value) {
            $params = @($value) + $params
         }
      }
   }
   $bound, $unbound
}

####################################################################################################
## Event Handlers
####################################################################################################
## Event handlers in powershell have TWO automatic variables: $This and $_
##   In the case of SmartIrc4Net:
##   $This  - usually the connection, and such ...
##   $_     - the IrcEventArgs, which just has the Data member:
##

function OnQueryMessage_ProcessCommands { 
   $Data = $_.Data
   Write-Verbose $Data.From
   # Write-Verbose $Data.Message
   Write-Debug $( $Data | Out-String )
   # Write-Debug $( $Data | Get-Member | Out-String )
   
   $command, $params = $Data.MessageArray
   Write-Verbose "`nCommand: $command `nParams: $params"
   if($PBC.ContainsKey($command)) {
      $Command, $Params = (Resolve-Parameters $((@($command) + @($Params)) -join " ")) -split " +"
      $bound, $unbound = Bind-Parameters @($params)
      trap { Write-Error "Error in ProcessCommands:`n$($_|out-string)"; Continue }
      Write-Debug "$Data | `&$($PBC[$command]) $bound $unbound"
      $Data | &$PBC[$command] @bound @unbound | 
         Out-String -width (510 - $Data.From.Length - $nick.Length - 3) | 
            % { $_.Trim().Split("`n") | %{ $irc.SendMessage("Message", $Data.Nick, $_.Trim() ) }}
   }
}

function OnChannelMessage_ProcessCommands {
   $Data = $_.Data
   Write-Verbose $Data.From
   # Write-Verbose $Data.Channel
   # Write-Verbose $Data.Message   
   Write-Debug $($Data | Out-String)
   # Write-Debug $($Data | Get-Member | Out-String)
   
   [string]$command, [string[]]$params = $Data.MessageArray
   if($PBC.ContainsKey($command)) {
      $Command, $Params = (Resolve-Parameters $((@($command) + @($Params)) -join " ")) -split " +"
      $bound, $unbound = Bind-Parameters @params
      trap { Write-Error "Error in ProcessCommands:`n$($_|out-string)"; Continue }
      Write-Debug "$Data | `&$($PBC[$command]) $bound $unbound"
      $Data | &$PBC[$command] @bound @unbound |
         Out-String -width (510 - $Data.Channel.Length - $nick.Length - 3) | 
            % { $_.Trim().Split("`n") | %{ $irc.SendMessage("Message", $Data.Channel, $_.Trim() ) }}
   }
}

function OnChannelMessage_ResolveUrls {
   $c = $_.Data.Channel
   $n = $_.Data.Nick
   $m = $_.Data.Message
   Resolve-URL $m | % { $irc.SendMessage("Message", $c, "<$($n)> $_" ) }

}


Import-Module "$PSScriptRoot\PowerBotCommands.psm1" -Force


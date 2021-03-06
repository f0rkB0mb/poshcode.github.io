##########################################################################################
## Depends on the PsXmppHelper.dll from http://CodePlex.com/PowerXmpp
## CONTAINS Read-HostMasked http://powershellcentral.com/scripts/104
## CONTAINS Out-Working http://powershellcentral.com/scripts/105
##########################################################################################
## NOTICE: THERE IS WAY TOO LITTLE ERROR HANDLING HERE!!!! 
## IF EVERYTHING does not go very well, you will likely get very little explanation
## MAKE SURE YOU ARE USING a registered jabber id and password

##########################################################################################
## Read-HostMasked
## See: http://powershellcentral.com/scripts/104
function Read-HostMasked([string]$prompt="Password") {
  $password = Read-Host -AsSecureString $prompt; 
  $BSTR = [System.Runtime.InteropServices.marshal]::SecureStringToBSTR($password);
  $password = [System.Runtime.InteropServices.marshal]::PtrToStringAuto($BSTR);
  [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR);
  return $password;
}

##########################################################################################
## Out-Working
## See: http://powershellcentral.com/scripts/105
$fore="White"; $back="red";
$work = @( $Host.UI.RawUI.NewBufferCellArray(@("|"),$fore,$back),
           $Host.UI.RawUI.NewBufferCellArray(@("/"),$fore,$back),
           $Host.UI.RawUI.NewBufferCellArray(@("-"),$fore,$back),
           $Host.UI.RawUI.NewBufferCellArray(@("\"),$fore,$back) );

[int]$script:w = 0;

filter out-working($wait=0) {
   $cur = $Host.UI.RawUI.Get_CursorPosition(); 
   $cur.X = 0; $cur.Y -=1;
   $Host.UI.RawUI.SetBufferContents($cur,$work[$script:w++]);
   if($script:w -gt 3) {$script:w = 0 }
   Start-Sleep -milli $wait
   $_
}

##########################################################################################
## Start-IrcJabberBridge - an Xmpp script
## Depends on the PsXmppHelper.dll from http://CodePlex.com/PowerXmpp
##
function Start-IRCJabberBridge {
   param (
      $From = $( Read-Host "Your Jabber ID" )
      ,$Password = $( Read-HostMasked "Password")
      ,$Message = $( Read-Host "Your Message!" )
      ,$To = $( Read-Host "Recipient's Jabber ID" )
      ,$Chat = "PowerShell%irc.FreeNode.net@irc.im.flosoft.biz"   # An IRC channel to join!
      ,$ChatNick = "PowerBot" # Your nickname in IRC
      ,$ChatPassword = $null
   )

   # Set path appropriately...
   [reflection.assembly]::LoadFrom( "agsXMPP.dll" ) | fl Location, FullName, GlobalAssemblyCache
   [reflection.assembly]::LoadFrom( "PsXmppHelper.dll" ) | fl Location, FullName, GlobalAssemblyCache
   
   $jidSender        = New-Object agsxmpp.jid $From
   $jidChat          = New-Object agsxmpp.jid $chat
   $jidReceiver      = New-Object agsxmpp.jid $To 
   
   $xmpp             = New-Object agsxmpp.XmppClientConnection( [string]$jidSender.Server )

   ## Use SRV lookups to determine correct XMPP server if different from the server
   ## portion of your JID.  e.g. user@gmail.com, the server is really talk.google.com
   # $xmpp.AutoResolveConnectServer     = $TRUE
   $xmpp.SocketConnectionType = [agsXMPP.net.SocketConnectionType]::HttpPolling;
   $xmpp.ConnectServer = "http://im.flosoft.biz:5280/http-poll/";

   # Since this function is only used to send a message, we don't care about doing the 
   # normal discovery and requesting a roster.  Leave disabled to quicken the login period.
   $xmpp.AutoAgents  = $false
   $xmpp.AutoRoster  = $false
   
   # The following switches may assist in troubleshooting connection issues.
   # If SSL and StartTLS are disabled, then you can use a network sniffer to inspect the XML
   #$xmpp.UseSSL      = $false
   #$xmpp.UseStartTLS = $false

   ### SOME CONSTANTS
   $MSG  = "agsXMPP.protocol.client.Message"
   $ChatMessage  = [agsXMPP.protocol.client.MessageType]::chat
   $GroupMessage = [agsXMPP.protocol.client.MessageType]::groupchat
   
   $queue = New-Object PsXmppClient.MessageQueue $xmpp
   $muc   = New-Object agsXMPP.protocol.x.muc.MucManager   $xmpp

   # Connect and wait ...
   $xmpp.Open($jidSender.User, $Password)
   while ( !$xmpp.Authenticated ) {
      Write-Verbose ("{0} - {1}" -f $xmpp.XmppConnectionState, $xmpp.Authenticated )
      [Threading.Thread]::Sleep(200)
   }
   Write-Verbose ("{0} - {1}" -f $xmpp.XmppConnectionState, $xmpp.Authenticated )
         
   # Set our status so we're visible
   $xmpp.Show = "chat"
   $xmpp.Status = "I'm a PowerShell Bot"
   $xmpp.SendMyPresence()
   
   # Join the chat room (the same as "SendMyPresence", except to a MUC)
   $muc.JoinRoom($jidChat, $ChatNick, $ChatPassword)

   # Send the initial message
   $xmpp.Send((New-Object $MSG $jidReceiver, $ChatMessage, $Message))
   
   $counter = 0
   "  Press any key to continue"
   while (!$Host.UI.RawUI.KeyAvailable)
   {
      foreach ($m in $queue.Messages)
      {
         " <{0}> {1}" -f $m.From.Resource, $m.Body
         if ($m.From.Bare -eq $To)
         {
            $xmpp.Send((New-Object $MSG $jidChat, $GroupMessage, $M.Body))
         }
         else
         {
            ## "{0}=={1}" -f $m.From.Bare,$To
            $xmpp.Send((New-Object $MSG $jidReceiver, $ChatMessage, ("<{0}> {1}" -f $m.From.Resource, $m.Body)))
         }
      }
      $counter++

      # Every so often, re-broadcast our continued presence 
      # Over http polling, not doing this was causing vanishing problems...
      if(($counter % 50) -eq 0 ) {
         $xmpp.SendMyPresence()
         $muc.JoinRoom($jidChat, $ChatNick)
      }
      out-working 100
   }

   $muc.LeaveRoom($jidChat, $ChatNick);
   $xmpp.Close();
}

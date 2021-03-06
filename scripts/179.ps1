##########################################################################################
## Depends on PoshXmpp.dll from http://CodePlex.com/PowerXmpp
#requires -pssnapin PoshXmpp
##########################################################################################
# Start-AtomToChat PowerBot@im.flosoft.biz SuperBot -ChatNick PowerBot
param (
    $JabberId = $( Read-Host "Bot's Jabber ID" )
   ,$Password = $( Read-Host "Bot's Password" -asSecure)
   ,$AtomFeeds[] = @("http://groups.google.com/group/microsoft.public.windows.powershell/feed/atom_v1_0_topics.xml")
   ,$Chat = "PowerShell%irc.FreeNode.net@irc.im.flosoft.biz"     # An IRC channel to join!
   ,$ChatNick = $("PowerBot$((new-object Random).Next(0,9999))") # Your nickname in IRC
)
$ErrorActionPreference = "Stop"

$global:PoshXmppClient = 
PoshXmpp\New-Client $JabberId $Password # http://im.flosoft.biz:5280/http-poll/
PoshXmpp\Connect-Chat $Chat $ChatNick

$nnc = $global:LastNewsCheck = [DateTime]::Now.AddHours(-10) # start
$feedReader = new-object Xml.XmlDocument

"PRESS ANY KEY TO STOP"
while(!$Host.UI.RawUI.KeyAvailable) {
   "Checking feeds..."
   foreach($feed in $AtomFeeds) {
      $feedReader.Load($feed)
      for($i = $feedReader.feed.entry.count - 1; $i -ge 0; $i--) {
         $e = $feedReader.feed.entry[$i]
         if([datetime]$e.updated -gt $global:LastNewsCheck) {
            PoshXmpp\Send-Message $Chat $("{0} {1} (Posted at {2:hh:mm} by {3})" -f $e.title."#text",  $e.link.href,  [datetime]$e.updated, $e.author.name)
            [Threading.Thread]::Sleep( 1000 )
         }
      }
      if( [datetime]$feedReader.feed.entry[0].updated -gt $nnc ) {
         $nnc = [datetime]$feedReader.feed.entry[0].updated
      }
   }
   $global:LastNewsCheck = $nnc # the most recent item in any feed
   $counter = 0
   "PRESS ANY KEY TO STOP" # we're going to wait 10 * 60 seconds 
   while(!$Host.UI.RawUI.KeyAvailable -and ($counter++ -lt 600)) {
      [Threading.Thread]::Sleep( 1000 )
   }
}

$global:PoshXmppClient.Close()

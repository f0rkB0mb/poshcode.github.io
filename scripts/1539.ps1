$gadgetWindow = @{
   # Transparency, WindowStyle, and background work together 
   # to get rid of the standard window's chrome and make the window "irregular" shaped
   # that is, the window will be the shape of it's content.
   AllowsTransparency = $True
   WindowStyle = "None"
   Background = "Transparent"
   # Async means the window will keep running but PowerShell will return to the prompt
   Async = $True
   # Assuming you put something on your window, this will make the window draggable
   # It might get in the way of clicking on controls, so bear that in mind.
   On_MouseDown = { $this.DragMove() }
   # This makes a timer for you, based on the TITLE and TAG of the window
   On_SourceInitialized = { 

      $this.Tag = DispatcherTimer -Interval $this.Tag[0] -On_Tick $this.Tag[1]
      $this.Tag.Start()
   }
   # Stop that timer or it will just keep right on firing.
   On_Closing = {
      $this.Tag.Stop()
   }
}


## Example uses:
# Create a little clock that's always topmost ...
boots { label -fontsize 24 | tee -var global:clock } @gadgetWindow -Title "Clock" -Topmost -Tag "00:00:00.2", { $global:clock.Content = "$(Get-Date -f 'hh:mm:ss')" } 

# World's simplest weather report, updates every 5 minutes
$weatherUrl = "http`://weather.yahooapis.com/forecastrss?p={0}" -f 14586 # Must be a "woeid"
# To find your WOEID, browse or search for your city from the Weather home page. 
# The WOEID is the LAST PART OF the URL for the forecast page for that city. 

boots { Image -Stretch Uniform -Width 250 -height 180| tee -var global:weather } @gadgetWindow -Title "Weather" -Tag "00:05", 
      { $h = ([int](Get-Date -f hh)); if($h -gt 8 -and $h -lt 7){$dayOrNight = 'd'}else{$dayOrNight = 'n'}
        $code = ([xml](New-Object Net.WebClient).DownloadString($weatherUrl)).rss.channel.item.condition.code
        $global:Weather.Source = "http`://l.yimg.com/a/i/us/nws/weather/gr/{0}{1}.png" -f $code, $dayOrNight
      }

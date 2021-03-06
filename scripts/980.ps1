if(!(Get-Command New-BootsWindow -EA SilentlyContinue)) {
   Add-PsSnapin PoshWpf
   #Import-Module PowerBoots
   #Add-BootsContentProperty 'DataPoints', 'Series'
   [Void][Reflection.Assembly]::LoadFrom( (Convert-Path (Resolve-Path "~\Documents\WindowsPowershell\Libraries\WPFVisifire.Charts.dll")) )
   #Add-BootsFunction -Assembly "~\Documents\WindowsPowershell\Libraries\WPFVisifire.Charts.dll"
   #Add-BootsFunction ([System.Windows.Threading.DispatcherTimer])
}

if(Get-Command Ping-Host -EA SilentlyContinue) {
   $pingcmd = { (Ping-Host $args[0] -count 1 -Quiet).AverageTime }
} else {
   $pingcmd = { [int]([regex]"time=(\d+)ms").Match( (ping $args[0] -n 1) ).Groups[1].Value }
}

$global:onTick = {
Param($window=$global:pingWindow)
   Invoke-BootsWindow $window {
      try {
         foreach($s in $window.Content.Series.GetEnumerator()) {
            $ping = &$pingcmd $s.LegendText
            $points = $s.DataPoints
            foreach($dp in 0..$($points.Count - 1)) 
            {
               if(($dp+1) -eq $points.Count) {
                  $points[$dp].YValue = $ping
               } else {
                  $points[$dp].YValue = $points[$dp+1].YValue
               }
            }
         }
      } catch { 
         Write-Output $_
      }
   }
}

function Add-PingHost {
PARAM(
   [string[]]$target
,  [Visifire.Charts.RenderAs]$renderAs="Line"
,  [Windows.Window]$window = $global:pingWindow
,  [Switch]$Passthru
)
   if($Window) {
      Invoke-BootsWindow $Window { 
         foreach($h1 in $target) {
            Add-PingHostInternal $h1 $renderAs $window
         }
      }
      if($Passthru) { return $Window }
   } else {
      return New-PingMonitor $target $renderAs -Passthru:$Passthru
   }
}

function Add-PingHostInternal {
PARAM(
   [string]$target
,  [Visifire.Charts.RenderAs]$renderAs="Line"
,  [System.Windows.Window]$window = $global:pingWindow
)
   $start = $(get-random -min 10 -max 20)
   $ds    = New-Object Visifire.Charts.DataSeries
   $ds.LegendText = $target
   $ds.RenderAs   = $renderAs
   [void]$window.Content.Series.Add($ds)
   for($i=0;$i -lt 25;$i++) {
      $dp = New-Object Visifire.Charts.DataPoint
      $dp.YValue = $start
      [void]$ds.DataPoints.Add( $dp )
   }
}

function New-PingMonitor {
PARAM (
   [string[]]$hosts = $(Read-Host "Please enter the name of a computer to ping")
,  [Visifire.Charts.RenderAs]$renderAs="Line"
,  [Switch]$Passthru
) 
   $global:pingWindow = New-BootsWindow -Async {
      Param($window) # New-Boots passes the window to us ...
      Write-Debug "Window: $window"
      # Make a timer
      $timer          = New-Object System.Windows.Threading.DispatcherTimer
      $timer.Interval = "00:00:01.0"
      # Make a new scriptblock of the OnTick handle, passing it ourselves
      $tickover = ({ &$global:onTick $window }).GetNewClosure()
      $timer.Add_Tick( $tickover )
      # Stick the timer into the window....
      $window.Tag = @($timer, $tickover)
      
      # Make a chart
      $PingChart = New-Object Visifire.Charts.Chart
      $PingChart.Height    = 300 
      $PingChart.Width     = 800 
      $PingChart.watermark = $false 
      #$PingChart.Add_Initialized( {$timer.Start();} )
      
      # Make a bunch of data series
      $hosts | % { 
         $h1 = $_
         $start = $(get-random -min 10 -max 20)
         $ds    = New-Object Visifire.Charts.DataSeries
         $ds.LegendText = $h1
         $ds.RenderAs   = $renderAs
         $PingChart.Series.Add($ds)
         for($i=0;$i -lt 25;$i++) {
            $dp = New-Object Visifire.Charts.DataPoint
            $dp.YValue = $start
            $ds.DataPoints.Add( $dp )
         }
      }
      # we have to output the chart: whatever we output from here ends up in the window
      $PingChart
   } -On_ContentRendered {
      Write-Debug "Content Rendered. Tag: $($this.tag[0])"
      $this.tag[0].Start()
   } -On_Closing { 
      $this.tag[0].Remove_Tick($this.tag[1])
      $this.tag[0].Stop()
      $global:pingWindow = $null 
   } -Title "Ping Monitor" -Passthru
   
   if($Passthru) {
      return $global:pingWindow
   }
}

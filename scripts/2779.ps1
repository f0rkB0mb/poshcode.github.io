
function New-PowerChart() {
[CmdletBinding(DefaultParameterSetName='DataTemplate')]
param(
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateSet("Area","Bar","Bubble","Column","Line","Pie","Scatter")]
    [String[]]
    ${ChartType}
,
    [Parameter(Position=1, Mandatory=$true, HelpMessage='The data for the chart ...')]
    [System.Management.Automation.ScriptBlock[]]
    ${ItemsSource}
,
    [Parameter(Position=2, Mandatory=$true, HelpMessage='The property name for the independent values ...')]
    [String[]]
    ${IndependentValuePath}
,  
    [Parameter(Position=3, Mandatory=$true, HelpMessage='The property name for the dependent values ...')]
    [String[]]
    ${DependentValuePath}
,
    [Parameter(Position=4, HelpMessage='The property name for the size values ...')]
    [String[]]
    ${SizeValuePath}
,  
    [TimeSpan]    
    ${Interval}
,
    [Switch]
    $Show
)
begin
{
    Write-Host "Interval: $Interval"
    Chart -ControlNale PowerChart -Tag @{Interval=$Interval; ItemsSource=$ItemsSource} -On_Loaded {
        $Interval = $this.Tag.Interval
        if($Interval) {
            Register-PowerShellCommand -ScriptBlock {     
                $i=0
                $Window.Content.Series | ForEach{ $_.ItemsSource = &$($Window.Content.Tag.ItemsSource[$i++]) }
            } -in $Interval -run
        }
    } -Series {
      $Series = @()
      # Write-Host "Three" -Fore Cyan
      for($c=0; $c -lt $ChartType.length; $c++) {
         $chartType = $ChartType[$c].ToLower()
         if($SizeValuePath -and $ChartType[$c] -eq "Bubble") {
            $Series += iex "$($chartType)Series -DependentValuePath $($DependentValuePath[$c]) -IndependentValuePath $($IndependentValuePath[$c]) -SizeValuePath $($SizeValuePath[$c]) -ItemsSource `$(&{$($ItemsSource[$c])})" 
            #$Series[-1].DataPointStyle = $this.FindResource("$($chartType)DataPointTooltipsFix")
         } elseif($ChartType[$c] -eq "Pie") {
            $Series += iex "$($chartType)Series -DependentValuePath $($DependentValuePath[$c]) -IndependentValuePath $($IndependentValuePath[$c]) -ItemsSource `$(&{$($ItemsSource[$c])})"
            #$Series[-1].StylePalette = $this.FindResource("$($chartType)PaletteTooltipsFix")
         } else {
            Write-Verbose "$($chartType)Series -DependentValuePath $($DependentValuePath[$c]) -IndependentValuePath $($IndependentValuePath[$c]) -ItemsSource `$(&{$($ItemsSource[$c])})" 
            $Series += iex "$($chartType)Series -DependentValuePath $($DependentValuePath[$c]) -IndependentValuePath $($IndependentValuePath[$c]) -ItemsSource `$(&{$($ItemsSource[$c])})" 
            #A$Series[-1].DataPointStyle = $this.FindResource("$($chartType)DataPointTooltipsFix")
         }       
      }
      Write-Verbose "There are $($Series.Count) Series!"
      $Series
   } -Background Transparent -BorderThickness 0 -Show:$Show
}
}


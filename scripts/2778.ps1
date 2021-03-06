<#
.SYNOPSIS
Displays a Binary Coded Sexagesimal clock using the ShowUI module.

.DESCRIPTION
This clock displays time using three rows of blocks. The top row represents
hours, the middle is minutes and the bottom is seconds. Each of the six columns
represents a binary digit. The values for each digit in the order displayed 
are: 32 16 8 4 2 1. Adding the values of each of the "On" blocks in a row yields
the value for the row's corresponding time part.

Press the 'h' key to toggle the Helper values.
Press the 't' key to toggle the Time text.
Press the 'd' key to toggle the Date text.
Pres the '+'/'-' keys to resize the window (pressing Shift is not required).

Click and drag to move the window.
Double-click the window to close.

This script was inspired by Boe Prox's post at:
http://learn-powershell.net/2011/07/06/building-a-binary-clock-with-powershell/

.PARAMETER OnColor
The color of the "On" blocks which represent the 1 digits in a binary number.

This value must be able to convert to a System.Windows.Media.Brush type. (e.g.
"Blue","Red","Transparent","#FF00FF")

The default value is "#00D000"

.PARAMETER OnColor
The color of the "Off" blocks which represent the 0 digits in a binary number.

This value must be able to convert to a System.Windows.Media.Brush type. (e.g.
"Blue","Red","Transparent","#FF00FF")

The default value is "#606060"

.PARAMETER GridColor
The color of the space between the blocks.

This value must be able to convert to a System.Windows.Media.Brush type. (e.g.
"Blue","Red","Transparent","#FF00FF")

The default value is "#202020"

.PARAMETER TextColor
The color of the text on the blocks. All text is off by default. Press 'h' for
Help values, 't' for Time or 'd' for Date.

This value must be able to convert to a System.Windows.Media.Brush type. (e.g.
"Blue","Red","Transparent","#FF00FF")

The default value is "#FFFFFF"

.PARAMETER Topmost
This switch determines the window's Topmost attribute.

.EXAMPLE
C:\PS>.\Show-BinaryClock.ps1 -OnColor '#8000F0' -OffColor '#808080' -GridColor '#FFFFFF' -Topmost

Displays a topmost clock with a white grid, gray off blocks and purple on blocks.

.EXAMPLE
C:\PS>.\Show-BinaryClock.ps1 -OnColor '#F08000' -OffColor 'Transparent' -GridColor 'Transparent'

Displays a clock where the on blocks and any text are the only visible elements.

.NOTES
NAME:     Show-BinaryClock.ps1
VERSION:  1.0
DATE:     2011-07-08
AUTHOR:   Ryan Grant
#> 

param(
$OnColor = '#00D000',
$OffColor = '#606060',
$GridColor = '#202020',
$TextColor = '#FFFFFF',
[switch] $Topmost
)

Import-Module ShowUI -ErrorAction Stop

$GLOBAL:backColor = @{'0'=$OffColor ;'1'= $OnColor}
    
$windowParams = @{
    Width = 160
    Height = 90
    WindowStyle = 'None'
    AllowsTransparency = $true
    Background = $GridColor
    Topmost = $Topmost
}

Window @windowParams -Show `
-Content {
    # Create 3 Rows of 6 TextBlocks in a UniformGrid. The top row represents the hour,
    # the middle row represents the minute, and the bottom row represents the second.
    UniformGrid -Name ClockGrid -Columns 6 -Margin 2 -Children {
        foreach($part in @('Hour','Minute','Second'))
            {0..5|%{TextBlock -Name "$part$_" -Margin 2 -Foreground $TextColor}}
    }
} -On_Loaded {
    Register-PowerShellCommand -In '0:0:0.5' -Run -ScriptBlock {
        $time = Get-Date
        
        # Convert the time values to a binary format string
        $vals =  @($time.Hour, $time.Minute, $time.Second)| 
                    %{[convert]::ToString($_,2)}| 
                    %{('0'*(6-$_.ToString().Length))+$_}

        # Set the TextBlock background colors to the appropriate value for each digit in the 
        # binary formatted string. Using the $backColor hash table, 0 = $OffColor and 1 = $OnColor
        foreach($d in 0..5) {
            (Get-Variable "Hour$d").Value.Background = $backColor[[string]$vals[0][$d]]
            (Get-Variable "Minute$d").Value.Background = $backColor[[string]$vals[1][$d]]
            (Get-Variable "Second$d").Value.Background = $backColor[[string]$vals[2][$d]]
        }

        # Display the time text
        # Multiplying by $IsShowTime creates an empty string if it is $False
        'Hour','Minute'|
            %{(Get-Variable ($_+"0")).Value.Text = ("{0:00}" -f $time.$_) * $IsShowTime}
        
        # Only set the second text if the helper text is off, since they occupy the same TextBlock
        if(!$IsHelpers)
            {(Get-Variable ("Second0")).Value.Text = ("{0:00}" -f $time.Second) * $IsShowTime}
        
        # Display the date text
        $Hour3.Text = ("{0:00}" -f $time.Month) * $IsShowDate
        $Hour4.Text = ("{0:00}" -f $time.Day) * $IsShowDate
        $Hour5.Text = ($time.Year.ToString().Substring(2,2)) * $IsShowDate
    }
} -On_KeyDown {
    switch ($_.Key){
        # Toggle helper text, and turn off time text
        'H' {
                $IsShowTime = 0
                $IsHelpers = $IsHelpers -bxor 1
            }
        # Toggle time text, and turn off helper text
        'T' {
                $IsHelpers = 0
                $IsShowTime = $IsShowTime -bxor 1
            }
        # Toggle date text
        'D' {
                $IsShowDate = $IsShowDate -bxor 1
            }
        # Increase the size of the window
        {'Add','OemPlus' -contains $_} {
                $window.Width *= 1.1
                $window.Height *= 1.1
            }
        # Decrease the size of the window
        {'Subtract','OemMinus' -contains $_} {
                if($window.Width -gt 50) {
                    $window.Width /= 1.1
                    $window.Height /= 1.1
                }
            }
    }
    # Set digit value helper text
    1..5| %{(Get-Variable "Second$_").Value.Text = "{0:00}" -f [math]::Pow(2,(5-$_)) * $IsHelpers}
    
    # Only set leftmost digit helper if not displaying the time text
    if(!$IsShowTime) {(Get-Variable "Second0").Value.Text = '32' * $IsHelpers}    
} `
-On_MouseDoubleClick {$window.Close()}`
-On_MouseLeftButtonDown {$window.DragMove()}

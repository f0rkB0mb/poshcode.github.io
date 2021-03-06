PARAM(
   $presentationTitle = "PowerShell Presentation"
,  $background = "C:\Users\Joel\Pictures\flow\Flow_2560.jpg"
)

Import-Module PowerBoots
$name = [System.Windows.Navigation.JournalEntry]::NameProperty



function global:Add-Slide {
[CmdletBinding()]
PARAM(
   [Parameter(Position=0)]
   $Title   = "This is the title"
,  [Parameter(Position=1, ValueFromPipeline=$true)]
   [string[]]$Content = @("Several bullet points", "Which are equally important")
,   [Parameter()]
   $Window = $presentationTitle
)
BEGIN   { [string[]]$Points = @() }
PROCESS { [string[]]$Points += $Content }
END {
   Invoke-BootsWindow $Window {
      $global:container[0].Content = `
      StackPanel -Margin 10 {
         TextBlock $Title  -FontSize 42 -FontWeight Bold -Foreground "#FF0088" 
         $Points | % { TextBlock -FontSize 24 -Foreground "White" $_ }
      } | Set-AttachedProperty $Name $Title
   }
}
}

function global:Set-Slide {
PARAM([int]$index) 
   Invoke-BootsWindow $presentationTitle {
      $count = @($global:container[0].BackStack.GetEnumerator()).Count
      for($i=$count;$i -lt $index;$i++) {
         $global:container[0].GoForward()
      }
      for($i=$count;$i -gt $index;$i--) {
         $global:container[0].GoBack()
      }
   }
}

## Finally, make the slide window
Boots -Title $presentationTitle        { 
   Frame -Ov global:container          `
         -MinWidth 800 -MinHeight 600  `
         -Content { 
            StackPanel {
               TextBlock -FontSize 42 $presentationTitle -Foreground "White"
            } -ov global:WelcomePage |
            Set-AttachedProperty $Name "Welcome" 
         }
} -Async -Popup -On_SourceInitialized { 
   $this.Background = ImageBrush -ImageSource $background
} -WindowState Maximized



"Point 1 is cool","Point 2 is also"         | Add-Slide "Slide 1"
"This is one point", "And this is another"  | Add-Slide "Slide 2"

Add-Slide "Slide 3"  "Point 5 is cool","Point 6 is also"
Add-Slide "Slide 4"  "This is one point", "And this is the last"

Set-Slide 0




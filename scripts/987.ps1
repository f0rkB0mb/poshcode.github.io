#                                                                                                   #
# Select-Window Notepad | Remove-Window -passthru                                                   #
# ## And later ...                                                                                  #
# Select-Window Notepad | Select-ChildWindow | Send-Keys "%N"                                       #
# ## OR ##                                                                                          #
# Select-Window Notepad | Select-ChildWindow |                                                      #
#    Select-Control -title "Do&n't Save" -recurse | Send-Click                                      #
#                                                                                                   #

#                                                                                                   #
# PS notepad | Select-Window | Select-ChildWindow | %{ New-Object Huddled.Wasp.Window $_ }          #
#                                                                                                   #


# cp C:\Users\Joel\Projects\PowerShell\Wasp\trunk\WASP\bin\Debug\Wasp.dll .\Modules\WASP\           #
# Import-Module WASP

# function formatter  { END {
#    $input | Format-Table @{l="Text";e={$_.Text.SubString(0,25)}}, ClassName, FrameworkId -Auto
# }}

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$SWA = "System.Windows.Automation"

Import-Module Accelerators
Add-Accelerator AutoElement        "$SWA.AutomationElement"            -EA SilentlyContinue
Add-Accelerator InvokePattern      "$SWA.InvokePattern"                -EA SilentlyContinue
Add-Accelerator ExpandPattern      "$SWA.ExpandCollapsePattern"        -EA SilentlyContinue
Add-Accelerator WindowPattern      "$SWA.WindowPattern"                -EA SilentlyContinue
Add-Accelerator TransformPattern   "$SWA.TransformPattern"             -EA SilentlyContinue

Add-Accelerator ValuePattern       "$SWA.ValuePattern"                 -EA SilentlyContinue
Add-Accelerator TextPattern        "$SWA.TextPattern"                  -EA SilentlyContinue

Add-Accelerator Condition          "$SWA.Condition"                    -EA SilentlyContinue
Add-Accelerator AndCondition       "$SWA.TextPattern"                  -EA SilentlyContinue
Add-Accelerator OrCondition        "$SWA.TextPattern"                  -EA SilentlyContinue
Add-Accelerator NotCondition       "$SWA.TextPattern"                  -EA SilentlyContinue
Add-Accelerator PropertyCondition  "$SWA.PropertyCondition"            -EA SilentlyContinue

Add-Accelerator AutoElementIds     "$SWA.AutomationElementIdentifiers" -EA SilentlyContinue
Add-Accelerator TransformIds       "$SWA.TransformPatternIdentifiers"  -EA SilentlyContinue


$FalseCondition = [Condition]::FalseCondition
$TrueCondition  = [Condition]::TrueCondition

Add-Type -AssemblyName System.Windows.Forms
Add-Accelerator SendKeys           System.Windows.Forms.SendKeys                     -EA SilentlyContinue

function New-UIAElement {
[CmdletBinding()]
PARAM(
   [Parameter(ValueFromPipeline=$true)]
   [AutoElement]$Element
) 
PROCESS {
   $Element | Add-Member -Name Text            -Type ScriptProperty -PassThru -Value {
                        $this.GetCurrentPropertyValue([AutoElementIds]::NameProperty) 
          } | Add-Member -Name ClassName       -Type ScriptProperty -Passthru -Value { 
                        $this.GetCurrentPropertyValue([AutoElementIds]::ClassNameProperty) 
          } | Add-Member -Name FrameworkId     -Type ScriptProperty -Passthru -Value { 
                        $this.GetCurrentPropertyValue([AutoElementIds]::FrameworkIdProperty) 
          } | Add-Member -Name ProcessId       -Type ScriptProperty -Passthru -Value { 
                        $this.GetCurrentPropertyValue([AutoElementIds]::ProcessIdProperty) 
          } | Add-Member -Name ControlType     -Type ScriptProperty -Passthru -Value { 
                        $this.GetCurrentPropertyValue([AutoElementIds]::LocalizedControlTypeProperty) 
          }
}
}

function Select-Window {
[CmdletBinding()]
PARAM(
   [Parameter()]
   [Alias("Name")]
   [string]$Text="*"
,
   [Parameter()]
   [string]$ClassName="*"
,
   [Parameter()]
   [string]$ControlType="*"
,
	[Parameter()]
   [switch]$Recurse
,
   [Parameter(ValueFromPipeline=$true)]
   [AutoElement]$Parent = [AutoElement]::RootElement
) 
   PROCESS {
      if($Recurse) {
         $Parent.FindAll( "Descendants", $TrueCondition ) | New-UIAElement |
         Where-Object { 
            ($_.ClassName   -like $ClassName) -AND
            ($_.Text        -like $Text) -AND
            ($_.ControlType -like $ControlType)
         }
      } else {
         $Parent.FindAll( "Children", $TrueCondition ) | New-UIAElement |
         Where-Object { 
            ($_.ClassName   -like $ClassName) -AND
            ($_.Text        -like $Text) -AND
            ($_.ControlType -like $ControlType)
         }
      }
   }
}

function formatter  { END {
   $input | Format-Table @{l="Text";e={$_.Text.SubString(0,25)}}, ClassName, FrameworkId -Auto
}}


function Invoke-Element {
[CmdletBinding()]
PARAM(
   [Parameter(ValueFromPipeline=$true)]
   [AutoElement]$Target
)
   PROCESS {
      $Target.GetCurrentPattern([InvokePattern]::Pattern).Invoke()
   }
}

function Set-ElementText {
[CmdletBinding()]
PARAM(
   [Parameter()]
   [string]$Text
,
   [Parameter(ValueFromPipeline=$true)]
   [AutoElement]$Target
)
   PROCESS {
      $Target.SetFocus();
      $textPattern = $valuePattern = $null
      try {
         $textPattern = $Target.GetCurrentPattern([TextPattern]::Pattern)
         Write-Host "textPattern:`n$($textPattern | gm)"
      } catch { }
      try {
         $valuePattern = $Target.GetCurrentPattern([ValuePattern]::Pattern)
         Write-Host "valuePattern:`n$($valuePattern | gm)"
      } catch { }
      
      $Target.SetFocus();
      
      
      if($valuePattern) {
         $valuePattern.SetValue( $Text )
      }
      if($textPattern) {
         [SendKeys]::SendWait("^{HOME}");
         [SendKeys]::SendWait("^+{END}");
         [SendKeys]::SendWait("{DEL}");
         [SendKeys]::SendWait( $Text )
      }
   }
}

#requires -version 2.0

[CmdletBinding()]
param($Path)

<#
    Quick check to see if we have necessary module...
#>

if (!(Get-Module ShowUI)) {
    try {
        Import-Module ShowUI
    } catch {
        Write-Warning "Can't load ShowUI module. I quit! For more details about error use -Verbose parameter."
        Write-Verbose $_
    }
}   

<#
    Show UI builds UI structure...
#>

Show-UI  -Parameters $Path {
    param ($Path)
    DockPanel -Height 400 {
        ScrollViewer {
            ItemsControl {
                <#
                    Hash that will set common button's options and some effects...
                #>
            
                $Effect = @{
                    Effect = {
                        New-Object Windows.Media.Effects.BlurEffect -Property @{
                            Radius = 3
                        }
                    }
                    On_MouseEnter = {
                        $Clear = DoubleAnimation -From 3 -To 1 -Duration '0:0:0.5'
                        $DependencyRadius = $This.Effect.GetType()::RadiusProperty
                        $This.Effect.BeginAnimation($DependencyRadius,$Clear)
                    }
                    On_MouseLeave = {
                        $Blur = DoubleAnimation -From 1 -To 3 -Duration '0:0:0.5'
                        $DependencyRadius = $This.Effect.GetType()::RadiusProperty
                        $This.Effect.BeginAnimation($DependencyRadius,$Blur)
                    }
                }
                
                <#
                    Time to read our folder. We ignore folders, only files will be listed.
                    As you can see it's pretty easy to pass $Path parameter to UI, and it's not global... :)
                #>
                
                foreach ($File in Get-ChildItem $Path | where { !$_.PSIsContainer } ) {
                    Button @Effect -Content $File.Name -On_Click ([scriptblock]::Create(@"
                        Write-UIOutput $($File.FullName)
                        `$ShowUI.ActiveWindow.Close()
"@)) -ToolTip "File size: $($File.Length) bytes, Last modified: $($File.LastWriteTime.ToShortDateString())"
                    
                }
            } # END ItemsControl
        } # END ScrollViewer
    } # END DockPanel
} # END Show-UI

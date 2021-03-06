# Module version 0.1
# Author: Bartek Bielawski (@bielawb on twitter)
# Purpose: Add functionality to PowerShell ISE
# Description: Adds Add-ons menu 'ISEFun' with all functions included.
#    User can add any action there using Add-MyMenuItem function
#    One of functions (Copy item from history) was build using WPK - won't work if the latter is not loaded.
#    There is also pretty large code for Windows Forms form (change token colors using ColorDialog
#    Edit-Function will allow you modify any function in ISE editor
#    Expand-Alias will expand aliases in current file
#    Have ISE - Fun! ;)
    



if (-not ($MyISEMenu = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus | Where-Object { $_.DisplayName -eq 'ISEFun'} ) ) {
    $MyISEMenu = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('ISEFun',$null,$null)
}

# Helper function to add menu items, exported cause it can be used also for other stuff. :>
function Add-MyMenuItem {

<#
    .Synopsis
        Adds items to ISEFun Add-Ons sub-menu
    .Description
        Function can be used to add menu items to ISEFun menu. All you need is command, name and hotkey - we will take care of the rest for you. ;)
    .Example
        Add-MyMenuItem 'Write-Host fooo' 'Fooo!' 'CTRL+9'
        
        Description
        -----------
        This command will add item 'Fooo!' to ISEFun menu. This item will write 'fooo' to the host and can be launched using shortcut CTRL + 9
        
#>

    PARAM (
        # Script that will be launched when menu item will be selected
        [Parameter(Mandatory = $true, HelpMessage = 'Command that you want to add to menu')]
        [string]$Command,
        # Title for the command in the menu
        [string]$DisplayName,
        # Hot key to use given item
        [string]$HotKey = $null
    )
    if (!$DisplayName) { 
        $DisplayName = $Command -replace '-',' '
    }
    if ( -not ($MyISEMenu.Submenus | Where-Object { $_.DisplayName -eq $DisplayName} ) ) {
        try {
            [void]$Script:MyISEMenu.Submenus.Add($DisplayName,[scriptblock]::Create($Command),$HotKey)
        } catch {
            # Probably hotkey already use, adding item without it
            [void]$Script:MyISEMenu.Submenus.Add($DisplayName,[scriptblock]::Create($Command),$null)
        }
    }
}

Add-MyMenuItem Add-MyMenuItem 'Add items'

# Next few lines are just garbage you get when you wanna be smart and create GUI in the script.
# Forgive me for adding this stuff here, I could probably compile it in some dll and skip this but...
# ... well - it gives impression that my module is bigger than it actually is. ;)
#
# Our form to change colours... :)
$handler_bClose_Click= 
{
    $Main.Hide()
}

$handler_bColor_Click= 
{
    $Dialog = New-Object Windows.Forms.ColorDialog -Property @{
        Color = [drawing.color]::FromArgb($psISE.Options.TokenColors.Item($Combo.SelectedItem).ToString())
        FullOpen = $true
    }
    
    if ($Dialog.ShowDialog() -eq 'OK') {
        $psISE.Options.TokenColors.Item($Combo.SelectedItem) = [windows.media.color]::FromRgb($Dialog.Color.R, $Dialog.Color.G, $Dialog.Color.B)
        $Combo.ForeColor = $Dialog.Color

    }

}

$handler_selectedValue = {
    $Combo.ForeColor = [drawing.color]::FromArgb($psISE.Options.TokenColors.Item($Combo.SelectedItem).ToString())
    $bColor.Focus()
}

$OnLoadForm_StateCorrection = {
	$Main.WindowState = $InitialFormWindowState
}

$Script:Main = New-Object Windows.Forms.Form -Property @{
    Text = "Token colors selector"
    MaximizeBox = $False
    Name = "Main"
    HelpButton = $True
    MinimizeBox = $False
    ClientSize = New-Object System.Drawing.Size 426, 36
}
$Main.DataBindings.DefaultDataSourceUpdateMode = 0

$Combo = New-Object Windows.Forms.ComboBox -Property @{
    FormattingEnabled = $True
    Size = New-Object System.Drawing.Size 239, 23
    Name = "Combo"
    Location = New-Object System.Drawing.Point 12, 7
    Font = New-Object System.Drawing.Font("Lucida Console",11.25,0,3,238)
    TabIndex = 4
    }
$Combo.DataBindings.DefaultDataSourceUpdateMode = 0
$Combo.Items.AddRange($psISE.Options.TokenColors.Keys)
$Combo.Add_SelectedValueChanged($handler_SelectedValue)

$InitialFormWindowState = New-Object Windows.Forms.FormWindowState

$bClose = New-Object Windows.Forms.Button -Property @{
    TabIndex = 2 
    Name = "bClose"
    Size = New-Object System.Drawing.Size 75, 23
    UseVisualStyleBackColor = $True
    Text = "Close"
    Location = New-Object System.Drawing.Point 338, 7
    }
$bClose.DataBindings.DefaultDataSourceUpdateMode = 0
$bClose.add_Click($handler_bClose_Click)

$bColor = New-Object Windows.Forms.Button -Property @{
    TabIndex = 1
    Name = "bColor"
    Size = New-Object System.Drawing.Size 75, 23
    UseVisualStyleBackColor = $True
    Text = "Color"
    Location = New-Object System.Drawing.Point 257, 7
}
$bColor.DataBindings.DefaultDataSourceUpdateMode = 0
$bColor.add_Click($handler_bColor_Click)

$Main.Controls.AddRange(@($bColor,$bClose,$Combo))
$InitialFormWindowState = $Main.WindowState
$Main.add_Load($OnLoadForm_StateCorrection)
$HelpMessage = @'
This GUI will help you change you token colors.
It's updating text color as you select tokens that you want to modify.
Button 'Color' opens up color dialog.
I won't describe actions performed by 'Close' button. I hope you are able to guess it... ;)
'@
$Main.add_HelpButtonClicked( { [void][windows.forms.MessageBox]::Show($HelpMessage,'Help','OK','Information')})

function Set-TokenColor {

<#
    .Synopsis
        GUI to add some Token Colors.
    .Description
        Really. It is just that. No more to it. Seriously!
        OK. GUI is pretty smart. You can select tokens that are available, color will change and match the one you currently have. See for yourself. ;)
    .Example
        Can show you click-click-click example :)
#>
    $Script:Main.ShowDialog()| Out-Null
}

Add-MyMenuItem Set-TokenColor

function Expand-Alias {

<#
    .Synopsis
        Function to expand all command aliases in current script.
    .Description
        If you want to expand all aliases in a script/ module that you write in PowerShell ISE - this function will help you with that.
        It's using Tokenizer to find all commands, Get-Alias to find aliases and their definition, and simply replace alias with command hidden by it.
    .Example
        Expand-Alias
#>

    # Read in current file
    if (!$psISE.CurrentFile) {
        throw 'No files opened!'
    }
    
    if ( -not ($Script = $psISE.CurrentFile.Editor.Text) ) {
        throw 'No code!'
    }
    
    $line = $psISE.CurrentFile.Editor.CaretLine
    $column = $psISE.CurrentFile.Editor.CaretColumn
    
    if ( -not ($commands = [System.Management.Automation.PsParser]::Tokenize($Script, [ref]$null) | Where-Object { $_.Type -eq 'Command' } | Sort-Object -Property Start -Descending) ) {
        return
    } 
    foreach ($command in $commands) {
        if (Get-Alias $command.Content -ErrorAction SilentlyContinue) {
            # $command
            $psISE.CurrentFile.Editor.Select($command.StartLine, $command.StartColumn, $command.EndLine, $command.EndColumn)
            $psISE.CurrentFile.Editor.InsertText($(Get-Alias $command.Content | Select-Object -ExpandProperty Definition))
        }
    }
    $psISE.CurrentFile.Editor.SetCaretPosition($line, $column)
}

Add-MyMenuItem Expand-Alias

function Edit-Function {

<#
    .Synopsis
        Simpe function to edit functions in ISE.
    .Description
        Need to edit function on-the-fly? Want to see how a given function looks like to change it a bit and rename it?
        Or maybe just preparing module and you want to change functions you define to make sure changes will work as expected?
        Well, with Edit-Function, which is very simple (thank you PowerShell team!) you can do it. :)
    .Example
        Edit-Function Edit-Function
        
        Description
        -----------
        You can open any function that exists in your current session, including the function that you reading help to now.
        Be careful with that one though. If you change it in wrong direction you may not be able to open it again and fix it.
        At least not in the way you could originaly, with Edit-Function. :)
#>

    [CmdletBinding()]
    param (
    [Parameter(Mandatory=$true,HelpMessage='Function name is mandatory parameter.')]
    [ValidateScript({Get-Command -CommandType function $_})]
    [string]
    $Name
    )
    if (!$psISE) {
        Throw 'Implemented for PowerShell ISE only!'
    }
    $file = $psISE.CurrentPowerShellTab.Files.Add()
    $file.Editor.InsertText("function $name {`n")
    $file.Editor.InsertText($(Get-Command -CommandType function $name | Select-Object -ExpandProperty definition))
    $file.Editor.InsertText("}")
}

Add-MyMenuItem Edit-Function

function Copy-HistoryItem {

<#
    .Synopsis
        Function build using WPK to give you functionality similar to one you already have in PowerShell.exe
    .Description
        Display you command history and let you choose from it. Copies selected command to you commandPane.
    .Example
        Copy-HistoryItem
        GUI, so it's not easy to show examples...
#>

    try {
        New-Window -Width 800 -Height 100 {
            New-ListBox -On_PreviewMouseDoubleClick {
                $psISE.CurrentPowerShellTab.CommandPane.InsertText($this.SelectedValue)
                $this.parent.close()
            } -Items $(Get-History | Select-Object -ExpandProperty CommandLine)
        } -Show
    } catch {
        throw 'Requires WPK to work, will be rewritten soon...'
    }
}

Add-MyMenuItem Copy-HistoryItem 'Copy item from History' F7

New-Alias -Name edfun -Value Edit-Function
New-Alias -Name expa -Value Expand-Alias
New-Alias -Name cphi -Value Copy-HistoryItem

Export-ModuleMember -Function * -Alias *

# Get rid off menu if module is going to be unloaded.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    [void]$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Remove($MyISEMenu)
}

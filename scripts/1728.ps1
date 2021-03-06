#requires -version 2.0
## ISE-FileName module v 1.0
##############################################################################################################
## Provides File and Path cmdlets for working with ISE
## Copy-ISEFullPath - Copy the full path of the current file to the clipboard
## Copy-ISEPath - Copy the path of the current file to the clipboard
## Copy-ISEFileName - Copy the filename of the current file to the clipboard
##
## Usage within ISE or Microsoft.PowershellISE_profile.ps1:
## Import-Module ISE-FileName.psm1
##
## Code found in IseCream (http://psisecream.codeplex.com/) that was authored by Doug Finke
## under the name Copy-ISEFileName.ps1
##
##############################################################################################################
## History:
## 1.0 - Initial release (Doug Finke)
##############################################################################################################

## Get-ISEFullPath 
##############################################################################################################
## Function to get the Full Path for use by the other functions
## This code was originaly designed by Doug Finke
##############################################################################################################
Function Get-ISEFullPath {
    $psISE.CurrentFile.FullPath
}

## Copy-ISEFullPath 
##############################################################################################################
## Copy the full path of the current file to the clipboard
## This code was originaly designed by Doug Finke
##############################################################################################################
Function Copy-ISEFullPath {
    (Get-ISEFullPath) | Copy-ToClipBoard 
}

## Copy-ISEPath
##############################################################################################################
## Copy the path of the current file to the clipboard
## This code was originaly designed by Doug Finke
##############################################################################################################
Function Copy-ISEPath {
   Split-Path (Get-ISEFullPath) | Copy-ToClipBoard 
}

## Copy-ISEFileName
##############################################################################################################
## Copy the filename of the current file to the clipboard
## This code was originaly designed by Doug Finke
##############################################################################################################
Function Copy-ISEFileName {
   Split-Path -Leaf (Get-ISEFullPath) | Copy-ToClipBoard 
}

## Copy-ToClipboard
##############################################################################################################
## Filter to copy the code to the clipboard
## This code was originaly designed by Doug Finke
##############################################################################################################
Filter Copy-ToClipBoard {
    $dataObject = New-Object Windows.DataObject 
    $dataObject.SetText($_, [Windows.TextDataFormat]"UnicodeText") 
    [Windows.Clipboard]::SetDataObject($dataObject, $true)
}

##############################################################################################################
## Inserts a submenu File/Path Names to ISE's Custom Menu
## Inserts command Copy FullPath to submenu File/Path Names
## Inserts command Copy Path to submenu File/Path Names
## Inserts command Copy Filename to submenu File/Path Names
##############################################################################################################
if (-not( $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus | where { $_.DisplayName -eq "File/Path Names" } ) )
{
	$filenameMenu = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add("_File/Path Names",$null,$null) 
	$null = $filenameMenu.Submenus.Add("Copy FullPath", {Copy-ISEFullPath}, "Ctrl+Alt+A")
	$null = $filenameMenu.Submenus.Add("Copy Path", {Copy-ISEPath}, "Ctrl+Alt+P")
	$null = $filenameMenu.Submenus.Add("Copy Filename", {Copy-ISEFileName}, "Ctrl+Alt+F")
}

# If you are using IsePack (http://code.msdn.microsoft.com/PowerShellPack) and IseCream (http://psisecream.codeplex.com/),
# you can use this code to add your menu items. The added benefits are that you can specify the order of the menu items and
# if the shortcut already exists it will add the menu item without the shortcut instead of failing as the default does.
#Add-IseMenu -Name "File/Path Names" @{            
#    "Copy FullPath"  = {Copy-ISEFullPath} | Add-Member NoteProperty order 1 -PassThru | Add-Member NoteProperty ShortcutKey "Ctrl+Alt+A" -PassThru
#    "Copy Path"      = {Copy-ISEPath} | Add-Member NoteProperty order 2 -PassThru | Add-Member NoteProperty ShortcutKey "Ctrl+Alt+P" -PassThru
#    "Copy Filename"  = {Copy-ISEFileName} | Add-Member NoteProperty order 3 -PassThru | Add-Member NoteProperty ShortcutKey "Ctrl+Alt+F" -PassThru
#}

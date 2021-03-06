# Removes un-needed apps from Windows 10.
# To keep install of package insert hashtag before line, see example below:
#Get-AppxPackage *3dbuilder* | Remove-AppxPackage

Get-AppxPackage *3dbuilder* | Remove-AppxPackage
Get-AppxPackage *Appconnector* | Remove-AppxPackage
Get-AppxPackage *BingFinance* | Remove-AppxPackage
Get-AppxPackage *BingNews* | Remove-AppxPackage
Get-AppxPackage *BingSports* | Remove-AppxPackage
Get-AppxPackage *BingWeather* | Remove-AppxPackage
Get-AppxPackage *CommsPhone* | Remove-AppxPackage
Get-AppxPackage *ConnectivityStore* | Remove-AppxPackage
Get-AppxPackage *Getstarted* | Remove-AppxPackage
Get-AppxPackage *Messaging* | Remove-AppxPackage
Get-AppxPackage *MicrosoftOfficeHub* | Remove-AppxPackage
Get-AppxPackage *MicrosoftSolitaireCollection* | Remove-AppxPackage
Get-AppxPackage *OneNote* | Remove-AppxPackage
Get-AppxPackage *Sway* | Remove-AppxPackage
Get-AppxPackage *people* | Remove-AppxPackage
Get-AppxPackage *SkypeApp* | Remove-AppxPackage
Get-AppxPackage *WindowsAlarms* | Remove-AppxPackage
Get-AppxPackage *WindowsCamera* | Remove-AppxPackage
Get-AppxPackage *windowscommunicationsapps* | Remove-AppxPackage
Get-AppxPackage *WindowsDVDplayer* | Remove-AppxPackage
Get-AppxPackage *WindowsMaps* | Remove-AppxPackage
Get-AppxPackage *WindowsPhone* | Remove-AppxPackage
Get-AppxPackage *WindowsSoundRecorder* | Remove-AppxPackage
Get-AppxPackage *commsphone* | Remove-AppxPackage
Get-AppxPackage *WindowsStore* | Remove-AppxPackage
Get-AppxPackage *XboxApp* | Remove-AppxPackage
Get-AppxPackage *ZuneMusic* | Remove-AppxPackage
Get-AppxPackage *ZuneVideo* | Remove-AppxPackage
Get-AppxPackage *xbox* | Remove-AppxPackage
Get-AppxPackage *contactsupport* | Remove-AppxPackage

# Prevents the above apps from being installed onto new user accounts.
# To allow install of package insert hashtag before line, see example below:
#$Applist | WHere-Object {$_.packagename -like “*3DBuilder*”} | Remove-AppxProvisionedPackage -online

$Applist = Get-AppXProvisionedPackage -online

$Applist | WHere-Object {$_.packagename -like “*3DBuilder*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*Appconnector*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*BingFinance*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*BingNews*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*BingSports*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*BingWeather*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*CommsPhone*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*ConnectivityStore*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*Getstarted*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*Messaging*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*MicrosoftOfficeHub*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*MicrosoftSolitaireCollection*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*OneNote*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*Sway*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*People*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*SkypeApp*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*WindowsAlarms*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*WindowsCamera*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*windowscommunicationsapps*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*WindowsDVDplayer*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*WindowsMaps*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*WindowsPhone*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*WindowsSoundRecorder*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*WindowsStore*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*XboxApp*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*ZuneMusic*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*ZuneVideo*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*xbox*”} | Remove-AppxProvisionedPackage -online
$Applist | WHere-Object {$_.packagename -like “*contact support*”} | Remove-AppxProvisionedPackage -online

# Blocks Windows 10 from auto downloading new apps to users by adding a line into the registry.

$RegKey = “HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent”
if (-Not(Test-Path “$RegKey”)) {
New-Item -Path “$($RegKey.TrimEnd($RegKey.Split(‘\’)[-1]))” -Name “$($RegKey.Split(‘\’)[-1])” -Force | Out-Null
}
New-ItemProperty -Path “$RegKey” -Name “DisableWindowsConsumerFeatures” -Value “1” -PropertyType "Dword"

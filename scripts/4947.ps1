###############################################################################
# Use Unregister-Event -SourceIdentifier <name> -Force (to stop)
# Include script in $profile to register all these events. (Access events via 
# $MyEvent.SourceEventArgs.NewEvent for the current session only). Must only 
# be run once per session (via $profile).
# Please visit www.SeaStar.99k.org for many more utilities. 
# The Set-Variable below is needed for both Actions 3 and 9. Ensure that any
# unwanted 'actions' (Register-WmiEvent) are commented out.
###############################################################################
Set-Variable MSEupdate -Value 0 -Scope Global -Description `
    "MSE Database Status"

###############################################################################
#This ACTION will trap any USB insertions (SourceId = USBdevice).
###############################################################################
$action1 = {
    $file   = 'd:\Scripts\AutoMSE.vbs'    #Change to run desired script, etc.
    If (!(test-Path variable:\MyEvent)) {
        Set-Variable -name MyEvent -scope global
    }                         #$MyEvent.TargetInstance will display properties.
    $GLOBAL:MyEvent = $Event         #Expose to session for testing (As above).
    $e = $Event.SourceEventArgs.NewEvent
    $drive  = $e.TargetInstance.DeviceID   #Add a line here to exclude any USB device.
    $volume = $e.TargetInstance.VolumeName
    $serial = $e.TargetInstance.VolumeSerialNumber
    $free   = $e.TargetInstance.FreeSpace
    $size   = $e.TargetInstance.Size
    If ($volume -eq "") {
        $volume = "<BLANK>"
    }                                      #Now just add any exclusions here...
    If (($serial -ne "") -and ($volume -ne 'AIRCARD')) {           
        & c:\windows\system32\wscript.exe $file $drive $volume #Only single quotes here, if any!
    }
}
$query1 = "SELECT * FROM __InstanceCreationEvent WITHIN 10 WHERE `
    TargetInstance ISA 'Win32_LogicalDisk' AND TargetInstance.DriveType = 2"

$errorActionPreference = "SilentlyContinue"
$status = "FAIL"
While ($status -ne "OK") {
    try {
        Register-WmiEvent -Query $query1 -SourceIdentifier USBdevice -SupportEvent -Action $action1 `
        | Out-Null
        $status = "OK"
        Write-Host "USB Filter (Source: USBdevice) has been loaded successfully."
        Write-Host ""
    }
    catch {
        Write-Warning "WMI Error - USB filter has failed to load. Retrying ..."
        Start-Sleep -Seconds 3                                  #Wait 3 seconds.
    }
}
$errorActionPreference = "Continue"
###############################################################################
#This ACTION will trap any file downloads (SourceId = Download).
# New-Eventlog -Source Download -Logname 'Internet Explorer' must be added.
###############################################################################
$action2 = {
    $GLOBAL:MyEvent = $Event                  #Save for testing purposes later.
    $eventLog = "Internet Explorer"
    $id = 99
    $e = $Event.SourceEventArgs.NewEvent
    $drive  = $e.TargetInstance.Drive
    $file   = $e.TargetInstance.FileName + "." + `
              $e.TargetInstance.Extension
    $path   = $e.TargetInstance.Path
    $folder = $drive + "\Users\Derf\Downloads"
    Switch ($e.TargetInstance.Extension) {
        'exe'   {$id = 20; break}
        'enu'   {$id = 21; break}
        'ps1'   {$id = 22; break}
        'html'  {$id = 23; break}
        'zip'   {$id = 24; break}
        'rar'   {$id = 25; break}
        'part'  {$id = 26; break}
        'msi'   {$id = 29; break}
        Default {$id = 99}                 
    }
    $formatString = "{0:0.0}Kb"
    $size = $formatString -f ($e.TargetInstance.FileSize/1KB)
    $file = $file.Replace(".part","")
    $desc = "File $file has been added to the $folder folder (Filesize = $size)"
    If (!$desc.EndsWith("= 0.0Kb)")) {                     #Skip blank entries.
        Write-EventLog -Logname $eventLog -Source Download -EntryType Information -EventID $ID -Message $desc
    }
}
$query2 = "SELECT * FROM __InstanceCreationEvent WITHIN 30 WHERE TargetInstance `
    ISA 'CIM_DataFile' AND TargetInstance.Path = '\\Users\\Derf\\Downloads\\' AND `
        (TargetInstance.Drive = 'C:')"

Register-WmiEvent -Query $query2 -SourceIdentifier Download -SupportEvent -Action $action2 `
    | Out-Null

###############################################################################
# This ACTION will catch MSE Database Update (SourceId = FileWatcher) .There is
# no Event Log entry for this so use FileSystemWatcher instead.
# Change to run any script, etc. (Prompter.exe is now included in the Scripting
# Editor download from www.SeaStar.99k.org and is used to put a message in the
# notification area; simpler than using PowerShell). 
###############################################################################
$action3 = {
    $file = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType
    If (($GLOBAL:MSEupdate -eq 0) -and (Test-Path .\Prompter.exe)) {
        & 'd:\Scripts\prompter.exe' /Notify update /Title Microsoft Security Essentials Update `
          /Msg Update started: File $file is being updated. /Time
        [Console]::Beep(800,500)
        $GLOBAL:MSEupdate = 1 #This will ensure only 1 run and allow EndUpdate.
    }
}

$folder = "c:\ProgramData\Microsoft\Microsoft Antimalware\Definition Updates\"
$filter = "*.vdm"
$fsw = New-Object -TypeName System.IO.FileSystemWatcher -ArgumentList `
    $folder, $filter
$fsw.IncludeSubDirectories = $true #The '{**}' folder name changes on each run!
$fsw.EnableRaisingEvents   = $true

Register-ObjectEvent -InputObject $fsw -EventName "Changed" `
    -SourceIdentifier FileWatcher -SupportEvent -Action $action3 | Out-Null

###############################################################################
#This ACTION runs Ccleaner and WinPlayer.vbs (SourceId = UnHibernate)
###############################################################################
$action4 = {
    $file = 'd:\scripts\WinPlayer.vbs'
    & 'c:\windows\system32\wscript.exe' $file 2000   #Play Windows start sound.
    & "$env:programfiles\ccleaner\ccleaner.exe" /AUTO
    attrib -s -h 'C:\Users'         #Missing Explorer folders:Clear attributes.
    attrib -s -h 'C:\Users\derf'
}
$query4 = "SELECT * FROM Win32_PowerManagementEvent WHERE EventType = '18'"

Register-WmiEvent -Query $query4 -SourceIdentifier UnHibernate -SupportEvent -Action $action4 `
    | Out-Null

###############################################################################
#This ACTION will detect Avast Database changes (Updates). 
###############################################################################
$action5 = {
    If (!(test-Path variable:\MyEvent)) {
        Set-Variable -name MyEvent -scope Global
    }
    $GLOBAL:MyEvent = $Event
    $e = $Event.SourceEventArgs.NewEvent
    & 'd:\Scripts\prompter.exe' /Notify update /Title Avast Update Service `
       /Msg Starting database update
    Write-Eventlog -logname Antivirus -source avast -eventID 90 -entryType `
        Information -message "Avast5 Automatic Database Update"
}
$query5 = "SELECT * FROM __InstanceCreationEvent WITHIN 180 WHERE `
    TargetInstance ISA 'Win32_Process' AND TargetInstance.Name = 'avast.setup'"

#Register-WmiEvent -Query $query5 -SourceIdentifier Avast -Action $action5 `
#    | Out-Null

###############################################################################
#This ACTION will detect Windows Media Player & then start ActiveSyncToggle
###############################################################################
$action7 = {
    If (Test-Path "d:\Applications\ActiveSyncToggle.exe") {
        & 'd:\Applications\ActiveSyncToggle.exe'
    } 
}
$query7 = "SELECT * FROM __InstanceCreationEvent WITHIN 10 WHERE `
    TargetInstance ISA 'Win32_Process' AND TargetInstance.Name = 'wmplayer.exe'"

#Register-WmiEvent -Query $query7 -SourceIdentifier MediaPlayer -Action $action7 `
#    | Out-Null
 
###############################################################################
# This ACTION will detect any changes to the registry HKLM\Run key and write
# a Warning event in the Applications Event log. The message box will timeout
# after 10 seconds.
###############################################################################

$hive = "HKEY_LOCAL_MACHINE"
$keyPath = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run"

$action8 = {
    $HKLM = 'The key HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' +
       ' has been modified; check if the change is intentional.'
    $logType = 2
    $shell = New-Object -Com Wscript.Shell
    If (!(test-Path variable:\MyEvent)) {
        Set-Variable -name MyEvent -scope Global
    }
    $GLOBAL:MyEvent = $Event
    $shell.Popup($HKLM,10,'PS Automatic Event Monitor',48) | Out-Null  
    $Shell.LogEvent($logType,$HKLM) | Out-Null 
}
$query8 = "SELECT * FROM RegistryKeyChangeEvent WHERE Hive = '$hive' AND KeyPath = '$keyPath'"

Register-WmiEvent -Query $query8 -Namespace 'root\default' `
    -SourceIdentifier HKLMRunKey -SupportEvent -Action $action8 | Out-Null

###############################################################################
# This ACTION will detect the end of the update of MSE database (EventID 2000)
###############################################################################

$action9 = {
    If (($GLOBAL:MSEupdate -eq 1) -and (Test-Path .\Prompter.exe)) {
        & 'd:\Scripts\prompter.exe' /Notify mse /Title Microsoft Security Essentials Update `
              /Msg Database update completed. /Time
        [Console]::Beep(800,500)
        $GLOBAL:MSEupdate = 0         #One run only and allow next StartUpdate.
    }
}

$query9 = "SELECT * FROM __InstanceCreationEvent WHERE TargetInstance ISA `
             'Win32_NTLogEvent' AND TargetInstance.EventCode = '2000' AND `
                TargetInstance.LogFile = 'System'"

Register-WmiEvent -Query $query9 -SourceIdentifier 'EndUpdate' -SupportEvent -Action $action9 `
    | Out-Null 

###############################################################################
# This ACTION will only write once to the 'Ipconfig.txt' log each time online
# status is confirmed, although 1 or more Event 10000 entries may appear.
# These Events are forwarded automatically from the NetworkProfile\Operational 
# Event Log by a scheduled task, running 'ForwardEvent.exe'*, and if any number
# appear the 'action' will run once after 90 seconds. 
# [Type ForwardEvent ? in cmd window to list all the options.]
###############################################################################
$action10 = {
    $file    = "d:\scripts\ipconfig.txt"                       #Change to suit.
    $GLOBAL:MyNewEvent = $Event
    $command = "ipconfig.exe /all"
    $date    = ("{0:F}" -f [DateTime]::Now).PadRight(36,' ')
    $string  = ('-' * 80)
    $ping    = "ping -n 1 Yahoo.com"

##Now start the Here-String (End of string must be in Column 1)
$myString = @"

$date                              LAN Restart:
$string
"@
##End of Here-String

    Invoke-Expression $ping | Out-Null    #Only run next line if we are Online.
    $GLOBAL:PingStatus = $lastExitCode
    If (($lastExitCode -eq 0) -and (Test-Path $file)) {
        $myString | Out-File -Filepath $file -Encoding ASCII -Append
        Invoke-Expression $command | Out-File -Filepath $file -Encoding ASCII -Append
    } 
}

# Collect events forwarded from the NetworkProfile\Operational to the Scripts 
# Event Log. 

$query10 = "SELECT * FROM __InstanceCreationEvent WHERE TargetInstance ISA `
             'Win32_NTLogEvent' AND TargetInstance.EventCode = '300' AND `
                TargetInstance.SourceName = 'Internet' GROUP WITHIN 90 HAVING `
                  NumberOfEvents > 0"

Register-WmiEvent -Query $query10 -SourceIdentifier 'OnlineStatus' -SupportEvent -Action $action10 `
    | Out-Null 
 
#################################################################################
# Save all the available history items on exit from current PowerShell session.
# Use PowerShell's exiting event & hide the registration with -supportevent. This
# only works after typing 'EXIT', not via the top right 'X' button (although it
# will work in ISE).
#################################################################################

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -SupportEvent -Action {
   $error | ForEach-Object { $_.InvocationInfo.historyId} |
      Where-Object {$_ -gt 0} | 
         ForEach-Object {clear-history -id $_ -errorAction SilentlyContinue}
   Get-History | Sort-Object -Property CommandLine -Unique |
      Where-Object {$_.CommandLine -ne 'exit'} |
         Sort-Object -Property EndExecutionTime -Descending |
            Export-Clixml (Join-Path (Split-Path $profile) history.clixml) 
}
 



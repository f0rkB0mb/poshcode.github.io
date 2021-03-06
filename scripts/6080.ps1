
try{
    Add-PSSnapin VMware.VimAutomation.Core -ErrorAction continue
    Connect-VIServer -Server "ActualServerName" -user domain\Username -password Password1IsTheBestPassword -erroraction continue
}
catch {
    exit
}

$scheduler = New-Object -ComObject Schedule.Service
function Connect-ToTaskScheduler{
    param(
    # The name of the computer to connect to.
    $ComputerName,
    
    # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential    
    )   
    
    $scheduler = New-Object -ComObject Schedule.Service
    if ($Credential) { 
        $NetworkCredential = $Credential.GetNetworkCredential()
        $scheduler.Connect($ComputerName, 
            $NetworkCredential.UserName, 
            $NetworkCredential.Domain, 
            $NetworkCredential.Password)            
    } else {
        $scheduler.Connect($ComputerName)        
    }    
    $scheduler
}
function Get-ScheduledTask{
    param(
    # The name or name pattern of the scheduled task
    [Parameter()]
    $Name = "*",
    
    # The folder the scheduled task is in
    [Parameter()]
    [String[]]
    $Folder = "",
    
    # If this is set, hidden tasks will also be shown.  
    # By default, only tasks that are not marked by Task Scheduler as hidden are shown.
    [Switch]
    $Hidden,    
    
    # The name of the computer to connect to.
    $ComputerName,
    
    # The credential used to connect
    [Management.Automation.PSCredential]
    $Credential,
    
    # If set, will get tasks recursively beneath the specified folder
    [switch]
    $Recurse
    )
    
    process {
        $scheduler = Connect-ToTaskScheduler -ComputerName $ComputerName -Credential $Credential            
        $taskFolder = $scheduler.GetFolder($folder)
        $taskFolder.GetTasks($Hidden -as [bool]) | Where-Object {
            $_.Name -like $name
        }
        if ($Recurse) {
            $taskFolder.GetFolders(0) | ForEach-Object {
                $psBoundParameters.Folder = $_.Path
                Get-ScheduledTask @psBoundParameters
            }
        }        
    }
} 

$strDt = get-date -format "yyyyMMdd_HHmm"
$outfile = "D:\automation\get-AllServices\output\scheduledTasks_$strDt.csv"

$data = @()
$jobData = @()
$block = {schtasks /query /S $server /fO csv /V}

foreach ($server in (get-vm | Where-Object {$_.powerstate -eq "poweredon" -and $_.guest.GuestFamily -eq "windowsGuest"}).guest.hostname){
    $server
    $data = $null
    $data = &$block | ConvertFrom-csv
    foreach ($obj in $data){
        if (($obj.hostname -eq "Hostname" -and $obj.TaskName -eq "TaskName" -and $obj.status -eq "Status") -or $obj.taskname.contains("\Microsoft\") -eq $true){} #Do nothing if the line is just headers or if it's core MS
        else{
            $obj | Add-Member -name "Arguments" -MemberType NoteProperty -value ""
            #$obj.TaskName
            if ($obj.'Task To Run' -eq "Multiple Actions"){
                $xmlData = (Get-ScheduledTask -ComputerName $obj.HostName -name ($obj.taskname).split("\")[-1] -Recurse).xml.split("`n")
                $obj.'Task To Run' = ($xmlData | select-string -Pattern "<Command>|</Command>" | %{($_ -split '<Command>|</Command>')[1]}) -join "`n"
                $obj.'Start In'    = ($xmlData | select-string -Pattern "<WorkingDirectory>|</WorkingDirectory>" | %{($_ -split '<WorkingDirectory>|</WorkingDirectory>')[1]}) -join "`n"
                $obj.Arguments     = ($xmlData | select-string -Pattern "<Arguments>|</Arguments>" | %{($_ -split '<Arguments>|</Arguments>')[1]}) -join "`n"
            }
            $jobData += $obj
        }
    }
}
$jobdata | select hostname,taskname,'scheduled task state','run as user','next run time',status,'logon mode','last run time','last result',author,'task to run',arguments,'start in','Repeat: Every','Repeat: Until: Time','Repeat: Until: Duration','Repeat: Stop If Still Running','idle time','power management','delete task if not rescheduled','stop task if runs x hours and x minutes','schedule type','start-date','start time','end date',days,months,comment | export-csv $outFile -NoTypeInformation

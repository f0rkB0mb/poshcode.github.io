#======================================================================================================
# Created By: Anders Wahlqvist
# Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
#
# I also want to credit Dave Garnar who posted this helpful post:
# http://blog.davotronic5000.co.uk/getting-the-name-of-the-snapshot-creator-using-the-vsphere-task-api/
#======================================================================================================

function Get-VMSnapshotInformation
{
    <#
    .Synopsis
       Retrieves information about snapshots on a VM.

    .DESCRIPTION
       This function retrieves information about snapshots, including information on who created the snapshot and when.
       The creator information is not available in the "Get-Snapshot"-cmdlet.

    .EXAMPLE
       Get-VMSnapshotInformation -VM MyVirtualMachine

    .EXAMPLE
       Get-VM | Get-VMSnapshotInformation

    .PARAMETER VM
    The name of a VM to check for snapshots.

    #>

    [CmdletBinding()]
    Param
    (
        # Enter a name of the virtual machine
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Enter the name of a VM")]
        [Alias('Name')]
        $VM)

    Begin { }

    Process
    {
        foreach ($VirtualMachine in $VM) {
            $SnapShots = $null
            $SnapShots = Get-Snapshot $VirtualMachine

            if ($SnapShots -eq $null) {
                Continue
            }

            foreach ($SnapShot in $SnapShots) {
                $TaskMgr = Get-View TaskManager

                $Filter = New-Object VMware.Vim.TaskFilterSpec

                $Filter.Time = New-Object VMware.Vim.TaskFilterSpecByTime
                $Filter.Time.beginTime = ((($Snapshot.Created).AddSeconds(-5)).ToUniversalTime())
                $Filter.Time.timeType = "startedTime"
                $Filter.Time.EndTime = ((($Snapshot.Created).AddSeconds(5)).ToUniversalTime())

                $Filter.State = "success"

                $Filter.Entity = New-Object VMware.Vim.TaskFilterSpecByEntity
                $Filter.Entity.recursion = "self"
                $Filter.Entity.entity = (Get-Vm -Name $Snapshot.VM.Name).Extensiondata.MoRef

                $TaskCollector = Get-View ($TaskMgr.CreateCollectorForTasks($Filter))

                $TaskCollector.RewindCollector | Out-Null

                $Tasks = $TaskCollector.ReadNextTasks(100)
        
                $SnapUser = $null

                foreach ($Task in $Tasks) {
                    $GuestName = $Snapshot.VM
                    $Task = $Task | where {$_.DescriptionId -eq "VirtualMachine.createSnapshot" -and $_.State -eq "success" -and $_.EntityName -eq $GuestName}

                    If ($Task -ne $null) {
                        $SnapUser = $Task.Reason.UserName
                    }
                }

                $TaskCollector.DestroyCollector()

                $returnObject = New-Object System.Object
                $returnObject | Add-Member -Type NoteProperty -Name VMName -Value $SnapShot.VM.Name
                $returnObject | Add-Member -Type NoteProperty -Name Size -Value $SnapShot.SizeMB
                $returnObject | Add-Member -Type NoteProperty -Name Name -Value $SnapShot.Name
                $returnObject | Add-Member -Type NoteProperty -Name Id -Value $SnapShot.Id
                $returnObject | Add-Member -Type NoteProperty -Name Creator -Value $SnapUser
                $returnObject | Add-Member -Type NoteProperty -Name CreatedTime -Value $SnapShot.Created

                Write-Output $returnObject
            }
        }
    }

    End { }
}

<#
.SYNOPSIS
    Get the different protocol latencies for a specified volume.
.DESCRIPTION
    Get the different protocol latencies for a specified volume.
.PARAMETER Volume
    Volume to retrieve the latency.
.PARAMETER Protocol
    Protocol to collect latency for valid values are 'all','nfs','cifs','san','fcp','iscsi'
.PARAMETER Interval
    The interval between iterations in seconds, default is 15 seconds
.PARAMETER Count
    the number of iterations to execute, default is infinant
.PARAMETER Controller
    NetApp Controller to query.
.EXAMPLE
    .\Get-NaVolumeLatency.ps1 -Volume vol0 
    
    Get the average latency for all protocols on vol0
.EXAMPLE
    Get-NaVol | .\Get-NaVolumeLatency.ps1 -Interval 5 -count 5 | ft
    
    Get the average latency for all protocols, all volumes, 5 samples, 5 seconds apart.
.EXAMPLE
    .\Get-NaVolumeLatency.ps1 -Volume vol0 -protocol nfs
    
    Get the NFS latency for vol0
.NOTE
    #Requires -Version 2
    Uses the DataOnTap Toolkit Available http://communities.netapp.com/community/interfaces_and_tools/data_ontap_powershell_toolkit
#>
[cmdletBinding()]
Param(
    [Parameter(Mandatory=$true, 
        HelpMessage="Volume name to retrieve latency counters from.", 
        ValueFromPipelineByPropertyName=$true,
        ValueFromPipeLine=$true
    )]
    [Alias("Name")]
    [string]
    $Volume  
,
    [Parameter(Mandatory=$false)]
    [ValidateSet('all','nfs','cifs','san','fcp','iscsi')]
    [string]
    $Protocol='all'
,
    [Parameter(Mandatory=$false)]
    [int]
    $Interval=15
,
    [Parameter(Mandatory=$false)]
    [string]
    $count
,
    [Parameter(Mandatory=$false)]
    [NetApp.Ontapi.Filer.NaController]
    $Controller=($CurrentNaController)
)
Begin 
{
    IF ($Protocol -eq 'all')
    {
       $Counters = @(
            @{
                Counter = 'read_latency'
                Base     = ''
                unit     = ''
            }
       ,                    
            @{
                Counter = 'write_latency'
                Base     = ''
                unit     = ''
            }
       ,
            @{
                Counter = 'other_latency'
                Base     = ''
                unit     = ''
            }
       ,
            @{
                Counter = 'avg_latency'
                Base     = ''
                unit     = ''
            }
        )
    }
    Else
    {
        $Counters = @(
            @{
                Counter  = "$($Protocol.ToLower())_read_latency"
                Base     = ''
                unit     = ''
            }
        ,                   
            @{
                Counter = "$($Protocol.ToLower())_write_latency"
                Base     = ''
                unit     = ''
            }
        ,
            @{
                Counter = "$($Protocol.ToLower())_other_latency"
                Base     = ''
                unit     = ''
            }
        )
    }
    foreach ($c in $Counters)
    {
        Get-NaPerfCounter -Name 'volume' -Controller $Controller |
            Where-Object {$_.name -eq $c.Counter} |
            ForEach-Object {
                $c.Base = $_.BaseCounter
                $c.unit = switch ($_.unit) {
                    "microsec"  {1000}
                    "millisec"  {1}
                }
            }
    }
}
Process
{

    # Check if volume exists.
    if (-Not ((get-navol -Controller $Controller|select -ExpandProperty Name) -contains $Volume)) {
        Write-Warning "$volume doesn't exist!"
        break;
    }
    $iteration = 0
    $first = $null
    #loop untill we're done or Cntr ^c 
    while ((!$Count) -or ($iteration -le $count))
    {
        $second = New-Object Collections.HashTable
        Get-NaPerfData -Name volume `
            -Instances $Volume `
            -Controller $Controller `
            -Counters ($Counters|%{$_.base,$_.counter}) |
            Select-Object -ExpandProperty Counters | 
            ForEach-Object {
                $second.add($_.Name,$_.value)
            }
            
        if ($first -and $second)
        {
            $results = "" | Select-Object -Property ($Counters|%{$_.base,$_.counter})
            foreach ($v in $Counters)
            {
                IF ($second[$v.Base] -gt $first[$v.Base]) 
                {
                    #calculate the average over our interval
                    $avg = ($second[$v.Counter] - $first[$v.Counter])/($second[$v.Base] - $first[$v.Base])
                    #conver to ms
                    $results."$($v.Base)" = [math]::Round((($second[$v.Base] - $first[$v.Base])/$Interval))
                    $results."$($v.Counter)" = ("{0} ms" -f [math]::Round($avg/$v.unit))
                }
                Else
                {
                    $results."$($v.Base)" = 0
                    $results."$($v.Counter)" = "0 ms"
                }
            }
            Write-Output $results| Add-Member NoteProperty 'Volume' $Volume -PassThru
        }
        Start-Sleep -Seconds $Interval
        $first = $second.clone()
        $iteration++
    }
}

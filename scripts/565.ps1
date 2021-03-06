function cpu-usage
 { if ($Args)
        {$machine=$Args}
    else
        {$machine="localhost"}
      
#loop to refresh information cpu usage            
 while($auxiliary -ne 'Q')
       {

#first sample of processes
$before   = gwmi win32_perfrawdata_perfproc_process -ComputerName $machine
sleep -Milliseconds (100) 

#second sample of processes
$after = gwmi win32_perfrawdata_perfproc_process -ComputerName $machine

#hash list with the difference of two samples
$difference = @{}
#array with cpu percentage for each process
$result = @{}


#compare two samples and store difference in $difference["processname"]
foreach ($process_before in $before)
{ foreach ($process_after in $after)
    { if ($process_after.name -eq $process_before.name)
        {$difference_process = [long]$process_after.percentprocessortime -[long]$process_before.percentprocessortime
         $difference[$process_before.name] = $difference_process      
        }
    }
}

#total cpu time
$sum = $difference["_Total"]

#with all processes, we calculate percentaje
foreach ($i in $difference.keys)
    {$result[$i] = ((($difference.$i)/$sum)*100)
    }

          
#sort array descending
$result= (($result.GetEnumerator() | sort value -Descending)[1..10])

  
      Clear-Host
      Write-Host ""
      Write-Host "press Q to quit, another key to refresh"
    
     format-table -AutoSize -InputObject $result @{Label= "Name:"; Expression = {$_.name}},`
        @{Label = "percentaje CPU"; Expression= {"{0:n2}" -f ($_.Value)}}
      
        $auxiliary = $Host.UI.RawUI.ReadKey()
        $auxiliary = [string]$auxiliary.character
        $auxiliary=$auxiliary.toupper()       
        }      
}


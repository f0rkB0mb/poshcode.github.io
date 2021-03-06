#############################################################################################
#
# NAME: Search-WindowsUpdatesLocal.ps1
# AUTHOR: Rob Sewell http://sqldbawithabeard.com
# DATE:22/09/2013
#
# COMMENTS: Load function to show search for windows updates by KB locally
#
# USAGE: Search-WindowsUpdatesLocal KB2792100|Format-Table -AutoSize -Wrap
#    

Function Search-WindowsUpdatesLocal ([String] $Search)
{
$Search = $Search + "\d*" 
$Searcher = New-Object -comobject Microsoft.Update.Searcher
      $History = $Searcher.GetTotalHistoryCount()
     $Updates =  $Searcher.QueryHistory(1,$History)
# Define a new array to gather output
 $OutputCollection=  @()
     Foreach ($update in $Updates)
    {
    $Result = $null
    Switch ($update.ResultCode)
    {
        0 { $Result = 'NotStarted'}
        1 { $Result = 'InProgress' }
        2 { $Result = 'Succeeded' }
        3 { $Result = 'SucceededWithErrors' }
        4 { $Result = 'Failed' }
        5 { $Result = 'Aborted' }
        default { $Result = $_ }
    }
    $string = $update.title
    $SearchAnswer = $string | Select-String -Pattern $Search | Select-Object { $_.Matches } 
     $output = New-Object -TypeName PSobject
     $output | add-member NoteProperty “Date” -value $Update.Date
     $output | add-member NoteProperty “HotFixID” -value $SearchAnswer.‘ $_.Matches ‘.Value
     $output | Add-Member NoteProperty "Result" -Value $Result
     if($output.HotFixID)
     {
     $OutputCollection += $output
     }
 
    }

    $OutputCollection
    }


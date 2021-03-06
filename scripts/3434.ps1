#.Synopsis
#   Pivot multiple objects which are normalized with properties that are name, value pairs.
#.Description
#  Takes a series of objects where there are multiple rows to represent each object, with a pair of columns with the name and value of an additional property, and outputs new objects which have those new properties on them.
#.Example
#  Import-CSV data.csv | Pivot-Objects SamAccountName Attribute Value
#
#  Imports csv data containing multiple rows per-record such that a pair of columns named "Attribute" and "Value" are actually different in each row, and contain a name and value pair for attributes you want to add to the output objects.
#.Example
# @"
#   ID,    Attribute,     Value,       SamAccountName
#     ,    HoursPerWeek,  40,          J8329029
#     ,    LastDay,       20 Feb 2010, J8329029
#   12276, Job,           Sw Eng,      J8329029
#   2479,  HoursPerWeek,  35,          X5969731
#   2479,  LastDay,       20 Feb 2009, X5969731
#   2479,  Job,           Sr. SW Eng,  X5969731
#   2479,  Rate,          40,          X5969731
#   2479,  Bonus,         10000,       X5969731
# "@.Split("`n") | ConvertFrom-Csv | Pivot-Object -Group SamAccountName -Name Attribute -Value Value -Jagged
#   
#  This provides a full example, with data, and demonstrates how -Jagged works:
#  * Without -Jagged, you get two objects which each have the same properties. 
#  * With Jagged, only one one of the object output will have the Rate and Bonus properties, because there's values for the J8329029 user.
#.Notes
#  Author: Joel Bennett
#  function Pivot-Object {
[CmdletBinding()]
param(
   # The name of the property to merge on. Items with the same value in this column will be combined.
   [Parameter(Mandatory=$true)]
   [Alias("GroupBy")]
   [string]$GroupOnColumn,
   # The name of the property that has the names of the new properties to create.
   [Parameter(Mandatory=$true)]
   [string]$NameColumn,
   # The name of the property that has the values of the new properties to create.
   [string]$ValueColumn,
   [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
   # The input objects.  These can be passed on the pipeline as well (or instead).
   [object[]]$InputObject=@(),
   # If set, the objects that return only have the properties which were defined for them.
   # Otherwise, all properties that are defined for any object are assigned (even if that means they get null values) on all objects that are output.
   # See the examples for more information
   [switch]$Jagged
)
begin {
   [string[]]$Extra = @()
   [string[]]$NamedColumns = @()
   $CollectedInput = New-Object 'System.Collections.Generic.List[PSObject]'
}
process{
   $Extra += $InputObject | Get-Member -Type Properties | 
                            Select-Object -Expand Name -Unique | 
                            Where-Object {($Extra + @($GroupOnColumn,$NameColumn,$ValueColumn)) -NotContains $_}

   foreach($Incoming in $InputObject) {
      $NamedColumns += $Incoming.$NameColumn
      $null = $CollectedInput.Add($Incoming)
   }
}
end {
   $Columns = $NamedColumns | Select-Object -Unique | Where-Object { $_ }
   $Extra = $Extra | Select-Object -Unique | Where-Object { $_ -and ($Columns -NotContains $_) }
   
   ForEach($item in $CollectedInput | Group-Object $GroupOnColumn) {
      $thing = New-Object PSObject |
               Add-Member -Type NoteProperty -Name $GroupOnColumn -Value $Item.Name -passthru
 
      Write-Verbose "Group $($Item.Name)"
      foreach($c in $Extra) {
         $Value = $item.Group | Select-Object -Expand $c -Unique | Where-Object { $_ } | Select-Object -First 1
         Write-Verbose "Value $($Value)"
         if($Value) {
            Add-Member -input $thing -MemberType NoteProperty -Name $c -Value $Value
         }
      }
 
      foreach($i in $item.Group) {
         Add-Member -Input $thing -Type NoteProperty -Name $i.$NameColumn -Value $i.$ValueColumn
      }
      
      if($Jagged) {
         Write-Output $thing
      } else {
         # Note: I add the GroupOnColumn and Extra columns when -Jagged isn't specified ... I assume that's what you want.
         Write-Output $thing | select ([string[]]@(@($GroupOnColumn) + $columns + $extra))
      }
   }
}
#}



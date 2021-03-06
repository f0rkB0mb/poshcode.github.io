#.Synopsis
#  Pivot multiple objects which have properties that are name, value pairs
#.Description
#  Takes a series of objects where there are multiple rows which have a pair of columns where the values are different on ech row with the name and value of an additional property, and outputs new objects which have those new properties on them.
#
#.Parameter GroupOnColumn
#  The name of the property to merge on. Items with the same value in this column will be combined.
#.Parameter NameColumn
#  The name of the property that has the names of the new properties to create.
#.Parameter ValueColumn
#  The name of the property that has the values of the new properties to create
#.Parameter InputObject
#  The input objects.  These can be passed on the pipeline as well (or instead).
#.Parameter Jagged
#  If Jagged is set, the objects that return only have the properties defined on them. Otherwise, all properties that are defined for any object are assinged (with null values) on all objects that are output.
#.Example
#  Import-CSV data.csv | Pivot-Objects SamAccountName Attribute Value
#
#  Imports csv data containing multiple rows per-record such that a pair of columns named "Attribute" and "Value" are actually different in each row, and contain a name and value pair for attributes you want to add to the output objects.
#
#.Example
#@"
#  ID,    Attribute,     Value,       SamAccountName
#  12276, StdHrsPerWeek, 40,          J8329029
#  12276, UserStyle,     Fixed,       J8329029
#  2479,  LeaverId,      L1153731,    X5969731
#  2479,  LastDayOffice, 20 Feb 2009, X5969731
#"@.Split("`n") | ConvertFrom-Csv | Pivot-Objects SamAccountName Attribute Value
#
#
#
#.Notes
#  Author: Joel Bennett
#
#
# function Pivot-Object {
PARAM(
   [string]$GroupOnColumn
,  [string]$NameColumn
,  [string]$ValueColumn
,  [object[]]$InputObject=@()
,  [switch]$Jagged
)
PROCESS {
   if($_) {
      $InputObject += $_
   }
}
END {
   if($InputObject[0] -isnot [PSObject]) { 
            $first = new-object PSObject $first  
   } else { $first = $InputObject[0]   }

   [string[]]$extra = @( $first.PSObject.Properties | 
                         &{PROCESS{$_.Name}} | 
                         Where { ($columns -notcontains $_) -and 
                                 (@($NameColumn,$ValueColumn) -notContains $_)
                         } )

   [string[]]$columns = @($GroupOnColumn) + $extra +
                        @($InputObject | Select-Object -Expand $NameColumn | Sort-Object -Unique)

   ForEach($item in  $InputObject | group-Object $GroupOnColumn) {
      $thing = New-Object PSObject | 
               Add-Member -Type NoteProperty -Name $GroupOnColumn -Value $item.Name -passthru

      foreach($name in $extra) {
         Add-Member -input $thing -MemberType NoteProperty -Name $name -Value $item.Group[0].$name
      }

      foreach($i in $item.Group) { 
         Add-Member -Input $thing -Type NoteProperty -Name $i.$NameColumn -Value $i.$ValueColumn 
      }
      if($Jagged) {
         Write-Output $thing
      } else {
         Write-Output $thing | select $columns
      }
   }
   
}
#}


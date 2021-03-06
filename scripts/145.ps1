## Sort-Random.ps1
## Shuffle pipeline input into a random order...
## Note that, as with any Sort- function, this is a natural holdup in your pipeline
begin {
  $list = @()
}
process {
  $list += $_
}
end {
  $r = new-object Random
  1..$list.Count | % { $list[$r.Next(0,$list.Count-1)] }
}


## There's another way this could be done, which would result in being able to 
## reshuffle the output by just sorting.  If you needed to reshuffle a lot, 
## you could use this, and then to shuffle, just sort by RandomOrder
# begin{
#   $global:Random = new-object Random
# }
# process{
#   add-member -in $_ -p -n RandomOrder -t ScriptProperty -val {$Random.NextDouble()}
# }
##
## TO give you an idea of the difference, I liste files and shuffled them:
## While using the TOP method 1000 times takes about 36 seconds on my PC:
#### $files = gci
#### 1..1000 | %{$null = $files | sort-random }
## Using the bottom method, and then just resorting takes about 7 seconds:
#### $files = gci | Add-RandomOrder
#### 1..1000 | %{$null = $files | sort RandomOrder }
## However, if you're not reshuffling THE SAME list many times, the top method
## is much better, so I left that as the default....

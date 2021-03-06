###########################
# Drive Usage Report Generator
# By Jared Shippy
# Published: ?
# 
# Reports on Space consumed by each folder within the targeted folder.
# Useful for determining which home folders are driving disk sales.
###########################

###########################
#= List of Targets
$list = @(
    "c:\ProgramData"
    "c:\ProgramData"
    )


###########################
#= Location of Output File
[string]$outputPath = "C:\temp\"
$rootPath = "K:\"


###########################
#= HTML surroundings, build and place both files in the same folder as the script. I used
# https://google-developers.appspot.com/chart/interactive/docs/gallery/barchart#SimpleExample
# for generating the graphs
 
$htmlLead = get-content "htmlLead.html"
$htmlTail = get-content "htmlTail.html"
# END CONFING  ############################################################
# END CONFING  ###############################################################
# END CONFING  ############################################################



###########################
#= Function getSpaceUsed takes:
#= Target location 
function getSpaceUsed{
        #.Synopsis
        # Get folders, and space consumed by each
    [cmdletbinding()]
    param(
            # Target Location
            [Parameter(Mandatory=$True)]
            [string]$targetFol
        )
    $data = @()
    New-PSDrive -Name "K" -PSProvider FileSystem -Root $targetFol
    $colItems1 = Get-ChildItem $rootPath | ?{ $_.PSIsContainer}
    foreach ($i in $colItems1)
	   {
	   $colItems = (Get-ChildItem -force -recurse "$rootPath\$i" | Measure-Object -property length -sum)

       #= Make the size human readable
	   $size = "{0:N2}" -f ($colItems.sum / 1MB)
	   $size = $size.Replace(",","")

       $obj = New-Object PSObject -Property @{
            Folder = $i
            Size = [int]$size
       }


       $data += $obj
	   #$data += "$size, $i"
   }
   $data > ($outputPath + ($targetFol.Split("\")| select -last 1) + ".txt")
   #$object = New-Object PSObject -Property $data
   
   $formatting = $data | convertto-csv
   $formatting = $formatting[1..($formatting.count)] #convert, drop type line at top
   $formatting
   
   $first = $true
   $formatted = foreach ($_ in $formatting){
      if ($first -eq $true){
          "[" + ($_) + "],"
          $first = $false
        }else{
          "[" + ($_.split(",")[0] + "," + $_.split(",")[1].replace('"',"")) + "],"
        }

   }
   $formatted > ($outputPath + ($targetFol.Split("\")| select -last 1) + ".csv")
   
   #Build HTML File
   $htmlLead + $formatted + $htmlTail | out-file -force ($outputPath + ($targetFol.Split("\")| select -last 1) + ".html") -encoding ascii


   #$data | convertto-html > ($outputPath + ($targetFol.Split("\")| select -last 1) + ".html")
}





###########################
#= Runs the script
foreach ($_ in $list){
    getSpaceUsed $_
}

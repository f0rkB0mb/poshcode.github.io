#path of the script
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#This Module is needed to overcome to long paths
Import-Module "$($scriptPath)\AlphaFS.dll"

#List of shadow copy folders we need for restore
$list=@(
"\\myserver1\@GMT-2016.09.28-09.10.00\Folder1",
"\\myserver2\de\WinApps\@GMT-2016.09.28-12.10.00\Folder2"
)

#if true only output is shown
$only_output=$FALSE

#Warn user if only output is shown
if($only_output){
    Write-Host ""
    Write-Host "Only Output! Nothing is copied really!" -ForegroundColor Magenta
    Write-Host ""
}

#loop through each of the shadow paths
foreach($ShadowPath in $list){

    #Generate "real" path from shadow path
    $restorepath=""
    $split=$($ShadowPath -split "\@")
    $restorepath="$($split[0])$($split[1].Substring($($split[1].IndexOf("\"))+1))"

    #initialize count
    $count=0

    #Output Path
    Write-Host ""
    Write-Host "`tRestoring $($restorepath)" -ForegroundColor Yellow
    Write-Host ""

    #Ask to coontinue
    Read-Host -Prompt "Continue ? (press any key)"

    #Get all files in shadow copy
    $ShadowFiles = @([Alphaleonis.Win32.Filesystem.Directory]::GetFiles($($ShadowPath), '*', [System.IO.SearchOption]::AllDirectories))

    #Loop through each file
    foreach($file in $ShadowFiles){
    
        #Get original file name
        $original_file=""
        $original_file=$($file.Replace("$($ShadowPath)","$($restorepath)"))
        
        #Get original folder
        $original_folder=$original_file.Replace("$($($original_file.Split("\")[-1]))","")

        #if original folder doesn't exist, create it
        if(!([Alphaleonis.Win32.Filesystem.Directory]::Exists("$($original_folder)"))){
            if(!($only_output)){
                [Alphaleonis.Win32.Filesystem.Directory]::CreateDirectory("$($original_folder)")|Out-Null
            }
        }

        #If the original file doesn't exist copy the file from Shadowcopy
        if(!([Alphaleonis.Win32.Filesystem.File]::Exists("$($original_file)"))){
            
            Try{
                if(!($only_output)){
                    [Alphaleonis.Win32.Filesystem.File]::Copy($File, $original_file, $True)
                }
                
                #Output filename
                Write-Host "$($original_file.Split("\")[-1])" -ForegroundColor Green
                $count+=1
            }
            Catch{
                #Output filename
                Write-Host "$($original_file.Split("\")[-1])" -ForegroundColor Red
            }
        }
    }

    #Output count
    Write-Host ""
    Write-Host "$($count) Files restored"
    Write-Host ""

}



function Start-ISE ()
{
     <#
    .synopsis
        Load some file into ISE
    .Description
        Load some file into ISE
    .Parameter fileObjOrFileName
        file to be loaded
    .ReturnValue
        $null
    .Notes
        Author:  bernd kriszio
        e-mail: bkriszio@googlemail.com
        Created: 2008-12-28
        
        Requires: V2 CTP 3
        
        Todo: I do not see the solution using advanced functions for a variable number of arguments
            Start-ISE .\foo.ps1 .\bar.ps1
            fails.

    .Example       
        Start-ISE $profile 
         get-childitem *.ps1 | Start-ise
        'foo.ps1', 'bar.ps1' | Start-ise      
     #>

     param(
        [Parameter(Position = 0, Mandatory=$false, ValueFromPipeline=$True)]
        $fileObjOrFileName
    )
    
    PROCESS {
        if ($fileObjOrFileName -ne $null){
            if ($fileObjOrFileName.gettype().Name -eq 'FileInfo'){
                & "$PSHome/powershell_ise.exe" $fileObjOrFileName.Fullname
            }
            elseif ($fileObjOrFileName.gettype().Name -eq 'String') {
                & "$PSHome/powershell_ise.exe" "$(pwd)\$fileObjOrFileName"
            }
        }
      }
      
<#      End{
        foreach ($file in $args)
        {
            if ($file.gettype().Name -eq 'FileInfo'){
                & "$PSHome/powershell_ise.exe" $file.Fullname
            }
            elseif ($file.gettype().Name -eq 'String') {
                & "$PSHome/powershell_ise.exe" "$(pwd)\$file"
            }
        }
    }
#>   
}



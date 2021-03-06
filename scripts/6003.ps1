<#
.Synopsis
   Joins a list of text files into 1 large text file.
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Join-TextFile
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # Input text files. Alternatively, pipe a get-childitem into the function
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [System.IO.FileInfo[]]
        $TextFiles,

        # Text used as the separator
        [string]
        $Separator = (Get-Date -Format s)
    )

    Begin
    {
        
        Function Get-SHA256Hash($TextToHash)
        {
            $SHA256 = New-Object System.Security.Cryptography.SHA256Managed
            $ByteArray = [System.Text.Encoding]::UTF8.GetBytes($TextToHash)
            $HashByteArray = $SHA256.ComputeHash($ByteArray)
    
            Return [System.Convert]::ToBase64String($HashByteArray)
        }
        
        #Generate Unique string for this session

        $SessionID = Get-SHA256Hash ((gwmi win32_OperatingSystem|Select *) -join ";").ToString()

        $HeaderText = "##:Join-TextFile Start Seperator=#/$Separator/#;SessionID=$SessionID"
        $SeparatorStart = "##:Join-TextFile #/$Separator/# Begin Filename:#/<Filename>/# ContentsHash:#/<ContentsHash>/#"
        $SeparatorEnd = "##:Join-TextFile #/$Separator/# End Filename:#/<Filename>/#"
        $FooterText = "##:Join-TextFile End Seperator=#/$Separator/#;SessionID=$SessionID"

        Write-Output $HeaderText

    } #Begin



    
    Process
    {
        ForEach ($File in $TextFiles)
        {
            Write-Verbose $File
            $FileContents = Get-Content $File -Raw -Encoding UTF8
            $ContentsHash = Get-SHA256Hash $FileContents
            Write-Output ($SeparatorStart -replace '#\/\<Filename\>\/#',"#/$($File.Name)/#" -replace '#\/\<ContentsHash\>\/#',"#/$ContentsHash/#")
            Write-Output $FileContents
            Write-Output ($SeparatorEnd -replace '#\/\<Filename\>\/#$',"#/$($File.Name)/#")
        }
    } #Process
    
    End
    {
        Write-Output $FooterText
    } #End
}

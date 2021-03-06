function Get-ImageMetadata {
#.Synopsis
# pull EXIF, XMP, and other data from images using the BitmapMetaData
#.Example
# $image = Get-ImageMetadata C:\Users\JBennett\Pictures\3200x1200\02179_piertonowhere_interfacelift_com.jpg -verbose
# $image | fl *tiff*
# $image | fl *exif*

##   Usage:  ls *.jpg | Get-ImageMetaData | ft Length, LastWriteTime, Name, "36867"
##   Note that '36867' is the decimal value of (0x9003) the EXIF tag for DateTimeOriginal
##   For more information see: http://owl.phy.queensu.ca/~phil/exiftool/TagNames/EXIF.html
#####################################################################################################
## History:
##  - v1.0  - First release, retrieves all the data and stacks it somehow onto a FileInfo object
##  - v2.0  - Refactor for clarity and PowerShell 2.0 features
#####################################################################################################
param(
   [Parameter( ValueFromPipeLine = $true, ValueFromPipelineByPropertyname = $true, Mandatory = $true )]
   [ValidateScript( { Test-Path -Path $_ -PathType Leaf } )]
   [ValidatePattern('\.(jpg|tiff|bmp|png|gif)$')]
   [Alias("PSPath")]
   [string]$File
)
begin {
   $null = [Reflection.Assembly]::LoadWithPartialName("PresentationCore");
   
   function Get-ImageMetadata {
      PARAM(
         [Parameter(ValueFromPipeline=$true)]
         [System.Windows.Media.Imaging.BitmapFrame]$bitmapFrame
      ,
         [Parameter(ValueFromPipelineByPropertyName=$true)]
         $Metadata
      )
      begin {
         $ImageMetaData = @{}
      }
      process {
         foreach($Meta in $Metadata) {
            ## To read metadata, you use GetQuery.  To write metadata, you use SetQuery
            ## To WRITE metadata, you need a writer, 
            ##    but first you have to open the file ReadWrite, instead of Read only
            #  $writer = $bitmapFrame.CreateInPlaceBitmapMetadataWriter();
            #  if ($writer.TrySave()){ 
            #     $writer.SetQuery("/tEXt/{str=Description}", "Have a nice day."); 
            #  } else {
            #    Write-Host "Couldn't save data" -Fore Red
            #  }
            Write-Verbose "Getting metadata $Meta"
            $next = $bitmapFrame.MetaData.GetQuery($Meta);
            if($next.Location){
               $next | ForEach-Object { 
                  $ImageMetaData += Get-ImageMetadata $bitmapFrame "$($next.Location)$_"
               }
            } else {
               #  if($Meta.Split("/")[-1] -match "{ushort=(?<code>\d+)}") {
                  #  # $path = "0x{0:X}" -f [int]$matches["code"]
                  #  $Meta = [int]$matches["code"]
               #  }
               Write-Verbose "Metadata $Meta = $Next"
               $ImageMetaData.$Meta = $Next
            }
         }
      }
      end {
         write-output $ImageMetaData
      }
   }
}

process {
   $File = [string](Resolve-Path $File)
   
   try {
      $stream = new-object IO.FileStream $file, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read);
      $decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create( $stream, "None", "Default" )
      $ImageMetaData = $decoder.Frames[0] | Get-ImageMetadata
   } catch { 
      Write-Error "WARNING: $_"
      continue; 
   } finally {
      $stream.Close()
      $stream.Dispose()
   }

   $Output = New-Object IO.FileInfo $file
   foreach($key in $ImageMetaData.Keys) {
      Add-Member -in $Output -Type NoteProperty -Name $key -value $ImageMetaData.$key -Force
   }

   Write-Output $Output
}}





function Clear-ImageMetaData {

<#
    .Synopsis
        Modification of @Jaykuls function that writes (cleanes) images metadata.
    .Description
        Cleans meta data from file at $Path.
    .Link
        http://poshcode.org/617
    .Example
        Clear-ImageMetaData -Path c:\temp\test.jpg
        Opens test.jpg, reads, cleans metadata and closes it.
    .Example
        ls *.jpg | Clear-ImageMetaData
        Opens all .jpg files, and clears Meta Data for each one.
#>
[CmdletBinding()]
param (
    [Parameter(
                ValueFromPipeLine = $true,
                ValueFromPipelineByPropertyname = $true,
                Mandatory = $true
    )]
    [ValidateScript( { Test-Path -Path $_ -PathType Leaf } )]
    [ValidatePattern('\.(jpg|tiff|bmp|png|gif)$')]
    [string]$Path
)

process {

    try { 
        
        $Path = [string](Resolve-Path $Path)
        $stream = New-Object IO.FileStream $Path, 'Open', 'ReadWrite', 'ReadWrite'
        $decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create( $stream, "PreservePixelFormat", "Default" )
        $bitmapFrame = $decoder.Frames[0]
        
        foreach($meta in $bitmapFrame.MetaData) {
            $next = $bitmapFrame.MetaData.GetQuery($meta);
            if($next.Location){
               $next | ForEach-Object { 
                  Get-ImageMetadata $bitmapFrame "$($next.Location)$_" 
               }
            } else {
               if($path.Split("/")[-1] -match "{ushort=(?<code>\d+)}") {
                  # $path = "0x{0:X}" -f [int]$matches["code"]
                  $path = [int]$matches["code"]
               }
               Add-Member -in ($Global:ImageMetaData) -Type NoteProperty -Name $path -value $next -Force
            }
            
        $writer = $bitmapFrame.CreateInPlaceBitmapMetadataWriter()
        $Script = {
            param ($path)
            if($Writer.TrySave()) {
               foreach ($Element in $path) {
                   $writer.SetQuery($Element,'')   
                   & $Script $Element
               }
            } else {
               Write-Error "Can't write metadata to $Path"
            }
        }
        
        & $script $Writer
        
        $Stream.Flush()
        $Stream.Close()
        $Stream.Dispose()

    } catch {
        Write-Verbose $_
    } 
}
} # END function Clear-ImageMetaData

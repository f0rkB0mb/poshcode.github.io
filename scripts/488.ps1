#requires -version 2.0
## Set-Wallpaper - set your windows desktop wallpaper
###################################################################################################
## Usage:
##    Set-Wallpaper "C:\Users\Joel\Pictures\Others Stock\Potter Wasp.jpg" "Stretched"
##    ls *.jpg | get-random | Set-Wallpaper
###################################################################################################

add-type @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Wallpaper
{
   public enum Style : int
   {
       Tiled, Centered, Stretched
   }


   public class Setter {
      public const int SetDesktopWallpaper = 20;
      public const int UpdateIniFile = 0x01;
      public const int SendWinIniChange = 0x02;

      [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
      private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
      
      public static void SetWallpaper ( string path, Wallpaper.Style style ) {
         SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
         
         RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
         switch( style )
         {
             case Style.Stretched :
                 key.SetValue(@"WallpaperStyle", "2") ; 
                 key.SetValue(@"TileWallpaper", "0") ;
                 break;
             case Style.Centered :
                 key.SetValue(@"WallpaperStyle", "1") ; 
                 key.SetValue(@"TileWallpaper", "0") ; 
                 break;
             case Style.Tiled :
                 key.SetValue(@"WallpaperStyle", "1") ; 
                 key.SetValue(@"TileWallpaper", "1") ;
                 break;
         }
         key.Close();
      }
   }
}
"@

cmdlet Set-Wallpaper {
Param(
   [Parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
   [Alias("FullName")]
   [string]
   $Path
,
   [Parameter(Position=1, Mandatory=$true)]
   [Wallpaper.Style]
   $Style
)
   [Wallpaper.Setter]::SetWallpaper( (Convert-Path $Path), $Style )
}


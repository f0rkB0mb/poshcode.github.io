<#
.Synopsis
	Dynamically shortens the prompt based upon window size
.Notes
	I got really annoyed by having my PowerShell prompt extend across 2/3 of my window when in a deeply-nested directory structure.
	This shortens the prompt to roughly 1/3 of the window width, at a minimum showing the first and last piece of the path (usually the PSPROVIDER & the current directory)
	Additional detail is added, starting at the current directory's parent and working up from there.
	The omitted portion of the path is represented with an ellipsis (...)
#>

# Window title borrowed from Joel Bennett @ http://poshcode.org/1834
# This should go OUTSIDE the prompt function, it doesn't need re-evaluation
# We're going to calculate a prefix for the window title 
# Our basic title is "PoSh - C:\Your\Path\Here" showing the current path
if(!$global:WindowTitlePrefix) {
   # But if you're running "elevated" on vista, we want to show that ...
   if( ([System.Environment]::OSVersion.Version.Major -gt 5) -and ( # Vista and ...
         new-object Security.Principal.WindowsPrincipal (
            [Security.Principal.WindowsIdentity]::GetCurrent()) # current user is admin
            ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) )
   {
      $global:WindowTitlePrefix = "PoSh (ADMIN)"
   } else {
      $global:WindowTitlePrefix = "PoSh"
   }
}

function prompt {
# Put the full path in the title bar for reference
    $host.ui.rawui.windowtitle = $global:WindowTitlePrefix + " - " + $(get-location);
	
# Capture the maximum length of the prompt. If you want a longer prompt, adjust the math as necessary.
	$winWidth = $host.UI.RawUI.WindowSize.Width;
    $maxPromptPath = [Math]::Round($winWidth/3);
	
# In the PowerShell ISE (version 2.0 at least), $host.UI.RawUI.WindowSize.Widthis $null.
# For now, I'm just going to leave the default prompt for this scenario, as I don't work in the ISE.
    if (-not ($winWidth -eq $null)) {
        $currPath = (get-location).path;
        if ($currPath.length -ge $maxPromptPath){
            $pathParts = $currPath.split([System.IO.Path]::DirectorySeparatorChar);
# Absolute minimum path - PSPROVIDER and the current directory
            $myPrompt = $pathParts[0] + [System.IO.Path]::DirectorySeparatorChar+ "..." + [System.IO.Path]::DirectorySeparatorChar + $pathParts[$pathParts.length - 1];
            $counter = $pathParts.length - 2;
# This builds up the prompt until it reaches the maximum length we set earlier.
# Start at the current directory's parent and keep going up until the whole prompt reaches the previously-determined limit.
            while( ($myPrompt.replace("...","..."+[System.IO.Path]::DirectorySeparatorChar+$pathParts[$counter]).length -lt $maxPromptPath) -and ($counter -ne 0)) {
                $myPrompt = $myPrompt.replace("...","..."+[System.IO.Path]::DirectorySeparatorChar+$pathParts[$counter]);
                $counter--;
            }      
            $($myPrompt) + ">";    
        } else{
# If there's enough room for the full prompt, use the Powershell default prompt
            $(if (test-path variable:/PSDebugContext) { '[DBG]: ' } else { '' }) + 'PS ' + $(Get-Location) + $(if ($nestedpromptlevel -ge 1) { '>>' }) + '> '
        }
    }
}

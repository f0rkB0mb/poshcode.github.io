#requires -version 2.0
## ResolveAlias Module v2.0
########################################################################################################################
## Version History
## 1.0 - First Version. "It worked on my sample script"
## 1.1 - Now it parses the $(...) blocks inside strings
## 1.2 - Some tweaks to spacing and indenting (I really gotta get some more test case scripts)
## 1.3 - I went back to processing the whole script at once (instead of a line at a time)
##       Processing a line at a time makes it impossible to handle Here-Strings...
##       I'm considering maybe processing the tokens backwards, replacing just the tokens that need it
##       That would mean I could get rid of all the normalizing code, and leave the whitespace as-is
## 1.4 - Now resolves parameters too
## 1.5 - Fixed several bugs with command resolution (the ? => ForEach-Object problem)
##     - Refactored the Resolve-Line filter right out of existence
##     - Created a test script for validation, and 
## 1.6 - Added resolving parameter ALIASES instead of just short-forms
## 1.7 - Minor tweak to make it work in CTP3
## 2.0 - Modularized and v3 compatible
## * *TODO:* Put back the -FullPath option to resolve cmdlets with their snapin path
## * *TODO:* Add an option to put #requires statements at the top for each snapin used
########################################################################################################################
function Resolve-Command {
param( [string]$command )
   # aliases, functions, cmdlets, scripts, executables, normal files
   $cmds = @(Get-Command $command -EA "SilentlyContinue")
   if($cmds.Count -gt 1) {
      $cmd = @( $cmds | Where-Object { $_.Name -match "^$([Regex]::Escape($command))" })[0]
   } else {
      $cmd = $cmds[0]
   }
   if(!$cmd) {
      $cmd = @(Get-Command "Get-$command" -EA "SilentlyContinue" | Where-Object { $_.Name -match "^Get-$([Regex]::Escape($command))" })[0]
   }
   if( $cmd.CommandType -eq "Alias" ) {
      $cmd = Resolve-Command $cmd.Definition
   }
   return $cmd
}

function Expand-Alias {
#.Synopsis
#  Expands aliases and short parameters
#.Description
#  Expands all aliases (recursively) to actual functions/cmdlets/executables
#  Expands all short-form parameter names to their full versions
#  Works on files or strings, and can expand "inplace" on a file
#.Parameter Script
#  The script you want to expand aliases in
#.Parameter File
#  The script file you want to expand aliases in
#.Parameter InPlace
#  Enables replacing aliases in-place on files instead of into a new file
#.Parameter Unqualified
#  Allows you to leave the namespace (module name) off of commands
#  By default Expand-Alias will expand 'gc' to 'Microsoft.PowerShell.Management\Get-Content'
#  If you specify the Unqualified flag, it will expand to just 'Get-Content' instead.
   [CmdletBinding(ConfirmImpact="low",DefaultParameterSetName="Files")]
   param (
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Text")]
      [string]$Script
   ,
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Files")]
      [Alias("FullName","PSChildName","PSPath")]
      [IO.FileInfo]$File
   ,
      [Parameter( ParameterSetName="Files")] 
      [Switch]$InPlace
   , 
      [Parameter()]
      [Switch]$Unqualified
   )
   begin {
      Write-Debug $PSCmdlet.ParameterSetName
   }
   process {
      if($PSCmdlet.ParameterSetName -eq "Files") {
         if($File -is [System.IO.FileInfo]){
            $Script = (Get-Content $File -Delim ([char]0))            
         }
      }

      $Errors = $Null
      $Tokens = [System.Management.Automation.PSParser]::Tokenize($Script,[ref]$Errors)
      if($Errors) { 
         foreach($er in $Errors) { Write-Error $er }
         throw "There was an error parsing script (See above). We cannot expand aliases until the script parses without errors."
      }
      for($t = $Tokens.Count; $t -ge 0; $t--) {
         $token = $Tokens[$t]
         # DEBUG $token | fl * | out-host
         switch($token.Type) {
            "Command" {
               $cmd = Resolve-Command $token.Content
               Write-Verbose "Command $($token.Content) => $($cmd.Name)"
               if(!$Unqualified -and $cmd.ModuleName) { 
                  $command = '{0}\{1}' -f $cmd.ModuleName, $cmd.Name
               } else {
                  $command = $cmd.Name
               }
               $Script = $Script.Remove( $token.Start, $token.Length ).Insert( $token.Start, $command )
            }
            "CommandParameter" {
               for($c = $t; $c -ge 0; $c--) {
                  if( $Tokens[$c].Type -eq "Command" ) {
                     $cmd = Resolve-Command $Tokens[$c].Content
                     $short = $token.Content -replace "^-?","^"
                     $parameters = $cmd.ParameterSets | Select -expand Parameters
                     $param = @($parameters | Where-Object { $_.Name -match $short -or $_.Aliases -match $short} | Select -Expand Name -Unique)
                     if($param.Count -eq 1) {
                        Write-Verbose "Parameter $($token.Content) => -$($param[0])"
                        $Script = $Script.Remove( $token.Start, $token.Length ).Insert( $token.Start, "-$($param[0])" )
                     }
                     break
                  }
               }
            }
         }
      }

      switch($PSCmdlet.ParameterSetName) {
         "Text" {
            $Script
         }
         "Files" {
            switch($File.GetType()) {
               "System.IO.FileInfo" {
                  if($InPlace) {
                     $Script | Set-Content $File 
                  } else {
                     $Script
                  }
               }
               default { throw "We can't resolve a whole folder at once yet" }
            }
         }
         default { throw "ParameterSet: $($PSCmdlet.ParameterSetName)" }
      }
   }
}

Set-Alias Resolve-Alias Expand-Alias
Export-ModuleMember -Function * -Alias *


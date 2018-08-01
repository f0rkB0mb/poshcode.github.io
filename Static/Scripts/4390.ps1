function New-ScriptModule {
   #.Synopsis
   #  Generate a new module from some script files
   #.Description
   #  New-ScriptModule allows you to create a new script module by collecting one or more scripts into a new module directory, and then generating the psd1 and psm1 necessary to import them.
   #
   #  Additionally, it can upgrade existing script modules (or at least ones generated by New-ScriptModule) by updating the list of scripts.
   #.Example
   #  New-ScriptModule MyUtility *.ps1 -Author "Non Jaykul" -Description "My collection of utility functions"
   #
   #  This is the recommended way to run the New-ScriptModule cmdlet, providing a full Author name, and a real description. It collects all the script files in the present working directory and generates a new module "MyUtility" ...
   #.Example
   #  New-ScriptModule .\MyUtility *.ps1 -Author "Non Jaykul" -Description "My collection of utility functions"
   #
   #  Shows how to create a module in a specific path (rather than in the default ModulePath).  This example creates the folder "MyUtility" as a subfolder of the current folder
   #.Example
   #  New-ScriptModule MyUtility *.ps1, *\*.psd1 -recurse 
   #
   #  This example shows how to recursively collect all the script files in the directory and the data (language) files in it's sub-directories to recursively generate a new module "MyUtility" -- however, it leaves the author and description fields at default.
   #.Example
   #  New-ScriptModule ~\Documents\WindowsPowerShell\Modules\MyUtility -Upgrade
   #
   #  This example shows how to (re)generate the MyUtility module from all the files that have already been moved to that directory, and shows passing a specific module path instead of accepting the default path for modules.
   #
   #  If you use the first example to generate a module, and then you add some files to it, this is the simplest way to update it after adding new script files.  However, you can also create the module and move files there by hand, and then call this command-line to regenerate the psd1 and psm1 files and increment the version.
   #
   #  Note: the Upgrade parameter keeps the module GUID, increments the ModuleVersion.  You may provide additional parameters (like AuthorName) and overwrite those as well.
   #.Example
   #  Get-ChildItem *.ps1,*.psd1 -Recurse | New-ScriptModule MyUtility
   #
   #  This example shows how to pipe the files into the New-ScriptModule, and yet another approach to collecting the files needed.
   #.Notes
   #  Version History:
   #  v 4.4 Remove the 1-second sleep from the generated modules (oops, that was for testing)
   #  v 4.3 Change name to New-ScriptModule (to avoid overwriting existing New-Module)
   #        Remove constraint on ModuleName to support passing a path
   #        Changed default PowerShellVersion to current instead of current-1
   #  v 4.2 Minor changes to documentation and text strings
   #  v 4.1 Change the script list in the psm1 so it's easier to upgrade
   #        Add support for upgrading the file list without overwriting the file
   #        Add error handling and progress output for script import
   #  v 4.0 Put the script list into the psm1 so it can be signed (file bug against psd1)
   #        https://connect.microsoft.com/PowerShell/feedback/details/797141
   #  v 3.0 Add Upgrade support
   #  v 2.2 Add parameters and handling for the obvious New-ModuleManifest parameters
   #  v 2.1 Add generation of Verb list
   #  v 2.0 Import files from module manifest FileList instead
   #  v 1.1 Change to Resolve-Path and import-module
   #  v 1.0 Dot-source all files in module path
   [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="Medium", DefaultParameterSetName="OverwriteModule")]
   param(
      # The name of the module to create
      [Parameter(Position=0, Mandatory=$true)]
      [Alias("MP","ModuleName","Name","MN")]
      $ModulePath,

      # If set, appends to (increments) existing modules without prompting (shoule leave any customizations to your module in place):
      # * It only alters the file list in the psm1 (but will create one if it's missing)
      # * It only changes the manifest module version, and any explicitly set parameters
      [Parameter(Mandatory=$true, ParameterSetName="UpgradeModule")]
      [Switch]$Upgrade,

      # If set, overwrites existing modules without prompting
      [Parameter(ParameterSetName="OverwriteModule")]
      [Switch]$Force,

      # The script files to put in the module. Should be .ps1 files (but could be .psm1 too)
      [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="UpgradeModule")]
      [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="OverwriteModule")]
      [Alias("PSPath")]
      $Path,

      # Supports recursively searching for File
      [Switch]$Recurse,

      # The name of the author to use for the psd1 and copyright statement
      # (This is a passthru for New-ModuleManifest)
      [PSDefaultValue(Help = '$Env:UserName')]
      [String]$Author = $Env:UserName,

      # A short description of the contents of the module.
      # (This is a passthru for New-ModuleManifest)
      [Parameter(Position=1)]
      [PSDefaultValue(Help = 'A collection of script files by $Author')]
      [string]${Description} = "A collection of script files by $Author",

      # The vresion of the module 
      # (This is a passthru for New-ModuleManifest)
      [Parameter()]
      [PSDefaultValue(Help = "1.0 (when -Upgrade is set, increments the existing value to the nearest major version number)")]
      [Alias("MV","Version")]
      [Version]${ModuleVersion} = "1.0",

      # (This is a passthru for New-ModuleManifest)
      [AllowEmptyString()]
      [String]$CompanyName = "None (Personal Module)",

      # Specifies the minimum version of the Common Language Runtime (CLR) of the Microsoft .NET Framework that the module requires (Should be 2.0 or 4.0). Defaults to the (rounded) currently available ClrVersion.
      # (This is a passthru for New-ModuleManifest)
      [version]
      [PSDefaultValue(Help = 'Your current CLRVersion number (rounded to major.minor)')]
      ${ClrVersion} = $($PSVersionTable.CLRVersion.ToString(2)),

      # Specifies the minimum version of Windows PowerShell that will work with this module. Defaults to 1 less than your current version.
      # (This is a passthru for New-ModuleManifest)
      [version]
      [PSDefaultValue(Help = 'Your current PSVersion number (rounded to major.minor)')]
      [Alias("PSV")]
      ${PowerShellVersion} = $("{0:F1}" -f [Double]$PSVersionTable.PSVersion.ToString(2)),
      
      # Specifies modules that this module requires. (This is a passthru for New-ModuleManifest)
      [System.Object[]]
      [Alias("RM","Modules")]
      ${RequiredModules} = $null,
      
      # Specifies the assembly (.dll) files that the module requires. (This is a passthru for New-ModuleManifest)
      [AllowEmptyCollection()]
      [string[]]
      [Alias("RA","Assemblies")]
      ${RequiredAssemblies} = $null,

      # If set, enforces the allowed verb names on function exports
      [Switch]$StrictVerbs
   )

   begin {
      # Pick a reasonable location for putting modules...
      # The default is your user\Documents\WindowsPowerShell\Modules
      $ModuleBasePath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell\Modules"
      $PSModulePath = $Env:PSModulePath -split ";" | Resolve-Path
      # But if that's not in the PSModulePath, then we don't want to use it
      if($PSModulePath -notcontains $ModuleBasePath) {
         # Let's pick anything from your PSModulePath that's in your documents folder
         $ModuleBasePath = $PSModulePath -like "$([Environment]::GetFolderPath("MyDocuments"))*" | Select-Object -First 1
         if(!$ModuleBasePath) {
            # Or anything that's in your user profile at all
            $ModuleBasePath = $PSModulePath -like "$([Environment]::GetFolderPath("UserProfile"))*" | Select-Object -First 1
            # If all else fails, use the current directory
            if(!$ModuleBasePath) { $ModuleBasePath = $PWD }
         }
      }

      # Make sure ModulePath is actually a path...
      if(Test-Path $ModulePath -Type Container) {
         [String]$ModulePath = Resolve-Path $ModulePath
      } elseif(!$ModulePath.Contains([io.path]::DirectorySeparatorChar) -and !$ModulePath.Contains([io.path]::AltDirectorySeparatorChar)) {
         [String]$ModulePath = Join-Path $ModuleBasePath $ModulePath
      }
      [String]$ModuleName = Split-Path $ModulePath -Leaf

      # If they passed in the File(s) as a parameter
      if($Path) {
         Write-Verbose "Collecting Local Files: '$($Path -join "', '")'"
         $ScriptFiles = switch($Path) {
            {$_ -is [String]} { 
               if(Test-Path $_) {
                  Get-ChildItem $_ -Recurse:$Recurse | % { $_.FullName }
               } else { throw "Can't find the file '$_' doesn't exist." }
            }
            {$_ -is [IO.FileSystemInfo]} { $_.FullName }
            default { Write-Warning $_.GetType().FullName + " type not supported for `$Path" }
         }
      } else {
         $ScriptFiles = @()
      }
   }

   process {
      $ScriptFiles += switch($Path){
         {$_ -is [String]} { 
            if(Test-Path $_) {
               Resolve-Path $_ | % { $_.ProviderPath }
            } else { throw "Can't find the file '$_' doesn't exist." }
         }
         {$_ -is [IO.FileSystemInfo]} { $_.FullName }
         {$_ -eq $null}{ } # Older PowerShell version had issues with empty paths
         default { Write-Warning $_.GetType().FullName + " type not supported for `$Path" }
      }
   }

   end {
      # If there are errors in here, we need to stop before we really mess something up.
      $ErrorActionPreference = "Stop"

      # We support either generating a module from an existing module directory, 
      # or generating a module from loose files (but not both)
      if($ScriptFiles) {
         # We have script files, so let's make sure the directory is empty and then put our files in it
         if(!$Upgrade -and (Test-Path $ModulePath)) {
            if($Force -Or $PSCmdlet.ShouldContinue("The specified Module already exists: '$ModulePath'. Do you want to delete it and start over?", "Deleting '$ModulePath'")) {
               Write-Verbose "Deleting Directory: $ModulePath"
               Remove-Item $ModulePath -recurse
            } else {
               throw "The specified ModuleName '$ModuleName' already exists in '$ModulePath'. Please choose a new name, or specify -Force to overwrite that directory."
            }
         }

         if(!$Upgrade -or !(Test-Path $ModulePath)) {

            if((Test-Path (Split-Path $ModulePath)) -or $PSCmdlet.ShouldContinue("The directory tree for ModulePath doesn't already exist. Shall we create the following directory: '$ModulePath'?", "Creating '$ModulePath'")) {            
               try {
                  Write-Verbose "Creating Directory: $ModulePath"
                  $null = New-Item -Type Directory $ModulePath
               } catch [Exception]{
                  throw "Cannot create Module Directory: '$ModulePath' $_"
               }
            } else {
               throw "The specified ModulePath can't be created: '$ModulePath'"
            }
         }

         # Copy the files into the ModulePath, recreate directory paths where necessary
         foreach($file in Get-Item $ScriptFiles | Where { !$_.PSIsContainer }) {
            $Destination = Join-Path $ModulePath (Resolve-Path $file -Relative )
            if(!(Test-Path (Split-Path $Destination))) {
               Write-Verbose "Creating Directory: $Destination"
               $null = New-Item -Type Directory (Split-Path $Destination)
            }
            Copy-Item $file $Destination
         }
      } elseif(!$Upgrade) {
         throw "You must supply a value for -Path"
      }

      # We need to run the rest of this (especially the New-ModuleManifest stuff) from the ModulePath
      $ModulePath = Resolve-Path $ModulePath
      Push-Location $ModulePath

      # We'll list all the files in the module
      $FileList = @(Get-ChildItem -Recurse | Where { !$_.PSIsContainer } | Resolve-Path -Relative)
      # Make sure we list the RootModule even if it doesn't exist yet
      if(!$FileList -like "*${ModuleName}.psm1") { $FileList += "${ModuleName}.psm1" }

      Write-Verbose "Writing $($FileList.Count) files to manifest and $(($FileList -like "*.ps1").Count) to root module."
      $ReGeneratedFileList = @(
         '# BEGIN: REGeneratedCode: File list will be repopulated by New-ScriptModule'
         '$Scripts = @"'
         ''
         $($FileList -like "*.ps1") 
         ''
         '"@.trim() -split "\s*[\r\n]+\s*"'
         '# END REGeneratedCode'
      )

      try {
         # Create the RootModule if it doesn't exist yet
         if($Upgrade -and (Test-Path "${ModuleName}.psm1")) {
            Write-Verbose "Upgrading RootModule: ${ModuleName}.psm1"
            Set-Content "${ModuleName}.psm1" -Value @(
               $ReGeneratedFileList
               (Get-Content "${ModuleName}.psm1" -Delimiter ([char]0)) -replace "# BEGIN: REGeneratedCode:(?s:.*?)# END REGeneratedCode" -replace "[\r\n]+","`n"
            )
         } else {
            if($Force -Or !(Test-Path "${ModuleName}.psm1") -or $PSCmdlet.ShouldContinue("The specified '${ModuleName}.psm1' already exists in '$ModulePath'. Do you want to overwrite it?", "Creating new '${ModuleName}.psm1'")) {
               Write-Verbose "Generating new RootModule: ${ModuleName}.psm1"
               # Join the relative file paths into a string that will build an array in the script:
               Set-Content "${ModuleName}.psm1" -Value @(
                  $ReGeneratedFileList
                  ''
                  '# BEGIN: ONCEGeneratedCode: Will not be repopulated by New-ScriptModule'
                  'Push-Location $PSScriptRoot'
                  'foreach($script in $scripts | Resolve-Path -ErrorAction Continue) {'
                  '    Write-Progress "Loading $script" -Percent ($p++/$scripts.count)'
                  '    Import-Module $script -ErrorVariable LoadError -ErrorAction SilentlyContinue'
                  '    if($LoadError) {'
                  '        Write-Error (@("Failed to load script: $script") + $LoadError -join "`n`n")'
                  '    }'
                  '}'
                  'Pop-Location'
                  '# END ONCEGeneratedCode'
               )
            } else {
               throw "The specified Module '${ModuleName}.psm1' already exists in '$ModulePath'. Please create a new Module, or specify -Force to overwrite the existing one."
            }
         }


         if($Force -Or $Upgrade -or !(Test-Path "${ModuleName}.psd1") -or $PSCmdlet.ShouldContinue("The specified '${ModuleName}.psd1' already exists in '$ModulePath'. Do you want to update it?", "Creating new '${ModuleName}.psd1'")) {
            if($Upgrade -and (Test-Path "${ModuleName}.psd1")) {
               Import-LocalizedData -BindingVariable ModuleInfo -File "${ModuleName}.psd1" -BaseDirectory $ModulePath
            } else {
               # If there's no upgrade, then we want to use all the parameter (default) values, not just the PSBoundParameters:
               $ModuleInfo = @{
                  # ModuleVersion is special, because it will get incremented
                  ModuleVersion = 0.0
                  Author = $Author
                  Description = $Description
                  CompanyName = $CompanyName
                  ClrVersion = $ClrVersion
                  PowerShellVersion = $PowerShellVersion
                  RequiredModules = $RequiredModules
                  RequiredAssemblies = $RequiredAssemblies
                  # These we leave as-is for upgrades (if they're customized, don't change them)
                  TypesToProcess = $FileList -match ".*Types?\.ps1xml"
                  FormatsToProcess = $FileList -match ".*Formats?\.ps1xml"
                  NestedModules = $FileList -like "*.psm1" -notlike "*${ModuleName}.psm1"
                  FunctionsToExport = $Verbs
                  AliasesToExport = "*"
                  VariablesToExport = "${ModuleName}*"
                  CmdletsToExport = $Null
               }
            }

            $verbs = if($Strict){ Get-Verb | % { $_.Verb +"-*" } } else { "*-*" }

            # RootModule in v3, but this should keep it compatible with v2
            $Null = $ModuleInfo.Remove("RootModule")
            $ModuleInfo.ModuleToProcess = "${ModuleName}.psm1"

            # Overwrite existing values with the new truth ;)
            $ModuleInfo.Path = "${ModuleName}.psd1"           
            $ModuleInfo.ModuleVersion = [Math]::Floor(1.0 + $ModuleInfo.ModuleVersion).ToString("F1")
            $ModuleInfo.FileList = $FileList

            # Overwrite defaults and upgrade values with specified values (if any)
            $null = $PSBoundParameters.Remove("Path")
            $null = $PSBoundParameters.Remove("Force")
            $null = $PSBoundParameters.Remove("Upgrade")
            $null = $PSBoundParameters.Remove("Recurse")
            $null = $PSBoundParameters.Remove("ModulePath")
            foreach($key in $PSBoundParameters.Keys) {
               $ModuleInfo.$key = $PSBoundParameters.$key
            }

            Write-Verbose "Generating version $($ModuleInfo.ModuleVersion) of ${ModuleName}.psd1"
            New-ModuleManifest @ModuleInfo
            Get-Item $ModulePath
         }  else {
            throw "The specified Module Manifest '${ModuleName}.psd1' already exists in '$ModulePath'. Please create a new Module, or specify -Force to overwrite the existing one."
         }
      } catch {
         throw
      } finally {
         Pop-Location
      }
   }
}

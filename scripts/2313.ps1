#requires -version 2.0
#History:
# 1.0  - First public release (March 19, 2010)
# 2.0  - Private Build
#      - Included the Accelerator function inline
#      - Added a few default aliases
# 3.0  - September 3, 2010
#      - Included the New-ConstructorFunction feature (ripped from PowerBoots to serve a more generic and powerful purpose!)
#      - New-ConstructorFunction and Import-ConstructorFunctions depend on the Autoload Module: http://poshcode.org/2312
#      - NOTE: You should really have a Reflection.psd1 with the contents: @{ RequiredModules = @("Autoload"); GUID="64b5f609-970f-4e65-b02f-93ccf3e60cbb"; ModuleVersion="3.0.0.0" }
function Get-Type {
   <#
   .Synopsis
      Gets the types that are currenty loaded in .NET, or gets information about a specific type
   .Description
      Gets information about one or more loaded types, or gets the possible values for an enumerated type or value.
   .Parameter Assembly
      The Assemblies to search for types.
      Can be an actual Assembly object or a regex to pass to Get-Assembly.
   .Parameter TypeName
      The type name(s) to search for (wildcard patterns allowed).
   .Parameter BaseType
      A Base type they should derive from (wildcard patterns allowed).
   .Parameter Enum
      An enumeration to list all of enumeration values for 
   .Parameter Namespace
      A namespace to restrict where we selsect types from (wildcard patterns allowed).
   .Parameter Force
      Causes Private types to be included
   .Example
      Get-Type
       
      Gets all loaded types (takes a VERY long time to print out)
   .Example
      Get-Type -Assembly ([PSObject].Assembly)
       
      Gets types from System.Management.Automation
   .Example
      [Threading.Thread]::CurrentThread.ApartmentState | Get-Type
       
      Gets all of the possible values for the ApartmentState property
   .Example
      [Threading.ApartmentState] | Get-Type
       
      Gets all of the possible values for an apartmentstate
   #>
   [CmdletBinding(DefaultParameterSetName="Assembly")]   
   param(
   # The assembly to collect types from
   [Parameter(ValueFromPipeline=$true)]
   [PsObject[]]$Assembly
,
   # The type names to return from
   [Parameter(Mandatory=$false)]
   [String[]]$TypeName
,
   # The type names to return from
   [Parameter(Mandatory=$false)]
   [String[]]$Namespace
,
   # A Base Type they should derive from 
   [Parameter(Mandatory=$false)]
   [String[]]$BaseType
,
   # The enumerated value to get all of the possibilties of
   [Parameter(ParameterSetName="Enum", ValueFromPipeline=$true)]
   [PSObject]$Enum
, 
   [Parameter()][Alias("Private","ShowPrivate")]
   [Switch]$Force
   )

   process {
      if($psCmdlet.ParameterSetName -eq 'Enum') {
         if($Enum -is [Enum]) {
            [Enum]::GetValues($enum.GetType())
         } elseif($Enum -is [Type] -and $Enum.IsEnum) {
            [Enum]::GetValues($enum)
         } else {
            throw "Specified Enum is neither an enum value nor an enumerable type"
         }
      }
      else {
         if($Assembly -as [Reflection.Assembly[]]) { 
            ## This is what we expected, move along
         } elseif($Assembly -as [String[]]) {
            $Assembly = Get-Assembly $Assembly
         } elseif(!$Assembly) {
            $Assembly = [AppDomain]::CurrentDomain.GetAssemblies()
         }
           
         :asm foreach ($asm in $assembly) {
            Write-Verbose "Testing Types from Assembly: $($asm.Location)"
            if ($asm) { 
               $asm.GetTypes() | Where {
                  ( $Force -or $_.IsPublic ) -AND
                  ( !$Namespace -or $( foreach($n in $Namespace) { $_.Namespace -like $n  } ) ) -AND
                  ( !$TypeName -or $( foreach($n in $TypeName) { $_.Name -like $n -or $_.FullName -like $n } ) -contains $True ) -AND
                  ( !$BaseType -or $( foreach($n in $BaseType) { $_.BaseType -like $n } ) -contains $True )
               }
            }
         }
      }
   }
}

function Add-Assembly {
#.Synopsis
#  Load assemblies 
#.Description
#  Load assemblies from a folder
#.Parameter Path
#  Specifies a path to one or more locations. Wildcards are permitted. The default location is the current directory (.).
#.Parameter Passthru
#  Returns System.Runtime objects that represent the types that were added. By default, this cmdlet does not generate any output.
#  Aliased to -Types
#.Parameter Recurse
#  Gets the items in the specified locations and in all child items of the locations.
# 
#  Recurse works only when the path points to a container that has child items, such as C:\Windows or C:\Windows\*, and not when it points to items that do not have child items, such as C:\Windows\*.dll
[CmdletBinding()]
param(
   [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true, Position=0)]
   [Alias("PSPath")]
   [string[]]$Path = "."
,
   [Alias("Types")]
   [Switch]$Passthru
,
   [Switch]$Recurse
)
process {
   foreach($file in Get-ChildItem $Path -Filter *.dll -Recurse:$Recurse) {
      Add-Type -Path $file.FullName -Passthru:$Passthru | Where { $_.IsPublic }
   }
}
}

function Get-Assembly {
<#
.Synopsis 
   Get a list of assemblies available in the runspace
.Description
   Returns AssemblyInfo for all the assemblies available in the current AppDomain, optionally filtered by partial name match
.Parameter Name
   A regex to filter the returned assemblies. This is matched against the .FullName or Location (path) of the assembly.
#>
[CmdletBinding()]
param(
   [Parameter(ValueFromPipeline=$true, Position=0)]
   [string[]]$Name = ''
)
process {
   [appdomain]::CurrentDomain.GetAssemblies() | Where {  $(foreach($n in $Name){$_.FullName -match $n -or $_.Location -match $n }) -contains $True }
}
}

function Get-Constructor {
<#
.Synopsis 
   Returns RuntimeConstructorInfo for the (public) constructor methods of the specified Type.
.Description
   Get the RuntimeConstructorInfo for a type and add members "Syntax," "SimpleSyntax," and "Definition" to each one containing the syntax information that can use to call that constructor.
.Parameter Type
   The type to get the constructor for
.Parameter Force
   Force inclusion of Private and Static constructors which are hidden by default.
.Parameter NoWarn
   Serves as the replacement for the broken -WarningAction. If specified, no warnings will be written for types without public constructors.
.Example
   Get-Constructor System.IO.FileInfo
   
   Description
   -----------
   Gets all the information about the single constructor for a FileInfo object. 
.Example
   Get-Type System.IO.*info mscorlib | Get-Constructor -NoWarn | Select Syntax
   
   Description
   -----------
   Displays the constructor syntax for all of the *Info objects in the System.IO namespace. 
   Using -NoWarn supresses the warning about System.IO.FileSystemInfo not having constructors.
  
.Example
   $path = $pwd
   $driveName = $pwd.Drive
   $fileName = "$Profile"
   Get-Type System.IO.*info mscorlib | Get-Constructor -NoWarn | ForEach-Object { Invoke-Expression $_.Syntax }
   
   Description
   -----------
   Finds and invokes the constructors for DirectoryInfo, DriveInfo, and FileInfo.
   Note that we pre-set the parameters for the constructors, otherwise they would fail with null arguments, so this example isn't really very practical.


#>
[CmdletBinding()]
param( 
   [Parameter(Mandatory=$true, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$true, Position=0)]
   [Alias("ParameterType")]
   [Type]$Type
,  [Switch]$Force 
,  [Switch]$NoWarn
)
   process { 
      $type.GetConstructors() | Where-Object { $Force -or $_.IsPublic -and -not $_.IsStatic } -OutVariable ctor | Select *,
         @{ name = "TypeName"; expression = { $_.ReflectedType.FullName } },
         @{ name = "Definition";
            expression = {Get-MemberSignature $_ -Simple}
         },
         @{ name = "Syntax";
            expression = {Get-MemberSignature $_ -Simple}
         },
         @{ name = "SafeSyntax";
            expression = {Get-MemberSignature $_}
         }
      if(!$ctor -and !$NoWarn) { Write-Warning "There are no public constructors for $($type.FullName)" }
   }
}

function Get-Method {
<#
.Synopsis 
   Returns MethodInfo for the (public) constructor methods of the specified Type.
.Description
   Get the MethodInfo for a type and add members "Syntax," "SimpleSyntax," and "Definition" to each one containing the syntax information that can use to call that constructor.
.Parameter Type
   The type to get methods on
.Parameter Name
   The name(s) of the method(s) you want to retrieve (Accepts Wildcard Patterns)
.Parameter Force
   Force inclusion of Private methods and property accessors which are hidden by default.

#>
[CmdletBinding(DefaultParameterSetName="Type")]
param( 
   [Parameter(ParameterSetName="Type", Mandatory=$true, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$true, Position=0)]
   [Type]$Type
,
   [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=1)]
   [String[]]$Name ="*"
,  [Switch]$Definition
,  [Switch]$Force 
)
   process { 
      foreach($method in 
         $type.GetMethods() + $type.GetConstructors() | Where-Object { $Force -or $_.IsPublic } | 
         # Hide the Property accessor methods
         Where-Object { $Force -or !$_.IsSpecialName -or $_.Name -notmatch "^get_|^set_" } |
         Where-Object { $( foreach($n in $Name) { $_.Name -like $n } ) -contains $True } )
      {
         $method |
         Add-Member NoteProperty TypeName   -Value $($method.ReflectedType.FullName     ) -Passthru |
         Add-Member NoteProperty Definition -Value $(Get-MemberSignature $method -Simple) -Passthru |
         Add-Member AliasProperty Syntax Definition -Passthru |
         #Add-Member NoteProperty Syntax     -Value $(Get-MemberSignature $method -Simple) -Passthru |
         Add-Member NoteProperty SafeSyntax -Value $(Get-MemberSignature $method        ) -Passthru
      }
   }
}

function Get-MemberSignature {
[CmdletBinding()]
param(
   [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
   [System.Reflection.MethodBase]$MethodBase,
   [Switch]$Simple
)
process {
   $parameters = $(
      foreach($param in $MethodBase.GetParameters()) {
         # Write-Host $param.ParameterType.FullName.TrimEnd('&'), $param.Name -fore cyan
      
         if($param.ParameterType.Name.EndsWith('&')) { $ref = '[ref]' } else { $ref = '' }
         if($param.ParameterType.IsArray) { $array = ',' } else { $array = '' }
         if($Simple) { 
            '{0} {1}' -f $parm.ParameterType.FullName, $param.Name
         } else {
            '{0}({1}[{2}]${3})' -f $ref, $array, $param.ParameterType.FullName.TrimEnd('&'), $param.Name
         }
      }
   )
   
   if($MethodBase.IsConstructor) {
      "New-Object $($MethodBase.ReflectedType.FullName) $($parameters -join ', ')"
   } elseif($Simple) {
      "$($MethodBase.ReturnType.FullName) $($MethodBase.Name)($($parameters -join ', '))"
   } elseif($MethodBase.IsStatic) {
      "[$($MethodBase.ReturnType.FullName)] [$($MethodBase.ReflectedType.FullName)]::$($MethodBase.Name)($($parameters -join ', '))"
   } else {
      "[$($MethodBase.ReturnType.FullName)] `$$($MethodBase.ReflectedType.Name)Object.$($MethodBase.Name)($($parameters -join ', '))"
   }
}
}

function Read-Choice {
[CmdletBinding()]
param(
   [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
   [hashtable[]]$Choices
,
   [Parameter(Mandatory=$False)]
   [string]$Caption = "Please choose!"
,  
   [Parameter(Mandatory=$False)]
   [string]$Message = "Choose one of the following options:"
,  
   [Parameter(Mandatory=$False)]
   [int[]]$Default  = 0
,  
   [Switch]$MultipleChoice
,
   [Switch]$Passthru
)
begin {
   [System.Collections.DictionaryEntry[]]$choices = $choices | % { $_.GetEnumerator() }
}
process {
   $Descriptions = [System.Management.Automation.Host.ChoiceDescription[]]( $(
                     foreach($choice in $choices) {
                        New-Object System.Management.Automation.Host.ChoiceDescription $choice.Key,$choice.Value
                     } 
                   ) )

   if(!$MultipleChoice) { [int]$Default = $Default[0] }

   [int[]]$Answer = $Host.UI.PromptForChoice($Caption,$Message,$Descriptions,$Default)

   if($Passthru) {
      Write-Verbose "$Answer"
      Write-Output  $Descriptions[$Answer]
   } else {
      Write-Output $Answer
   }
}
}

function Get-Argument {
param(
   [Type]$Target
,  [String]$Method
,  $Arguments
)
end {
trap {
   write-error $_
   break
}
   Write-Verbose "Get $Method Method on $($Target.FullName):"
   $MethodBase = Get-Method $target $Method
   Write-Verbose $($MethodBase | Out-String)
   if(@($MethodBase).Count -gt 1) {
      $i = 0
      $i = Read-Choice -Choices $(foreach($mb in $MethodBase) { @{ "$($mb.SafeSyntax) &$($i = $i+1;$i)`b`n" =  $mb.SafeSyntax } }) -Default ($MethodBase.Count-1) -Caption "Choose a Method." -Message "Please choose which method overload to invoke:"
      [System.Reflection.MethodBase]$MethodBase = $MethodBase[$i]
   }

   ForEach($parameter in $MethodBase.GetParameters()) {
      $found = $false
      For($a =0;$a -lt $Arguments.Count;$a++) {
         if($argument[$a] -as $parameter.ParameterType) {
            Write-Output $argument[$a]
            if($a -gt 0 -and $a -lt $Arguments.Count) {
               $Arguments = $Arguments | Select -First ($a-1) -Last ($Arguments.Count -$a)
            } elseif($a -eq 0) {
               $Arguments = $Arguments | Select -Last ($Arguments.Count - 1)
            } else { # a -eq count
               $Arguments = $Arguments | Select -First ($Arguments.Count - 1)
            }
            $found = $true
            break
         }
      }
      if(!$Found) {
         $userInput = Read-Host "Please enter a [$($parameter.ParameterType.FullName)] value for $($parameter.Name)"
         if($userInput -match '^{.*}$' -and !($userInput -as $parameter.ParameterType)) {
            Write-Output ((Invoke-Expression $userInput) -as $parameter.ParameterType)
         } else {
             Write-Output ($userInput -as $parameter.ParameterType)
         }
      }
   }
}
}

function Invoke-Member {
[CmdletBinding()]
param(        
   [parameter(position=0, valuefrompipeline=$true, mandatory=$true)]
   [allownull()]
   [allowemptystring()]
   $InputObject
,
   [parameter(position=1, mandatory=$true)]
   [validatenotnullorempty()]
   $Method
,
   [parameter(valuefromremainingarguments=$true)]
   [allowemptycollection()]
   [object[]]$Arguments
,
   [parameter()]
   [switch]$Static
)
#  begin {
   #  if(!(get-member SafeSyntax -input $method -type Property)){
      #  if(get-member Name -inpup $Method -Type Property) {
         #  $Method = Get-Method $InputObject $Method.Name
      #  } else {
         #  $Method = Get-Method $InputObject $Method
      #  }
   #  }
   #  $SafeSyntax = [ScriptBlock]::Create( $Method.SafeSyntax )
#  }
process {
   #  if ($InputObject) 
   #  {
      #  if ($InputObject | Get-Member $Method -static:$static) 
      #  {

         if ($InputObject -is [type]) {
             $target = $InputObject
         } else {
             $target = $InputObject.GetType()
         }
      
         if($Method -match "ctor|constructor") {
            $Method = ".ctor"
            [System.Reflection.BindingFlags]$flags = "CreateInstance"
            $InputObject = $Null
         } else {
            [System.Reflection.BindingFlags]$flags = "IgnoreCase,Public,InvokeMethod"
            if($Static) { $flags += "Static" } else { $flags += "Instance" }
         }
         
            
         [Object[]]$Parameters = Get-Argument $target $Method $Arguments
         
         Write-Verbose "$($Parameters | %{ '[' + $_.GetType().FullName + ']' + $_ })"
            
         try {
            Write-Verbose "Invoking $Method on [$target]$InputObject with $flags and $Parameters"
            Write-Verbose "[$($target.FullName)].InvokeMember('$Method', '$flags', `$null, '$InputObject', ([object[]]($(($Parameters | %{ '[' + $_.GetType().FullName + ']''' + $_ + ''''}) -join', '))))"
             $target.InvokeMember($Method, $flags, $null, $InputObject, $Parameters)
         } catch {
             if ($_.Exception.Innerexception -is [MissingMethodException]) {
                 write-warning "Method argument count (or type) mismatch."
             }
         }
      #  } else {
         #  write-warning "Method $Method not found."
      #  }
   #  }
}
}

function Invoke-Generic {
#.Synopsis
#  Invoke Generic method definitions via reflection:
[CmdletBinding()]
param( 
   [Parameter(Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
   [Alias('On','Type')]
   $InputObject
,
   [Parameter(Position=1,ValueFromPipelineByPropertyName=$true)]
   [Alias('Named')]
   [string]$MethodName
,
   [Parameter(Position=2)]
   [Alias('Returns')]
   [Type]$ReturnType
, 
   [Parameter(Position=3, ValueFromPipelineByPropertyName=$true)]
   [Type[]]$ArgumentTypes
, 
   [Parameter(Position=4, ValueFromRemainingArguments=$true, ValueFromPipelineByPropertyName=$true)]
   [Object[]]$WithArgs
)
process {
   $Type = $InputObject -as [Type]
   if(!$Type) { $Type = $InputObject.GetType() }
   
   if($WithArgs) {
      if(!$ArgumentTypes) {
         [Type[]]$ArgumentTypes = $withArgs | % { $_.GetType() }   
      }
      [Object[]]$Arguments = $withArgs | %{ $_.PSObject.BaseObject }

      $Type.GetMethod($MethodName, $ArgumentTypes).MakeGenericMethod($returnType).Invoke( $on, $Arguments )
   } else {
      [Type[]]$ArgumentTypes = New-Object Type[] 0
      $Type.GetMethod($MethodName, $ArgumentTypes).MakeGenericMethod($returnType).Invoke( $on )
   }
   
} }

# get a reference to the Type   
$xlr8r = [type]::gettype("System.Management.Automation.TypeAccelerators")  

function Import-Namespace {
[CmdletBinding()]
param(
   [Parameter(ValueFromPipeline=$true)]
   [string]$Namespace
,  
   [Switch]$Force
)
   Get-Type -Namespace $Namespace -Force:$Force | Add-Accelerator
}

function Add-Accelerator {
<#
   .Synopsis
      Add a type accelerator to the current session
   .Description
      The Add-Accelerator function allows you to add a simple type accelerator (like [regex]) for a longer type (like [System.Text.RegularExpressions.Regex]).
   .Example
      Add-Accelerator list System.Collections.Generic.List``1
      $list = New-Object list[string]
      
      Creates an accelerator for the generic List[T] collection type, and then creates a list of strings.
   .Example
      Add-Accelerator "List T", "GList" System.Collections.Generic.List``1
      $list = New-Object "list t[string]"
      
      Creates two accelerators for the Generic List[T] collection type.
   .Parameter Accelerator
      The short form accelerator should be just the name you want to use (without square brackets).
   .Parameter Type
      The type you want the accelerator to accelerate (without square brackets)
   .Notes
      When specifying multiple values for a parameter, use commas to separate the values. 
      For example, "-Accelerator string, regex".
      
      PowerShell requires arguments that are "types" to NOT have the square bracket type notation, because of the way the parsing engine works.  You can either just type in the type as System.Int64, or you can put parentheses around it to help the parser out: ([System.Int64])

      Also see the help for Get-Accelerator and Remove-Accelerator
   .Link
      http://huddledmasses.org/powershell-2-ctp3-custom-accelerators-finally/
      
#>
[CmdletBinding()]
param(
   [Parameter(Position=0,ValueFromPipelineByPropertyName=$true)]
   [Alias("Key","Name")]
   [string[]]$Accelerator
,
   [Parameter(Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
   [Alias("Value","FullName")]
   [type]$Type
)
process {
   # add a user-defined accelerator  
   foreach($a in $Accelerator) { 
      $xlr8r::Add( $a, $Type) 
      trap [System.Management.Automation.MethodInvocationException] {
         if($xlr8r::get.keys -contains $a) {
            if($xlr8r::get[$a] -ne $Type) {
               Write-Error "Cannot add accelerator [$a] for [$($Type.FullName)]`n                  [$a] is already defined as [$($xlr8r::get[$a].FullName)]"
            }
            Continue;
         } 
         throw
      }
   }
}
}

function Get-Accelerator {
<#
   .Synopsis
      Get one or more type accelerator definitions
   .Description
      The Get-Accelerator function allows you to look up the type accelerators (like [regex]) defined on your system by their short form or by type
   .Example
      Get-Accelerator System.String
      
      Returns the KeyValue pair for the [System.String] accelerator(s)
   .Example
      Get-Accelerator ps*,wmi*
      
      Returns the KeyValue pairs for the matching accelerator definition(s)
   .Parameter Accelerator
      One or more short form accelerators to search for (Accept wildcard characters).
   .Parameter Type
      One or more types to search for.
   .Notes
      When specifying multiple values for a parameter, use commas to separate the values. 
      For example, "-Accelerator string, regex".
      
      Also see the help for Add-Accelerator and Remove-Accelerator
   .Link
      http://huddledmasses.org/powershell-2-ctp3-custom-accelerators-finally/
#>
[CmdletBinding(DefaultParameterSetName="ByType")]
param(
   [Parameter(Position=0, ParameterSetName="ByAccelerator", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
   [Alias("Key","Name")]
   [string[]]$Accelerator
,
   [Parameter(Position=0, ParameterSetName="ByType", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
   [Alias("Value","FullName")]
   [type[]]$Type
)
process {
   # add a user-defined accelerator  
   switch($PSCmdlet.ParameterSetName) {
      "ByAccelerator" { 
         $xlr8r::get.GetEnumerator() | % {
            foreach($a in $Accelerator) {
               if($_.Key -like $a) { $_ }
            }
         }
         break
      }
      "ByType" { 
         if($Type -and $Type.Count) {
            $xlr8r::get.GetEnumerator() | ? { $Type -contains $_.Value }
         }
         else {
            $xlr8r::get.GetEnumerator() | %{ $_ }
         }
         break
      }
   }
}
}

function Remove-Accelerator {
<#
   .Synopsis
      Remove a type accelerator from the current session
   .Description
      The Remove-Accelerator function allows you to remove a simple type accelerator (like [regex]) from the current session. You can pass one or more accelerators, and even wildcards, but you should be aware that you can remove even the built-in accelerators.
      
   .Example
      Remove-Accelerator int
      Add-Accelerator int Int64
      
      Removes the "int" accelerator for Int32 and adds a new one for Int64. I can't recommend doing this, but it's pretty cool that it works:
      
      So now, "$(([int]3.4).GetType().FullName)" would return "System.Int64"
   .Example
      Get-Accelerator System.Single | Remove-Accelerator
      
      Removes both of the default accelerators for System.Single: [float] and [single]
   .Example
      Get-Accelerator System.Single | Remove-Accelerator -WhatIf
      
      Demonstrates that Remove-Accelerator supports -Confirm and -Whatif. Will Print:
         What if: Removes the alias [float] for type [System.Single]
         What if: Removes the alias [single] for type [System.Single]
   .Parameter Accelerator
      The short form accelerator that you want to remove (Accept wildcard characters).
   .Notes
      When specifying multiple values for a parameter, use commas to separate the values. 
      For example, "-Accel string, regex".
      
      Also see the help for Add-Accelerator and Get-Accelerator
   .Link
      http://huddledmasses.org/powershell-2-ctp3-custom-accelerators-finally/
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
   [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
   [Alias("Key","FullName")]
   [string[]]$Accelerator
)
process {
   foreach($a in $Accelerator) {
      foreach($key in $xlr8r::Get.Keys -like $a) { 
         if($PSCmdlet.ShouldProcess( "Removes the alias [$($Key)] for type [$($xlr8r::Get[$key].FullName)]",
                                     "Remove the alias [$($Key)] for type [$($xlr8r::Get[$key].FullName)]?",
                                     "Removing Type Accelerator" )) {
            # remove a user-defined accelerator
            $xlr8r::remove($key)   
         }
      }
   }
}
}



###############################################################################
##### Imported from PowerBoots

$Script:CodeGenContentProperties = 'Content','Child','Children','Frames','Items','Pages','Blocks','Inlines','GradientStops','Source','DataPoints', 'Series', 'VisualTree'
$DependencyProperties = @{}
if(Test-Path $PSScriptRoot\DependencyPropertyCache.xml) {
	#$DependencyProperties = [System.Windows.Markup.XamlReader]::Parse( (gc $PSScriptRoot\DependencyPropertyCache.xml) )
	$DependencyProperties = Import-CliXml  $PSScriptRoot\DependencyPropertyCache.xml 
}

function Get-ReflectionModule { $executioncontext.sessionstate.module }

function Set-ObjectProperties {
[CmdletBinding()]
param( $Parameters, [ref]$DObject )

   if($DObject.Value -is [System.ComponentModel.ISupportInitialize]) { $DObject.Value.BeginInit() }

   if($DebugPreference -ne "SilentlyContinue") { Write-Host; Write-Host ">>>> $($Dobject.Value.GetType().FullName)" -fore Black -back White }
   foreach ($param in $Parameters) {
      if($DebugPreference -ne "SilentlyContinue") { Write-Host "Processing Param: $($param|Out-String )" }
      ## INGORE DEPENDENCY PROPERTIES FOR NOW :)
      if($param.Key -eq "DependencyProps") {
      ## HANDLE EVENTS ....
      }
      elseif ($param.Key.StartsWith("On_")) {
         $EventName = $param.Key.SubString(3)
         if($DebugPreference -ne "SilentlyContinue") { Write-Host "Event handler $($param.Key) Type: $(@($param.Value)[0].GetType().FullName)" }
         $sb = $param.Value -as [ScriptBlock]
         if(!$sb) {
            $sb = (Get-Command $param.Value -CommandType Function,ExternalScript).ScriptBlock
         }
         $Dobject.Value."Add_$EventName".Invoke( $sb );
         # $Dobject.Value."Add_$EventName".Invoke( ($sb.GetNewClosure()) );
         
         # $Dobject.Value."Add_$EventName".Invoke( $PSCmdlet.MyInvocation.MyCommand.Module.NewBoundScriptBlock( $sb.GetNewClosure() ) );
         
         
      } ## HANDLE PROPERTIES ....
      else { 
         try {
            ## TODO: File a BUG because Write-DEBUG and Write-VERBOSE die here.
            if($DebugPreference -ne "SilentlyContinue") {
               Write-Host "Setting $($param.Key) of $($Dobject.Value.GetType().Name) to $($param.Value.GetType().FullName): $($param.Value)" -fore Gray
            }
            if(@(foreach($sb in $param.Value) { $sb -is [ScriptBlock] }) -contains $true) {
               $Values = @()
               foreach($sb in $param.Value) {
                  $Values += & (Get-ReflectionModule) $sb
               }
            } else {
               $Values = $param.Value
            }

            if($DebugPreference -ne "SilentlyContinue") { Write-Host ([System.Windows.Markup.XamlWriter]::Save( $Dobject.Value )) -foreground green }
            if($DebugPreference -ne "SilentlyContinue") { Write-Host ([System.Windows.Markup.XamlWriter]::Save( @($Values)[0] )) -foreground green }
            
            Set-Property $Dobject $Param.Key $Values

            if($DebugPreference -ne "SilentlyContinue") { Write-Host ([System.Windows.Markup.XamlWriter]::Save( $Dobject.Value )) -foreground magenta }
      
            if($DebugPreference -ne "SilentlyContinue") {
               if( $Dobject.Value.$($param.Key) -ne $null ) {
                  Write-Host $Dobject.Value.$($param.Key).GetType().FullName -fore Green
               }
            }
         }
         catch [Exception]
         {
            Write-Host "COUGHT AN EXCEPTION" -fore Red
            Write-Host $_ -fore Red
            Write-Host $this -fore DarkRed
         }
      }

      while($DependencyProps) {
         $name, $value, $DependencyProps = $DependencyProps
         $name = ([string]@($name)[0]).Trim("-")
         if($name -and $value) {
            Set-DependencyProperty -Element $Dobject.Value -Property $name -Value $Value
         }
      }
   }
   if($DebugPreference -ne "SilentlyContinue") { Write-Host "<<<< $($Dobject.Value.GetType().FullName)" -fore Black -back White; Write-Host }
   
   if($DObject.Value -is [System.ComponentModel.ISupportInitialize]) { $DObject.Value.EndInit() }

}

function Set-Property {
PARAM([ref]$TheObject, $Name, $Values)
   $DObject = $TheObject.Value
   
   if($DebugPreference -ne "SilentlyContinue") { Write-Host ([System.Windows.Markup.XamlWriter]::Save( $DObject )) -foreground DarkMagenta }
   if($DebugPreference -ne "SilentlyContinue") { Write-Host ([System.Windows.Markup.XamlWriter]::Save( @($Values)[0] )) -foreground DarkMagenta }

   $PropertyType = $DObject.GetType().GetProperty($Name).PropertyType
   if('System.Windows.FrameworkElementFactory' -as [Type] -and $PropertyType -eq [System.Windows.FrameworkElementFactory] -and $DObject -is [System.Windows.FrameworkTemplate]) {
      if($DebugPreference -ne "SilentlyContinue") { Write-Host "Loading a FrameworkElementFactory" -foreground Green}
      
      # [Xml]$Template = [PoshWpf.XamlHelper]::ConvertToXaml( $DObject )
      # [Xml]$Content = [PoshWpf.XamlHelper]::ConvertToXaml( (@($Values)[0]) )
      # In .Net 3.5 the recommended way to programmatically create a template is to load XAML from a string or a memory stream using the Load method of the XamlReader class.
      [Xml]$Template = [System.Windows.Markup.XamlWriter]::Save( $DObject )
      [Xml]$Content = [System.Windows.Markup.XamlWriter]::Save( (@($Values)[0]) )

      $Template.DocumentElement.PrependChild( $Template.ImportNode($Content.DocumentElement, $true) ) | Out-Null
     
      $TheObject.Value = [System.Windows.Markup.XamlReader]::Parse( $Template.get_OuterXml() )
   }
   elseif('System.Windows.Data.Binding' -as [Type] -and @($Values)[0] -is [System.Windows.Data.Binding] -and !$PropertyType.IsAssignableFrom([System.Windows.Data.BindingBase])) {
      $Binding = @($Values)[0];
      if($DebugPreference -ne "SilentlyContinue") { Write-Host "$($DObject.GetType())::$Name is $PropertyType and the value is a Binding: $Binding" -fore Cyan}

      if(!$Binding.Source -and !$Binding.ElementName) {
         $Binding.Source = $DObject.DataContext
      }
      if($DependencyProperties.ContainsKey($Name)) {
         $field = @($DependencyProperties.$Name.Keys | Where { $DObject -is $_ -and $PropertyType -eq ([type]$DependencyProperties.$Name.$_.PropertyType)})[0] #  -or -like "*$Class" -and ($Param1.Value -as ([type]$_.PropertyType)
         if($field) { 
            if($DebugPreference -ne "SilentlyContinue") { Write-Host "$($field)" -fore Blue }
            if($DebugPreference -ne "SilentlyContinue") { Write-Host "Binding: ($field)::`"$($DependencyProperties.$Name.$field.Name)`" to $Binding" -fore Blue}
            
            $DObject.SetBinding( ([type]$field)::"$($DependencyProperties.$Name.$field.Name)", $Binding ) | Out-Null
         } else {
            throw "Couldn't figure out $( @($DependencyProperties.$Name.Keys) -join ', ' )"
         }
      } else {
         if($DebugPreference -ne "SilentlyContinue") { 
            Write-Host "But $($DObject.GetType())::${Name}Property is not a Dependency Property, so it probably can't be bound?" -fore Cyan
         }
         try {
            
            $DObject.SetBinding( ($DObject.GetType()::"${Name}Property"), $Binding ) | Out-Null
            
            # $DObject.Add_Loaded( {
            #    $this.SetBinding( ($this.GetType())::ItemsSourceProperty,  (Binding -Source $this.DataContext) )
            # } )
               
            if($DebugPreference -ne "SilentlyContinue") { 
               Write-Host ([System.Windows.Markup.XamlWriter]::Save( $Dobject )) -foreground yellow
            }
         } catch {
            Write-Host "Nope, was not able to set it." -fore Red
            Write-Host $_ -fore Red
            Write-Host $this -fore DarkRed
         }
      }
   }
   elseif($PropertyType -ne [Object] -and $PropertyType.IsAssignableFrom( [System.Collections.IEnumerable] ) -and ($DObject.$($Name) -eq $null)) {
      if($Values -is [System.Collections.IEnumerable]) {
         if($DebugPreference -ne "SilentlyContinue") { Write-Host "$Name is $PropertyType which is IEnumerable, and the value is too!" -fore Cyan }
         $DObject.$($Name) = $Values
      } else { 
         if($DebugPreference -ne "SilentlyContinue") { Write-Host "$Name is $PropertyType which is IEnumerable, but the value is not." -fore Cyan }
         $DObject.$($Name) = new-object "System.Collections.ObjectModel.ObservableCollection[$(@($Values)[0].GetType().FullName)]"
         $DObject.$($Name).Add($Values)
      }
   }
   elseif($DObject.$($Name) -is [System.Collections.IList]) {
      foreach ($value in @($Values)) {
         try {
            $null = $DObject.$($Name).Add($value)
         }
         catch
         {
            # Write-Host "CAUGHT array problem" -fore Red
            if($_.Exception.Message -match "Invalid cast from 'System.String' to 'System.Windows.UIElement'.") {
               $null = $DObject.$($Name).Add( (New-System.Windows.Controls.TextBlock $value) )
            } else {
               Write-Error $_.Exception
            throw
            }
         }
      }
   }
   else {
      ## If they pass an array of 1 when we only want one, we just use the first value
      if($Values -is [System.Collections.IList] -and $Values.Count -eq 1) {
         if($DebugPreference -ne "SilentlyContinue") { Write-Host "Value is an IList ($($Values.GetType().FullName))" -fore Cyan}
         if($DebugPreference -ne "SilentlyContinue") { Write-Host "But we'll just use the first ($($Values[0].GetType().FullName))" -fore Cyan}
         
         if($DebugPreference -ne "SilentlyContinue") { Write-Host ([System.Windows.Markup.XamlWriter]::Save( $Values[0] )) -foreground White}
         try {
            $DObject.$($Name) = $Values[0]
         }
         catch [Exception]
         {
            # Write-Host "CAUGHT collection value problem" -fore Red
            if($_.Exception.Message -match "Invalid cast from 'System.String' to 'System.Windows.UIElement'.") {
               $null = $DObject.$($Name).Add( (TextBlock $Values[0]) )
            }else { 
               throw
            }
         }
      }
      else ## If they pass an array when we only want one, we try to use it, and failing that, cast it to strings
      {
         if($DebugPreference -ne "SilentlyContinue") { Write-Host "Value is just $Values" -fore Cyan}
         try {
            $DObject.$($Name) = $Values
         } catch [Exception]
         {
            # Write-Host "CAUGHT value problem" -fore Red
            if($_.Exception.Message -match "Invalid cast from 'System.String' to 'System.Windows.UIElement'.") {
               $null = $DObject.$($Name).Add( (TextBlock $values) )
            }else { 
               throw
            }
         }
      }
   }
}

function Set-DependencyProperty {
[CmdletBinding()]
PARAM(
   [Parameter(Position=0,Mandatory=$true)]
   $Property
,
   [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
   $Element
,
   [Parameter()]
   [Switch]$Passthru
)

DYNAMICPARAM {
   $paramDictionary = new-object System.Management.Automation.RuntimeDefinedParameterDictionary
   $Param1 = new-object System.Management.Automation.RuntimeDefinedParameter
   $Param1.Name = "Value"
   # $Param1.Attributes.Add( (New-ParameterAttribute -Position 1) )
   $Param1.Attributes.Add( (New-Object System.Management.Automation.ParameterAttribute -Property @{ Position = 1 }) )   

   if( $Property ) {
      if($Property.GetType() -eq ([System.Windows.DependencyProperty]) -or
         $Property.GetType().IsSubclassOf(([System.Windows.DependencyProperty]))) 
      {
         $Param1.ParameterType = $Property.PropertyType
      } 
      elseif($Property -is [string] -and $Property.Contains(".")) {
         $Class,$Property = $Property.Split(".")
         if($DependencyProperties.ContainsKey($Property)){
            $type = $DependencyProperties.$Property.Keys -like "*$Class"
            if($type) { 
               $Param1.ParameterType = [type]@($DependencyProperties.$Property.$type)[0].PropertyType
            }
         }

      } elseif($DependencyProperties.ContainsKey($Property)){
         if($Element) {
            if($DependencyProperties.$Property.ContainsKey( $element.GetType().FullName )) { 
               $Param1.ParameterType = [type]$DependencyProperties.$Property.($element.GetType().FullName).PropertyType
            }
         } else {
            $Param1.ParameterType = [type]$DependencyProperties.$Property.Values[0].PropertyType
         }
      }
      else 
      {
         $Param1.ParameterType = [PSObject]
      }
   }
   else 
   {
      $Param1.ParameterType = [PSObject]
   }
   $paramDictionary.Add("Value", $Param1)
   return $paramDictionary
}
PROCESS {   
   trap { 
      Write-Host "ERROR Setting Dependency Property" -Fore Red
      Write-Host "Trying to set $Property to $($Param1.Value)" -Fore Red
      continue
   }
   if($Property.GetType() -eq ([System.Windows.DependencyProperty]) -or
      $Property.GetType().IsSubclassOf(([System.Windows.DependencyProperty]))
   ){
      trap { 
         Write-Host "ERROR Setting Dependency Property" -Fore Red
         Write-Host "Trying to set $($Property.FullName) to $($Param1.Value)" -Fore Red
         continue
      }
      $Element.SetValue($Property, ($Param1.Value -as $Property.PropertyType))
   } 
	else {
      if("$Property".Contains(".")) {
         $Class,$Property = "$Property".Split(".")
      }
         
      if( $DependencyProperties.ContainsKey("$Property" ) ) {
         $fields = @( $DependencyProperties.$Property.Keys -like "*$Class" | ? { $Param1.Value -as ([type]$DependencyProperties.$Property.$_.PropertyType) } )
			if($fields.Count -eq 0 ) { 
            $fields = @($DependencyProperties.$Property.Keys -like "*$Class" )
         }			
         if($fields.Count) {
            $success = $false
            foreach($field in $fields) {
               trap { 
                  Write-Host "ERROR Setting Dependency Property" -Fore Red
                  Write-Host "Trying to set $($field)::$($DependencyProperties.$Property.$field.Name) to $($Param1.Value) -as $($DependencyProperties.$Property.$field.PropertyType)" -Fore Red
                  continue
               }
               $Element.SetValue( ([type]$field)::"$($DependencyProperties.$Property.$field.Name)", ($Param1.Value -as ([type]$DependencyProperties.$Property.$field.PropertyType)))
               if($?) { $success = $true; break }
            }
				
            if(!$success) { 
					throw "food" 
				}				
         } else {
            Write-Host "Couldn't find the right property: $Class.$Property on $( $Element.GetType().Name ) of type $( $Param1.Value.GetType().FullName )" -Fore Red      
         }
		}
		else {
         Write-Host "Unknown Dependency Property Key: $Property on $($Element.GetType().Name)" -Fore Red      
      }
   }
	
   if( $Passthru ) { $Element }
}
}

function Add-ConstructorFunction {
<#
.Synopsis
   Add support for a new class by creating the dynamic constructor function(s).
.Description
   Creates a New-Namespace.Type function for each type passed in, as well as a short form "Type" alias.

   Exposes all of the properties and events of the type as perameters to the function. 

   NOTE: The Type MUST have a default parameterless constructor.
.Parameter Assembly
	The Assembly you want to generate constructors for. All public types within it will be generated if possible.
.Parameter Type
   The type you want to create a constructor function for.  It must have a default parameterless constructor.
.Example
   Add-ConstructorFunction System.Windows.Controls.Button
   
   Creates a new function for the Button control.

.Example
   [Reflection.Assembly]::LoadWithPartialName( "PresentationFramework" ).GetTypes() | Add-ConstructorFunction

   Will create constructor functions for all the WPF components in the PresentationFramework assembly.  Note that you could also load that assembly using GetAssembly( "System.Windows.Controls.Button" ) or Load( "PresentationFramework, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" )

.Example
   Add-ConstructorFunction -Assembly PresentationFramework

   Will create constructor functions for all the WPF components in the PresentationFramework assembly.

.Links 
   http://HuddledMasses.org/powerboots
.ReturnValue
   The name(s) of the function(s) created -- so you can export them, if necessary.
.Notes
 AUTHOR:    Joel Bennett http://HuddledMasses.org
 LASTEDIT:  2009-01-13 16:35:23
#>
[CmdletBinding(DefaultParameterSetName="FromType")]
PARAM(
   [Parameter(Position=0,ValueFromPipeline=$true,ParameterSetName="FromType",Mandatory=$true)]
   [type[]]$type
,
   [Alias("FullName")]
   [Parameter(Position=0,ValueFromPipelineByPropertyName=$true,ParameterSetName="FromAssembly",Mandatory=$true)]
   [string[]]$Assembly
,
   [Parameter()]
	[string]$Path = "$PSScriptRoot\Types_Generated"
,
   [switch]$Force
,
   [switch]$ShortAliases
,
   [Switch]$Quiet
)
BEGIN {
   [Type[]]$Empty=@()
   if(!(Test-Path $Path)) {   
      MkDir $Path
   }
   $ErrorList = @()
}
END {
   #Set-Content -Literal $PSScriptRoot\DependencyPropertyCache.xml -Value ([System.Windows.Markup.XamlWriter]::Save( $DependencyProperties ))
	Export-CliXml -Path $PSScriptRoot\DependencyPropertyCache.xml -InputObject $DependencyProperties
	
   if($ErrorList.Count) { Write-Warning "Some New-* functions not aliased." }
   $ErrorList | Write-Error
}
PROCESS {
   if($PSCmdlet.ParameterSetName -eq "FromAssembly") {
      [type[]]$type = @()
      foreach($lib in $Assembly) {
         $asm =  $null
         trap { continue }
         if(Test-Path $lib) {
            $asm =  [Reflection.Assembly]::LoadFrom( (Convert-Path (Resolve-Path $lib -EA "SilentlyContinue") -EA "SilentlyContinue") )
         }
         if(!$asm) {
            ## BUGBUG: LoadWithPartialName is "Obsolete" -- but it still works in 2.0/3.5
            $asm =  [Reflection.Assembly]::LoadWithPartialName( $lib )
         }
         if($asm) {
            $type += $asm.GetTypes() | ?{ $_.IsPublic    -and !$_.IsEnum      -and 
                                         !$_.IsAbstract  -and !$_.IsInterface -and 
                                          $_.GetConstructor( "Instance,Public", $Null, $Empty, @() )}
         } else {
            Write-Error "Can't find the assembly $lib, please check your spelling and try again"
         }
      }
   }
   
   foreach($T in $type) {
      $TypeName = $T.FullName
      $ScriptPath = Join-Path $Path "New-$TypeName.ps1"
      Write-Verbose $TypeName

      ## Collect all dependency properties ....
      $T.GetFields() |
         Where-Object { $_.FieldType -eq [System.Windows.DependencyProperty] } |
         ForEach-Object { 
            [string]$Field = $_.DeclaringType::"$($_.Name)".Name
            [string]$TypeName = $_.DeclaringType.FullName
          
            if(!$DependencyProperties.ContainsKey( $Field )) {
               $DependencyProperties.$Field = @{}
            }
            
            $DependencyProperties.$Field.$TypeName = @{ 
               Name         = [string]$_.Name
               PropertyType = [string]$_.DeclaringType::"$($_.Name)".PropertyType.FullName
            }
         }
            
		if(!( Test-Path $ScriptPath ) -OR $Force) {
         $Pipelineable = @();
         ## Get (or generate) a set of parameters based on the the Type Name
         $PropertyNames = New-Object System.Text.StringBuilder "@("

         $Parameters = New-Object System.Text.StringBuilder "[CmdletBinding(DefaultParameterSetName='Default')]`nPARAM(`n"
		 
         ## Add all properties
         $Properties = $T.GetProperties("Public,Instance,FlattenHierarchy") | 
            Where-Object { $_.CanWrite -Or $_.PropertyType.GetInterface([System.Collections.IList]) }
			
         $Properties = ($T.GetEvents("Public,Instance,FlattenHierarchy") + $Properties) | Sort-Object Name -Unique

         foreach ($p in $Properties) {
            $null = $PropertyNames.AppendFormat(",'{0}'",$p.Name)
            switch( $p.MemberType ) {
               Event {
                  $null = $PropertyNames.AppendFormat(",'{0}__'",$p.Name)
                  $null = $Parameters.AppendFormat(@'
	[Parameter()]
	[PSObject]${{On_{0}}}
,
'@, $p.Name)
               }
               Property {
                  if($p.Name -match "^$($CodeGenContentProperties -Join '$|^')`$") {
                     $null = $Parameters.AppendFormat(@'
	[Parameter(Position=1,ValueFromPipeline=$true)]
	[Object[]]${{{0}}}
,
'@, $p.Name)
                     $Pipelineable += @(Add-Member -in $p.Name -Type NoteProperty -Name "IsCollection" -Value $($p.PropertyType.GetInterface([System.Collections.IList]) -ne $null) -Passthru)
                  } 
                  elseif($p.PropertyType -eq [System.Boolean]) 
                  {
                     $null = $Parameters.AppendFormat(@'
	[Parameter()]
	[Switch]${{{0}}}
,
'@, $p.Name)
                  }
                  else 
                  {
                     $null = $Parameters.AppendFormat(@'
	[Parameter()]
	[Object[]]${{{0}}}
,
'@, $p.Name)
                  }
               }
            }
         }
		$null = $Parameters.Append('	[Parameter(ValueFromRemainingArguments=$true)]
	[string[]]$DependencyProps
)')
		$null = $PropertyNames.Remove(2,1).Append(')')
			
      $collectable = [bool]$(@(foreach($p in @($Pipelineable)){$p.IsCollection}) -contains $true)
      $ofs = "`n";

$function = $(
"
if(!( '$TypeName' -as [Type] )) {
$(
   if( $T.Assembly.GlobalAssemblyCache ) {
"  `$null = [Reflection.Assembly]::Load( '$($T.Assembly.FullName)' ) "
   } else {
"  `$null = [Reflection.Assembly]::LoadFrom( '$($T.Assembly.Location)' ) "
   }
)
}
## if(`$ExecutionContext.SessionState.Module.Guid -ne (Get-ReflectionModule).Guid) {
## 	Write-Warning `"$($T.Name) not invoked in ReflectionModule context. Attempting to reinvoke.`"
##    # `$scriptParam = `$PSBoundParameters
##    # return iex `"& (Get-ReflectionModule) '`$(`$MyInvocation.MyCommand.Path)' ```@PSBoundParameters`"
## }
Write-Verbose ""$($T.Name) in module `$(`$executioncontext.sessionstate.module) context!""


function New-$TypeName {
<#
.Synopsis
   Create a new $($T.Name) object
.Description
   Generates a new $TypeName object, and allows setting all of it's properties.
   (From the $($T.Assembly.GetName().Name) assembly v$($T.Assembly.GetName().Version))
.Notes
 GENERATOR : $((Get-ReflectionModule).Name) v$((Get-ReflectionModule).Version) by Joel Bennett http://HuddledMasses.org
 GENERATED : $(Get-Date)
 ASSEMBLY  : $($T.Assembly.FullName)
 FULLPATH  : $($T.Assembly.Location)
#>
 
$Parameters
BEGIN {
   `$DObject = New-Object $TypeName
   `$All = $PropertyNames
}
PROCESS {
"
if(!$collectable) {
"
   # The content of $TypeName is not a collection
   # So if we're in a pipeline, make a new $($T.Name) each time
   if(`$_) { 
      `$DObject = New-Object $TypeName
   }
"
}
@'
foreach($key in @($PSBoundParameters.Keys) | where { $PSBoundParameters[$_] -is [ScriptBlock] }) {
   $PSBoundParameters[$key] = $PSBoundParameters[$key].GetNewClosure()
}
Set-ObjectProperties @($PSBoundParameters.GetEnumerator() | Where { [Array]::BinarySearch($All,($_.Key -replace "^On_(.*)",'$1__')) -ge 0 } ) ([ref]$DObject)
'@

if(!$collectable) {
@'
   Microsoft.PowerShell.Utility\Write-Output $DObject
} #Process
'@
   } else {
@'
} #Process
END {
   Microsoft.PowerShell.Utility\Write-Output $DObject
}
'@
   }
@"
}
                                                                        
## New-$TypeName `@PSBoundParameters
"@
)

         Set-Content -Path $ScriptPath -Value $Function
      }

      # Note: set the aliases global for now, because it's too late to export them
		# E.g.: New-Button = New-System.Windows.Controls.Button
		Set-Alias -Name "New-$($T.Name)" "New-$TypeName" -ErrorAction SilentlyContinue -ErrorVariable +ErrorList -Scope Global -Passthru:(!$Quiet)
		if($ShortAliases) {
		# E.g.: Button = New-System.Windows.Controls.Button
			Set-Alias -Name $T.Name "New-$TypeName" -ErrorAction SilentlyContinue -ErrorVariable +ErrorList -Scope Global -Passthru:(!$Quiet)
		}
		
      New-AutoLoad -Name $ScriptPath -Alias "New-$TypeName"
   }                                                         
}#PROCESS
}

function Import-ConstructorFunctions {
#.Synopsis
#  Autoload pre-generated constructor functions and generate aliases for them.
#.Description
#  Parses the New-* scripts in the specified path, and uses the Autoload module to pre-load them as commands and set up aliases for them, without parsing them into memory.
#.Parameter Path
#  The path to a folder with functions to preload
param(
   [Parameter()]
   [Alias("PSPath")]
	[string[]]$Path = "$PSScriptRoot\Types_Generated"
)
end {
	$Paths = $(foreach($p in $Path) { Join-Path $p "New-*.ps1" })
	Write-Verbose "Importing Constructors from: `n`t$($Paths -join "`n`t")"

	foreach($script in Get-ChildItem $Paths -ErrorAction 0) {
		$TypeName = $script.Name -replace 'New-(.*).ps1','$1'
      $ShortName = ($TypeName -split '\.')[-1]
      Write-Verbose "Importing constructor for type: $TypeName ($ShortName)"
		
      # Note: set the aliases global for now, because it's too late to export them
		# E.g.: New-Button = New-System.Windows.Controls.Button
		Set-Alias -Name "New-$ShortName" "New-$TypeName" -ErrorAction SilentlyContinue -ErrorVariable +ErrorList -Scope Global -Passthru:(!$Quiet)
		if($ShortAliases) {
		# E.g.: Button = New-System.Windows.Controls.Button
			Set-Alias -Name $ShortName "New-$TypeName" -ErrorAction SilentlyContinue -ErrorVariable +ErrorList -Scope Global -Passthru:(!$Quiet)
		}

		New-Autoload -Name $Script.FullName -Alias "New-$TypeName"
		# Write-Host -fore yellow $(Get-Command "New-$TypeName" | Out-String)
		Get-Command "New-$TypeName"
	}
}
}

###############################################################################


Add-Accelerator list System.Collections.Generic.List``1
Add-Accelerator dictionary System.Collections.Generic.Dictionary``2

Set-Alias aasm Add-Assembly -Option AllScope
Set-Alias gt Get-Type -Option AllScope
Set-Alias gasm Get-Assembly -Option AllScope
Set-Alias gctor Get-Constructor -Option AllScope
Set-Alias gax Get-Accelerator -Option AllScope
Set-Alias aax Add-Accelerator -Option AllScope
Set-Alias rax Remove-Accelerator -Option AllScope

Export-ModuleMember -Function * -Alias *
# SIG # Begin signature block
# MIIIDQYJKoZIhvcNAQcCoIIH/jCCB/oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOPmSsbNp7OA8QrGW9LDLkUk4
# Ni+gggUrMIIFJzCCBA+gAwIBAgIQKQm90jYWUDdv7EgFkuELajANBgkqhkiG9w0B
# AQUFADCBlTELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0
# IExha2UgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYD
# VQQLExhodHRwOi8vd3d3LnVzZXJ0cnVzdC5jb20xHTAbBgNVBAMTFFVUTi1VU0VS
# Rmlyc3QtT2JqZWN0MB4XDTEwMDUxNDAwMDAwMFoXDTExMDUxNDIzNTk1OVowgZUx
# CzAJBgNVBAYTAlVTMQ4wDAYDVQQRDAUwNjg1MDEUMBIGA1UECAwLQ29ubmVjdGlj
# dXQxEDAOBgNVBAcMB05vcndhbGsxFjAUBgNVBAkMDTQ1IEdsb3ZlciBBdmUxGjAY
# BgNVBAoMEVhlcm94IENvcnBvcmF0aW9uMRowGAYDVQQDDBFYZXJveCBDb3Jwb3Jh
# dGlvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMfUdxwiuWDb8zId
# KuMg/jw0HndEcIsP5Mebw56t3+Rb5g4QGMBoa8a/N8EKbj3BnBQDJiY5Z2DGjf1P
# n27g2shrDaNT1MygjYfLDntYzNKMJk4EjbBOlR5QBXPM0ODJDROg53yHcvVaXSMl
# 498SBhXVSzPmgprBJ8FDL00o1IIAAhYUN3vNCKPBXsPETsKtnezfzBg7lOjzmljC
# mEOoBGT1g2NrYTq3XqNo8UbbDR8KYq5G101Vl0jZEnLGdQFyh8EWpeEeksv7V+YD
# /i/iXMSG8HiHY7vl+x8mtBCf0MYxd8u1IWif0kGgkaJeTCVwh1isMrjiUnpWX2NX
# +3PeTmsCAwEAAaOCAW8wggFrMB8GA1UdIwQYMBaAFNrtZHQUnBQ8q92Zqb1bKE2L
# PMnYMB0GA1UdDgQWBBTK0OAaUIi5wvnE8JonXlTXKWENvTAOBgNVHQ8BAf8EBAMC
# B4AwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzARBglghkgBhvhC
# AQEEBAMCBBAwRgYDVR0gBD8wPTA7BgwrBgEEAbIxAQIBAwIwKzApBggrBgEFBQcC
# ARYdaHR0cHM6Ly9zZWN1cmUuY29tb2RvLm5ldC9DUFMwQgYDVR0fBDswOTA3oDWg
# M4YxaHR0cDovL2NybC51c2VydHJ1c3QuY29tL1VUTi1VU0VSRmlyc3QtT2JqZWN0
# LmNybDA0BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmNv
# bW9kb2NhLmNvbTAhBgNVHREEGjAYgRZKb2VsLkJlbm5ldHRAWGVyb3guY29tMA0G
# CSqGSIb3DQEBBQUAA4IBAQAEss8yuj+rZvx2UFAgkz/DueB8gwqUTzFbw2prxqee
# zdCEbnrsGQMNdPMJ6v9g36MRdvAOXqAYnf1RdjNp5L4NlUvEZkcvQUTF90Gh7OA4
# rC4+BjH8BA++qTfg8fgNx0T+MnQuWrMcoLR5ttJaWOGpcppcptdWwMNJ0X6R2WY7
# bBPwa/CdV0CIGRRjtASbGQEadlWoc1wOfR+d3rENDg5FPTAIdeRVIeA6a1ZYDCYb
# 32UxoNGArb70TCpV/mTWeJhZmrPFoJvT+Lx8ttp1bH2/nq6BDAIvu0VGgKGxN4bA
# T3WE6MuMS2fTc1F8PCGO3DAeA9Onks3Ufuy16RhHqeNcMYICTDCCAkgCAQEwgaow
# gZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2FsdCBMYWtl
# IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8GA1UECxMY
# aHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0wGwYDVQQDExRVVE4tVVNFUkZpcnN0
# LU9iamVjdAIQKQm90jYWUDdv7EgFkuELajAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUT5+I/cl2
# XCMwrqk7nr22uBFwAuwwDQYJKoZIhvcNAQEBBQAEggEAX0OJXKRNvY/GKPVbMj1Q
# V0UYJdKTM17Oca5Bvbj0BTcwbuoToM4mAH8s8ZJrZldIfcIdVsr89SQ+s9UwhE5W
# 1FsBl3smgVWjc8o9j3LTi/BssTOg2pgFaMwdR4GRmUgQjznAXFb3Np0FoB+RieAN
# IR6XXYoVSfMRg1Qa5M7MIy84ww4oGDE8ssBlterqR9VOSSKiHYvlbDHO9cVH1FJ3
# 8ulz1RPl2BA3iwDK6J0w74FNTXILJE85OEXAcxXwGPlgvtOqKFOpNf1/ji1iE9iO
# kysIFde1Amdq5Qx6nDNYkvWYj59vBH0SgcvJj5k2EieQEecraca10q95BE+oXmaK
# 1Q==
# SIG # End signature block


## Tab-Completion
#################
## Please dot souce this script file.
## In first loading, it may take a several minutes, in order to generate ProgIDs and TypeNames list.
## 
## What this can do is:
##
## [datetime]::n<tab>
## [datetime]::now.d<tab>
## $a = New-Object "Int32[,]" 2,3; $b = "PowerShell","PowerShell"
## $c = [ref]$a; $d = [ref]$b,$c
## $d[0].V<tab>[0][0].Get<tab>
## $d[1].V<tab>[0,0].tos<tab>
## $function:a<tab>
## $env:a<tab>
## [System.Type].a<tab>
## [datetime].Assembly.a<tab>
## ).a<tab> # shows System.Type properties and methods...

## #native command name expansion
## fsu<tab>

## #command option name expansion (for fsutil ipconfig net powershell only)
## fsutil <tab>
## ipconfig <tab>
## net <tab>
## powershell <tab>

## #TypeNames and Type accelerators expansion
## [Dec<tab>
## [system.Man<tab>.auto<tab>.p<tab>
## New-Object -TypeName IO.Dir<tab>
## New-Object System.win<tab>.for<tab>.bu<tab>

## #ProgIDs expansion
## New-Object -Com shel<tab>

## #Enum option expansion
## Set-ExecutionPolicy <tab>
## Set-ExecutionPolicy All<tab>
## Set-ExcusionPolisy -ex <tab>
## Get-TraceSource Inte<tab>
## iex -Errora <tab> -wa Sil<tab>

## #WmiClasses expansion
## Get-WmiObject -class Win32_<tab>
## gwmi __Instance<tab>

## #Encoding expansion
## [Out-File | Export-CSV | Select-String | Export-Clixml] -enc <tab>
## [Add-Content | Get-Content | Set-Content} -Encoding Big<tab>

## #PSProvider name expansion
## [Get-Location | Get-PSDrive | Get-PSProvider | New-PSDrive | Remove-PSDrive] -PSProvider <tab>
## Get-PSProvider <tab>
## pwd -psp al<tab>

## #PSDrive name expansion
## [Get-PSDrive | New-PSDrive | Remove-PSDrive] [-Name] <tab>
## Get-PSDrive <tab>
## pwd -psd <tab>

## #PSSnapin name expansion
## [Add-PSSnapin | Get-PSSnapin | Remove-PSSnapin ] [-Name] <tab>
## Get-Command -PSSnapin <tab>
## Remove-PSSnapin <tab>
## Get-PSSnapin M<tab>

## #Eventlog name and expansion
## Get-Eventlog -Log <tab>
## Get-Eventlog w<tab>

## #Eventlog's entrytype expansion
## Get-EventLog -EntryType <tab>
## Get-EventLog -EntryType Er<tab>
## Get-EventLog -Ent <tab>

## #Service name expansion
## [Get-Service | Restart-Service | Resume-Service | Start-Service | Stop-Service | Suspend-Service] [-Name] <tab>
## New-Service -DependsOn <tab>
## New-Service -Dep e<tab>
## Get-Service -n <tab>
## Get-Service <tab>,a<tab>,p<tab>
## gsv <tab>

## #Service display name expansion
## [Get-Service | Restart-Service | Resume-Service | Start-Service | Stop-Service | Suspend-Service] [-DisplayName] <tab>
## Get-Service -Dis <tab>
## gsv -Dis <tab>,w<tab>,b<tab>

## #Cmdlet and Topic name expansion (this also support default help function and man alias)
## Get-Help [-Name] about_<tab>
## Get-Help <tab>

## #Category name expansion (this also support default help function and man alias)
## Get-Help -Category c<tab>,<tab>

## #Command name expansion
## Get-Command [-Name] <tab>
## Get-Command -Name <tab>
## gcm a<tab>,<tab>

## #Scope expansion
## [Clear-Variable | Export-Alias | Get-Alias | Get-PSDrive | Get-Variable | Import-Alias
## New-Alias | New-PSDrive | New-Variable | Remove-Variable | Set-Alias | Set-Variable] -Scope <tab>
## Clear-Variable -Scope G<tab>
## Set-Alias  -s <tab>

## #Process name expansion
## [Get-Process | Stop-Process] [-Name] <tab>
## Stop-Process -Name <tab>
## Stop-Process -N pow<tab>
## Get-Process <tab>
## ps power<tab>

## #Trace sources expansion
## [Trace-Command | Get-TraceSource | Set-TraceSource] [-Name] <tab>,a<tab>,p<tab>

## #Trace -ListenerOption expansion
## [Set-TraceSource | Trace-Command] -ListenerOption <tab>
## Set-TraceSource -Lis <tab>,n<tab>

## #Trace -Option expansion
## [Set-TraceSource | Trace-Command] -Option <tab>
## Set-TraceSource -op <tab>,con<tab>

## #ItemType expansion
## New-Item -Item <tab>
## ni -ItemType d<tab>

## #ErrorAction and WarningAction option expansion
## CMDLET [-ErrorAction | -WarningAction] <tab>
## CMDLET -Errora s<tab>
## CMDLET -ea con<tab>
## CMDLET -wa <tab>

## #Continuous expansion with comma when parameter can treat multiple option
## # if there are spaces, occur display bug in the line
## # if strings contains '$' or '-', not work
## Get-Command -CommandType <tab>,<tab><tab>,cm<tab>
## pwd -psp <tab>,f<tab>,va<tab>
## Get-EventLog -EntryType <tab>,i<tab>,s<tab>

## #Enum expansion in method call expression
## # this needs one or more spaces after left parenthesis or comma
## $str = "day   night"
## $str.Split( " ",<space>rem<tab>
## >>> $str.Split( " ", "RemoveEmptyEntries" ) <Enter> ERROR
## $str.Split( " ", "RemoveEmptyEntries" -as<space><tab>
## >>> $str.Split( " ", "RemoveEmptyEntries" -as [System.StringSplitOptions] ) <Enter> Success
## $type = [System.Type]
## $type.GetMembers(<space>Def<tab>
## [IO.Directory]::GetFiles( "C:\", "*",<space>All<tab>
## # this can do continuous enum expansion with comma and no spaces
## $type.GetMembers( "IgnoreCase<comma>Dec<tab><comma>In<tab>"
## [IO.Directory]::GetAccessControl( "C:\",<space>au<tab><comma>ac<tab><comma>G<tab>

## #Better '$_.' expansion when cmdlet output objects or method return objects
## ls |group { $_.Cr<tab>.Tost<tab>"y")} | tee -var foo| ? { $_.G<tab>.c<tab> -gt 5 } | % { md $_.N<tab> ; copy $_.G<tab> $_.N<tab>  }
## [IO.DriveInfo]::GetDrives() | ? { $_.A<tab> -gt 1GB }
## $Host.UI.RawUI.GetBufferContents($rect) | % { $str += $_.c<tab> }
## gcm Add-Content |select -exp Par<tab>| select -ExpandProperty Par<tab> | ? { $_.Par<tab>.N<tab> -eq "string" }
## $data = Get-Process
## $data[2,4,5]  | % { $_.<tab>
## #when Get-PipeLineObject failed, '$_.' shows methods and properties name of FileInfo and String and Type

## #Property name expansion by -Property parameter
## [ Format-List | Format-Custom | Format-Table | Format-Wide | Compare-Object |
##  ConvertTo-Html | Measure-Object | Select-Object | Group-Object | Sort-Object ] [-Property] <tab>
## Select-Object -ExcludeProperty <tab>
## Select-Object -ExpandProperty <tab>
## gcm Get-Acl|select -exp Par<tab>
## ps |group na<tab>
## ls | ft A<tab>,M<tab>,L<tab>

## #Hashtable key expansion in the variable name and '.<tab>'
## Get-Process | Get-Unique | % { $hash += @{$_.ProcessName=$_} }
## $hash.pow<tab>.pro<tab>

## #Parameter expansion for function, filter and script
## man -f<tab>
## 'param([System.StringSplitOptions]$foo,[System.Management.Automation.ActionPreference]$bar,[System.Management.Automation.CommandTypes]$baz) {}' > foobar.ps1
## .\foobar.ps1 -<tab> -b<tab>

## #Enum expansion for function, filter and scripts
## # this can do continuous enum expansion with comma and no spaces
## .\foobar.ps1 -foo rem<tab> -bar <tab><comma>c<tab><comma>sc<tab> -ea silent<tab> -wa con<tab>

## #Enum expansion for assignment expression
## #needs space(s) after '=' and comma
## #strongly-typed with -as operator and space(s)
## $ErrorActionPreference =<space><tab>
## $cmdtypes = New-Object System.Management.Automation.CommandTypes[] 3
## $cmdtypes =<space><tab><comma><space>func<tab><comma><space>cmd<tab> -as<space><tab>

## #Path expansion with variable and '\' or '/'
## $PWD\../../<tab>\<tab>
## "$env:SystemDrive/pro<tab>/<tab>

## #Operator expansion which starts with '-'
## "Power","Shell" -m<tab> "Power" -r<tab> '(Pow)(er)','$1d$2'
## 1..9 -co<tab> 5

## #Keyword expansion
## fu<tab> test { p<tab> $foo, $bar ) b<tab> "foo" } pr<tab> $_ } en<tab> "$bar" } }

## #Variable name expansion (only global scope)
## [Clear-Variable | Get-Variable | New-Variable | Remove-Variable | Set-Variable] [-Name] <tab>
## [Cmdlet | Function | Filter | ExternalScript] -ErrorVariable <tab>
## [Cmdlet | Function | Filter | ExternalScript] -OutVariable <tab>
## Tee-Object -Variable <tab>
##  gv pro<tab>,<tab>
##  Remove-Variable -Name out<tab>,<tab>,ps<tab>
##  ... | ... | tee -v <tab>

## #Alias name expansion
## [Get-Alias | New-Alias | Set-Alias] [-Name] <tab>
## Export-Alias -Name <tab>
##  Get-Alias i<tab>,e<tab>,a<tab>
##  epal -n for<tab>

## #Property name expansion with -groupBy parameter
## [Format-List | Format-Custom | Format-Table | Format-Wide] -groupBy <tab>
##  ps | ft -g <tab>
##  gcm | Format-Wide -GroupBy Par<tab>

## #Type accelerators expansion with no characters
##  [<tab>
##  New-Object -typename <tab>
##  New-Object <tab>

## # File glob expansion with '@'
##  ls *.txt@<tab>
##  ls file.txt, foo1.txt, 'bar``[1``].txt', 'foo bar .txt'	# 1 <tab> expanding with comma
##  ls * -Filter *.txt						# 2 <tab> refactoring 
##  ls *.txt							# 3 <tab> (or 1 <tab> & 1 <shift>+<tab>) return original glob pattern

## This can also use '^'(hat) or '~'(tilde) for Excluding
##  ls <hat>*.txt@<tab>
##  ls foo.ps1, 'bar``[1``].xml'		# 1 <tab> expanding with comma
##  ls * -Filter * -Excluding *.txt		# 2 <tab> refactoring 
##  *.txt<tilde>foo*<tilde>bar*@<tab>
##  ls file.txt					# 1 <tab> expanding with comma
##  ls * -Filter *.txt -Excluding foo*, bar*	# 2 <tab> refactoring 

## # Ported history expansion from V2CTP3 TabExpansion with '#' ( #<pattern> or #<id> )
##  ls * -Filter * -Excluding foo*, bar*<Enter>
##  #ls<tab>
##  #1<tab>

## # Command buffer stack with ';'(semicolon)
##  ls * -Filter * -Excluding foo*, bar*<semicolon><tab> # push command1
##  echo "PowerShell"<semicolon><tab> # push command2
##  get-process<semicolon><tab> # push command3
##  {COMMAND}<Enter> # execute another command 
##  get-process # Auto pop command3 from stack by LIFO
## This can also hand-operated pop with ';,'(semicolon&comma) or ';:'(semicolon&colon)
##  get-process; <semicolon><comma><tab>
##  get-process; echo "PowerShell" # pop command2 from stack by LIFO

## # Function name expansion after 'function' or 'filter' keywords
## function cl<tab>

## #Switch syntax option expansion
##  switch -w<tab> -f<tab>

## #Better powershell.exe option expansion with '-'
##  powershell -no<tab> -<tab> -en<tab>

## #A part of PowerShell attributes expansion ( CmdletBinding, Parameter, Alias, Validate*, Allow* )
##  [par<tab>
##  [cmd<tab>

## #Member expansion for CmdletBinding and Parameter attributes
##  [Parameter(man<tab>,<tab>1,val<tab>$true)]
##  [CmdletBinding( <tab>"foo", su<tab>$true)]

## #Several current date/time formats with Ctrl+D
##  <Ctrl+D><tab><tab><tab><tab><tab>...

## #Hand-operated pop from command buffer with Ctrl+P (this is also available with ';:' or ';,')
##  <command>;<tab> # push command
##  <Ctrl+D><tab> # pop

## #Paste clipboard with Ctrl+V
##  <Ctrl+V><tab>

## # Cut current line with Ctrl+X
##  <command><Ctrl+X><tab>

## # Cut words with a character after Ctrl+X until the character
## 1: PS > dir -Filter *.txt<Ctrl+X>-<tab> # Cut words until '-'
## 2: PS > dir -
## 3: PS > dir -<Ctrl+V><tab> # Paste words that were copyed now

## # Cut last word in current line with Ctrl+Z
## 1: PS >  Get-ChildItem *.txt<Ctrl+Z><tab> # Cut last word in current line
## 2: PS >  Get-ChildItem 
## 3: PS >  Get-ChildItem -Exclude <Ctrl+V><tab> # Paste last word that was copyed now

## #[ScriptBlock] member expansion for [ScriptBlock] literal
##  { 1+1 }.inv<tab>

## #A part of history commands expansion with Ctrl+L (using split(";"),split("|"),split(";|") )
## ls -Force -Recurse -Filter *.txt | ? { $_.LastWriteTime -lt  [DateTime]::Today } ; echo PowerShell
## ls<Ctrl+L><tab><tab>
## ?<Ctrl+L><tab><tab>
## ec<Ctrl+L><tab>

## # Using Ctrl+K, characters insertion (bihind space or semi-coron or pipe operator) feature : it encloses tokens with parnthesis by default
##  1 - 1 - 1 - 1<Ctrl+K><tab>
##  1 - 1 - 1 - (1)<tab>
##  1 - 1 - 1 (- 1)<tab>
##  1 - 1 - (1 - 1)<tab><tab><tab>...
## with double Ctrl+K, it encloses tokens with $( )
##  for ( $i=0;$j=1<Ctrl+K><Ctrl+K><tab><tab>
##  for ( $($i=0;$j=1)
## if there is a character between <Ctrl+K> and  <tab>, it is inserted between tokens
##  1+1 | {$_*2}<Ctrl+K>%<tab>
##  1+1 | %{$_*2}
##  1+1 +1+1<Ctrl+K>;<tab>
##  1+1 ;+1+1
## if the character is ( or { or {, tokens are enclosed ( ) or { } or {}
##  int<Ctrl+K>[<tab>
##  [int]
## with double Ctrl+K, and if there is a character between <Ctrl+K> and  <tab>, it is inserted between tokens with '$'
##  C:\WINDOWS\system32\notepad.exe<Ctrl+K><Ctrl+K>{<tab>
##  ${C:\WINDOWS\system32\notepad.exe}
## % and ? are given special treatment with double Ctrl+K, these enclose tokens with % { } or ? { } behind '|'
##  ls | $_.LastWriteTime -gt "2009/5"<Ctrl+K><Ctrl+K>?<tab>
##  ls | ? {$_.LastWriteTime -gt "2009/5"}
##  ls | $_.FullName<Ctrl+K><Ctrl+K>%<tab>
##  ls | % {$_.FullName}

## # WMI Namespaces expansion for Get-WmiObject
##  gwmi -Namespace <tab>
##  Get-WmiObject -Namespace root\asp<tab>

## # WMI Classes expansion which is corresponding to WMI Namespace (*)
##  gwmi -Namespace ROOT\CIMV2\ms_409 -Class <tab>_<tab>


### Generate ProgIDs list...
if ( Test-Path $PSHOME\ProgIDs.txt )
{
    $_ProgID = type $PSHOME\ProgIDs.txt -ReadCount 0
}
else
{
    $_HKCR = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey("CLSID\")
    $_ProgID = New-Object ( [System.Collections.Generic.List``1].MakeGenericType([String]) )
    foreach ( $_subkey in $_HKCR.GetSubKeyNames() )
    {
        foreach ( $_i in [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey("CLSID\$_subkey\ProgID") )
        {
            if ($_i -ne $null)
            {
                $_ProgID.Add($_i.GetValue(""))
            }
        }
    }
    '$_ProgID was updated...' | Out-Host
    $_ProgID = $_ProgID|sort -Unique

    Set-Content -Value $_ProgID -Path $PSHOME\ProgIDs.txt -Verbose
}

### Generate TypeNames list...

if ( Test-Path $PSHOME\TypeNames.txt )
{
    $_TypeNames = type $PSHOME\TypeNames.txt -ReadCount 0
}
else
{
    $_TypeNames = New-Object ( [System.Collections.Generic.List``1].MakeGenericType([String]) )
    foreach ( $_asm in [AppDomain]::CurrentDomain.GetAssemblies() )
    {
        foreach ( $_type in $_asm.GetTypes() )
        {
            $_TypeNames.Add($_type.FullName)
        }
    }
    '$_TypeNames was updated...' | Out-Host
    $_TypeNames = $_TypeNames | sort -Unique

    Set-Content -Value $_TypeNames -Path $PSHOME\TypeNames.txt -Verbose
}

if ( Test-Path $PSHOME\TypeNames_System.txt )
{
    $_TypeNames_System = type $PSHOME\TypeNames_System.txt -ReadCount 0
}
else
{
    $_TypeNames_System = $_TypeNames -like "System.*" -replace '^System\.'
    '$_TypeNames_System was updated...' | Out-Host
    Set-Content -Value $_TypeNames_System -Path $PSHOME\TypeNames_System.txt -Verbose
}

### Generate Namespaces list...
if ( Test-Path $PSHOME\WMINamespaces.txt )
{
    $_WMINamespaces = type $PSHOME\WMINamespaces.txt -ReadCount 0
}
else
{
    $_WMINamespaces = & {
       $sb = {
           param ($ns)
           gwmi __NAMESPACE -Namespace $ns -com . |
           % {
               $ns = $_.__NAMESPACE + "\" + $_.Name
               $ns
               & $sb $ns
           }
       }
       & $sb root
    }
    $_WMINamespaces = $_WMINamespaces + "ROOT" | sort
    '$_WMINamespaces was updated...' | Out-Host
    Set-Content -Value $_WMINamespaces -Path $PSHOME\WMINamespaces.txt -Verbose
}
### Get default WMI Namespace...
$_WMIdftNS = $_WMINamespaces -eq (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\WBEM\Scripting)."Default Namespace"

### Generate WMIClasses list...
if ( Test-Path $PSHOME\WMIClasses.txt )
{
    $_WMIClasses =  Import-Clixml $PSHOME\WMIClasses.txt
}
else
{
    $_new = '=(New-Object ( [System.Collections.Generic.List``1].MakeGenericType([String]) ));'
    $_WMIClasses = iex ('@{"' + [String]::Join( "`"$_new`"", $_WMINamespaces ) + "`"$_new}")

    foreach ( $_namespace in $_WMINamespaces )
    {
        foreach ( $_class in gwmi -Namespace $_namespace -List )
        {
            $_WMIClasses.$_namespace.Add($_class.Name)
        }
    $_WMIClasses.$_namespace.Sort()
    }
    '$_WMIClasses was updated...' | Out-Host
    Export-Clixml -InputObject $_WMIClasses -Path $PSHOME\WMIClasses.txt -Verbose
}

[Reflection.Assembly]::LoadWithPartialName( "System.Windows.Forms" ) | Out-Null
$global:_cmdstack = New-Object Collections.Stack
$global:_snapin = $null
$global:_TypeAccelerators = "ADSI", "Array", "Bool", "Byte", "Char", "Decimal", "Double", "float", "hashtable", "int", "Long", "PSObject", "ref",
                            "Regex", "ScriptBlock", "Single", "String", "switch", "Type", "WMI", "WMIClass", "WMISearcher", "xml"
$global:_cmdline = New-Object Collections.ArrayList

iex (@'
function prompt {
h -Count 1 -OutVariable line |
% { $_.CommandLine.Split("|"); $_.CommandLine.Split(";"); $_.CommandLine.Split(";"); $_.CommandLine.Split(";|") } |
Get-Unique | ? { $_ -ne $line.CommandLine -and $_ -notmatch '^\s*$' } |
% { $_.Trim(" ") } |
? { $global:_cmdline -notcontains $_ } | % { Set-CommandLine $_ | Out-Null }
if ($_cmdstack.Count -gt 0) {
    $line = $global:_cmdstack.Pop() -replace '([[\]\(\)+{}?~%])','{$1}'
    [System.Windows.Forms.SendKeys]::SendWait($line)
}
'@ + @"
${function:prompt}
}
"@)

function Write-ClassNames ( $data, $i, $prefix='', $sep='.' )
{
    $preItem = ""
    foreach ( $class in $data -like $_opt )
    {
        $Item = $class.Split($sep)
        if ( $preItem -ne $Item[$i] )
        {
            if ( $i+1 -eq $Item.Count )
            {
                if ( $prefix -eq "[" )
                {
                    $suffix = "]"
                }
                elseif ( $sep -like "[_\]" )
                {
                    $suffix = ""
                }
                else
                {
                    $suffix = " "
                }
            }
            else
            {
                $suffix = ""
            }
            $prefix + $_opt.Substring(0, $_opt.LastIndexOf($sep)+1) + $Item[$i] + $suffix

            $preItem = $Item[$i]
        }
    }
}

function Get-PipeLineObject {

    $i = -2
    $property = $null
    do {
        $str = $line.Split("|")
        # extract the command name from the string
        # first split the string into statements and pipeline elements
        # This doesn't handle strings however.
        $_cmdlet = [regex]::Split($str[$i], '[|;=]')[-1]

        # take the first space separated token of the remaining string
        # as the command to look up. Trim any leading or trailing spaces
        # so you don't get leading empty elements.
        $_cmdlet = $_cmdlet.Trim().Split()[0]

        if ( $_cmdlet -eq "?" )
        {
            $_cmdlet = "Where-Object"
        }

        $global:_exp = $_cmdlet

        # now get the info object for it...
        $_cmdlet = @(Get-Command -type 'cmdlet,alias' $_cmdlet)[0]

        # loop resolving aliases...
        while ($_cmdlet.CommandType -eq 'alias')
        {
            $_cmdlet = @(Get-Command -type 'cmdlet,alias' $_cmdlet.Definition)[0]
        }

        if ( "Select-Object" -eq $_cmdlet )
        {
            if ( $str[$i] -match '\s+-Exp\w*[\s:]+(\w+)' )
            {
                $property = $Matches[1] + ";" + $property
            }
        }

        $i--
    } while ( "Get-Unique", "Select-Object", "Sort-Object", "Tee-Object", "Where-Object" -contains $_cmdlet )

    if ( $global:_forgci -eq $null )
    {
        $a = @(ls "Alias:\")[0]
        $e = @(ls "Env:\")[0]
        $f = @(ls "Function:\")[0]
        $h = @(ls "HKCU:\")[0]
        $v = @(ls "Variable:\")[0]
        $c = @(ls "cert:\")[0]
        $global:_forgci = gi $PSHOME\powershell.exe |
        Add-Member -Name CommandType -MemberType 'NoteProperty' -Value $f.CommandType -PassThru |
        Add-Member -Name Definition -MemberType 'NoteProperty' -Value $a.Definition -PassThru |
        Add-Member -Name Description -MemberType 'NoteProperty' -Value $a.Description -PassThru |
        Add-Member -Name Key -MemberType 'NoteProperty' -Value $e.Key -PassThru |
        Add-Member -Name Location -MemberType 'NoteProperty' -Value $c.Location -PassThru |
        Add-Member -Name LocationName -MemberType 'NoteProperty' -Value $c.LocationName -PassThru |
        Add-Member -Name Options -MemberType 'NoteProperty' -Value $a.Options -PassThru |
        Add-Member -Name ReferencedCommand -MemberType 'NoteProperty' -Value $a.ReferencedCommand -PassThru |
        Add-Member -Name ResolvedCommand -MemberType 'NoteProperty' -Value $a.ResolvedCommand -PassThru |
        Add-Member -Name ScriptBlock -MemberType 'NoteProperty' -Value $f.ScriptBlock -PassThru |
        Add-Member -Name StoreNames -MemberType 'NoteProperty' -Value $c.StoreNames -PassThru |
        Add-Member -Name SubKeyCount -MemberType 'NoteProperty' -Value $h.SubKeyCount -PassThru |
        Add-Member -Name Value -MemberType 'NoteProperty' -Value $e.Value -PassThru |
        Add-Member -Name ValueCount -MemberType 'NoteProperty' -Value $h.ValueCount -PassThru |
        Add-Member -Name Visibility -MemberType 'NoteProperty' -Value $a.Visibility -PassThru |
        Add-Member -Name Property -MemberType 'NoteProperty' -Value $h.Property -PassThru |
        Add-Member -Name ResolvedCommandName -MemberType 'NoteProperty' -Value $a.ResolvedCommandName -PassThru |
        Add-Member -Name Close -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name CreateSubKey -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name DeleteSubKey -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name DeleteSubKeyTree -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name DeleteValue -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name Flush -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetSubKeyNames -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetValue -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetValueKind -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetValueNames -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name IsValidValue -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name OpenSubKey -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name SetValue -MemberType 'ScriptMethod' -Value {} -PassThru
    }

    if ( $global:_mix -eq $null )
    {
        $f = gi $PSHOME\powershell.exe
        $t = [type]
        $s = ""
        $global:_mix = `
        Add-Member -InputObject (New-Object PSObject) -Name Mode -MemberType 'NoteProperty' -Value $f.Mode -PassThru |
        Add-Member -Name Assembly -MemberType 'NoteProperty' -Value $t.Assembly -PassThru |
        Add-Member -Name AssemblyQualifiedName -MemberType 'NoteProperty' -Value $t.AssemblyQualifiedName -PassThru |
        Add-Member -Name Attributes -MemberType 'NoteProperty' -Value $f.Attributes -PassThru |
        Add-Member -Name BaseType -MemberType 'NoteProperty' -Value $t.BaseType -PassThru |
        Add-Member -Name ContainsGenericParameters -MemberType 'NoteProperty' -Value $t.ContainsGenericParameters -PassThru |
        Add-Member -Name CreationTime -MemberType 'NoteProperty' -Value $f.CreationTime -PassThru |
        Add-Member -Name CreationTimeUtc -MemberType 'NoteProperty' -Value $f.CreationTimeUtc -PassThru |
        Add-Member -Name DeclaringMethod -MemberType 'NoteProperty' -Value $t.DeclaringMethod -PassThru |
        Add-Member -Name DeclaringType -MemberType 'NoteProperty' -Value $t.DeclaringType -PassThru |
        Add-Member -Name Exists -MemberType 'NoteProperty' -Value $f.Exists -PassThru |
        Add-Member -Name Extension -MemberType 'NoteProperty' -Value $f.Extension -PassThru |
        Add-Member -Name FullName -MemberType 'NoteProperty' -Value $f.FullName -PassThru |
        Add-Member -Name GenericParameterAttributes -MemberType 'NoteProperty' -Value $t.GenericParameterAttributes -PassThru |
        Add-Member -Name GenericParameterPosition -MemberType 'NoteProperty' -Value $t.GenericParameterPosition -PassThru |
        Add-Member -Name GUID -MemberType 'NoteProperty' -Value $t.GUID -PassThru |
        Add-Member -Name HasElementType -MemberType 'NoteProperty' -Value $t.HasElementType -PassThru |
        Add-Member -Name IsAbstract -MemberType 'NoteProperty' -Value $t.IsAbstract -PassThru |
        Add-Member -Name IsAnsiClass -MemberType 'NoteProperty' -Value $t.IsAnsiClass -PassThru |
        Add-Member -Name IsArray -MemberType 'NoteProperty' -Value $t.IsArray -PassThru |
        Add-Member -Name IsAutoClass -MemberType 'NoteProperty' -Value $t.IsAutoClass -PassThru |
        Add-Member -Name IsAutoLayout -MemberType 'NoteProperty' -Value $t.IsAutoLayout -PassThru |
        Add-Member -Name IsByRef -MemberType 'NoteProperty' -Value $t.IsByRef -PassThru |
        Add-Member -Name IsClass -MemberType 'NoteProperty' -Value $t.IsClass -PassThru |
        Add-Member -Name IsCOMObject -MemberType 'NoteProperty' -Value $t.IsCOMObject -PassThru |
        Add-Member -Name IsContextful -MemberType 'NoteProperty' -Value $t.IsContextful -PassThru |
        Add-Member -Name IsEnum -MemberType 'NoteProperty' -Value $t.IsEnum -PassThru |
        Add-Member -Name IsExplicitLayout -MemberType 'NoteProperty' -Value $t.IsExplicitLayout -PassThru |
        Add-Member -Name IsGenericParameter -MemberType 'NoteProperty' -Value $t.IsGenericParameter -PassThru |
        Add-Member -Name IsGenericType -MemberType 'NoteProperty' -Value $t.IsGenericType -PassThru |
        Add-Member -Name IsGenericTypeDefinition -MemberType 'NoteProperty' -Value $t.IsGenericTypeDefinition -PassThru |
        Add-Member -Name IsImport -MemberType 'NoteProperty' -Value $t.IsImport -PassThru |
        Add-Member -Name IsInterface -MemberType 'NoteProperty' -Value $t.IsInterface -PassThru |
        Add-Member -Name IsLayoutSequential -MemberType 'NoteProperty' -Value $t.IsLayoutSequential -PassThru |
        Add-Member -Name IsMarshalByRef -MemberType 'NoteProperty' -Value $t.IsMarshalByRef -PassThru |
        Add-Member -Name IsNested -MemberType 'NoteProperty' -Value $t.IsNested -PassThru |
        Add-Member -Name IsNestedAssembly -MemberType 'NoteProperty' -Value $t.IsNestedAssembly -PassThru |
        Add-Member -Name IsNestedFamANDAssem -MemberType 'NoteProperty' -Value $t.IsNestedFamANDAssem -PassThru |
        Add-Member -Name IsNestedFamily -MemberType 'NoteProperty' -Value $t.IsNestedFamily -PassThru |
        Add-Member -Name IsNestedFamORAssem -MemberType 'NoteProperty' -Value $t.IsNestedFamORAssem -PassThru |
        Add-Member -Name IsNestedPrivate -MemberType 'NoteProperty' -Value $t.IsNestedPrivate -PassThru |
        Add-Member -Name IsNestedPublic -MemberType 'NoteProperty' -Value $t.IsNestedPublic -PassThru |
        Add-Member -Name IsNotPublic -MemberType 'NoteProperty' -Value $t.IsNotPublic -PassThru |
        Add-Member -Name IsPointer -MemberType 'NoteProperty' -Value $t.IsPointer -PassThru |
        Add-Member -Name IsPrimitive -MemberType 'NoteProperty' -Value $t.IsPrimitive -PassThru |
        Add-Member -Name IsPublic -MemberType 'NoteProperty' -Value $t.IsPublic -PassThru |
        Add-Member -Name IsSealed -MemberType 'NoteProperty' -Value $t.IsSealed -PassThru |
        Add-Member -Name IsSerializable -MemberType 'NoteProperty' -Value $t.IsSerializable -PassThru |
        Add-Member -Name IsSpecialName -MemberType 'NoteProperty' -Value $t.IsSpecialName -PassThru |
        Add-Member -Name IsUnicodeClass -MemberType 'NoteProperty' -Value $t.IsUnicodeClass -PassThru |
        Add-Member -Name IsValueType -MemberType 'NoteProperty' -Value $t.IsValueType -PassThru |
        Add-Member -Name IsVisible -MemberType 'NoteProperty' -Value $t.IsVisible -PassThru |
        Add-Member -Name LastAccessTime -MemberType 'NoteProperty' -Value $f.LastAccessTime -PassThru |
        Add-Member -Name LastAccessTimeUtc -MemberType 'NoteProperty' -Value $f.LastAccessTimeUtc -PassThru |
        Add-Member -Name LastWriteTime -MemberType 'NoteProperty' -Value $f.LastWriteTime -PassThru |
        Add-Member -Name LastWriteTimeUtc -MemberType 'NoteProperty' -Value $f.LastWriteTimeUtc -PassThru |
        Add-Member -Name MemberType -MemberType 'NoteProperty' -Value $t.MemberType -PassThru |
        Add-Member -Name MetadataToken -MemberType 'NoteProperty' -Value $t.MetadataToken -PassThru |
        Add-Member -Name Module -MemberType 'NoteProperty' -Value $t.Module -PassThru |
        Add-Member -Name Name -MemberType 'NoteProperty' -Value $t.Name -PassThru |
        Add-Member -Name Namespace -MemberType 'NoteProperty' -Value $t.Namespace -PassThru |
        Add-Member -Name Parent -MemberType 'NoteProperty' -Value $f.Parent -PassThru |
        Add-Member -Name ReflectedType -MemberType 'NoteProperty' -Value $t.ReflectedType -PassThru |
        Add-Member -Name Root -MemberType 'NoteProperty' -Value $f.Root -PassThru |
        Add-Member -Name StructLayoutAttribute -MemberType 'NoteProperty' -Value $t.StructLayoutAttribute -PassThru |
        Add-Member -Name TypeHandle -MemberType 'NoteProperty' -Value $t.TypeHandle -PassThru |
        Add-Member -Name TypeInitializer -MemberType 'NoteProperty' -Value $t.TypeInitializer -PassThru |
        Add-Member -Name UnderlyingSystemType -MemberType 'NoteProperty' -Value $t.UnderlyingSystemType -PassThru |
        Add-Member -Name PSChildName -MemberType 'NoteProperty' -Value $f.PSChildName -PassThru |
        Add-Member -Name PSDrive -MemberType 'NoteProperty' -Value $f.PSDrive -PassThru |
        Add-Member -Name PSIsContainer -MemberType 'NoteProperty' -Value $f.PSIsContainer -PassThru |
        Add-Member -Name PSParentPath -MemberType 'NoteProperty' -Value $f.PSParentPath -PassThru |
        Add-Member -Name PSPath -MemberType 'NoteProperty' -Value $f.PSPath -PassThru |
        Add-Member -Name PSProvider -MemberType 'NoteProperty' -Value $f.PSProvider -PassThru |
        Add-Member -Name BaseName -MemberType 'NoteProperty' -Value $f.BaseName -PassThru |
        Add-Member -Name Clone -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name CompareTo -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name Contains -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name CopyTo -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name Create -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name CreateObjRef -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name CreateSubdirectory -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name Delete -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name EndsWith -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name FindInterfaces -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name FindMembers -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetAccessControl -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetArrayRank -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetConstructor -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetConstructors -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetCustomAttributes -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetDefaultMembers -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetDirectories -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetElementType -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetEnumerator -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetEvent -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetEvents -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetField -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetFields -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetFiles -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetFileSystemInfos -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetGenericArguments -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetGenericParameterConstraints -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetGenericTypeDefinition -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetInterface -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetInterfaceMap -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetInterfaces -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetLifetimeService -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetMember -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetMembers -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetMethod -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetMethods -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetNestedType -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetNestedTypes -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetObjectData -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetProperties -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetProperty -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name GetTypeCode -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name IndexOf -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name IndexOfAny -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name InitializeLifetimeService -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name Insert -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name InvokeMember -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name IsAssignableFrom -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name IsDefined -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name IsInstanceOfType -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name IsNormalized -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name IsSubclassOf -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name LastIndexOf -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name LastIndexOfAny -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name MakeArrayType -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name MakeByRefType -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name MakeGenericType -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name MakePointerType -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name MoveTo -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name Normalize -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name PadLeft -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name PadRight -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name Refresh -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name Remove -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name Replace -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name SetAccessControl -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name Split -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name StartsWith -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name Substring -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name ToCharArray -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name ToLower -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name ToLowerInvariant -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name ToUpper -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name ToUpperInvariant -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name Trim -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name TrimEnd -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name TrimStart -MemberType 'ScriptMethod' -Value {} -PassThru |
        Add-Member -Name Chars -MemberType 'NoteProperty' -Value $s.Chars -PassThru
    }


    if ( "Add-Member" -eq $_cmdlet )
    {
        $global:_dummy = $null
    }


    if ( "Compare-Object" -eq $_cmdlet )
    {
        $global:_dummy =  (Compare-Object 1 2)[0]
    }


    if ( "ConvertFrom-SecureString" -eq $_cmdlet )
    {
        $global:_dummy = $null
    }


    if ( "ConvertTo-SecureString" -eq $_cmdlet )
    {
        $global:_dummy = convertto-securestring "P@ssW0rD!" -asplaintext -force
    }


    if ( "ForEach-Object" -eq $_cmdlet )
    {
        $global:_dummy = $null
    }


    if ( "Get-Acl" -eq $_cmdlet )
    {
        $global:_dummy = Get-Acl
    }


    if ( "Get-Alias" -eq $_cmdlet )
    {
        $global:_dummy = (Get-Alias)[0]
    }


    if ( "Get-AuthenticodeSignature" -eq $_cmdlet )
    {
        $global:_dummy = Get-AuthenticodeSignature $PSHOME\powershell.exe
    }


    if ( "Get-ChildItem" -eq $_cmdlet )
    {
        $global:_dummy = $global:_forgci
    }


    if ( "Get-Command" -eq $_cmdlet )
    {
        $global:_dummy = @(iex $str[$i+1])[0]
    }


    if ( "Get-Content" -eq $_cmdlet )
    {
        $global:_dummy = (type $PSHOME\profile.ps1)[0]
    }


    if ( "Get-Credential" -eq $_cmdlet )
    {
        $global:_dummy = $null
    }


    if ( "Get-Culture" -eq $_cmdlet )
    {
        $global:_dummy = Get-Culture
    }


    if ( "Get-Date" -eq $_cmdlet )
    {
        $global:_dummy = Get-Date
    }


    if ( "Get-Event" -eq $_cmdlet )
    {
        $global:_dummy = (Get-Event)[0]
    }


    if ( "Get-EventLog" -eq $_cmdlet )
    {
        $global:_dummy = Get-EventLog Windows` PowerShell -Newest 1
    }


    if ( "Get-ExecutionPolicy" -eq $_cmdlet )
    {
        $global:_dummy = Get-ExecutionPolicy
    }


    if ( "Get-Help" -eq $_cmdlet )
    {
        $global:_dummy = Get-Help Add-Content
    }


    if ( "Get-History" -eq $_cmdlet )
    {
        $global:_dummy = Get-History -Count 1
    }


    if ( "Get-Host" -eq $_cmdlet )
    {
        $global:_dummy = Get-Host
    }


    if ( "Get-Item" -eq $_cmdlet )
    {
        $global:_dummy = $global:_forgci
    }


    if ( "Get-ItemProperty" -eq $_cmdlet )
    {
        $global:_dummy = $null
    }


    if ( "Get-Location" -eq $_cmdlet )
    {
        $global:_dummy = Get-Location
    }


    if ( "Get-Member" -eq $_cmdlet )
    {
        $global:_dummy = (1|Get-Member)[0]
    }


    if ( "Get-Module" -eq $_cmdlet )
    {
        $global:_dummy = (Get-Module)[0]
    }


    if ( "Get-PfxCertificate" -eq $_cmdlet )
    {
        $global:_dummy = $null
    }


    if ( "Get-Process" -eq $_cmdlet )
    {
        $global:_dummy = ps powershell
    }


    if ( "Get-PSBreakpoint" -eq $_cmdlet )
    {
        $global:_dummy =
        Add-Member -InputObject (New-Object PSObject) -Name Action -MemberType 'NoteProperty' -Value '' -PassThru |
        Add-Member -Name Command -MemberType 'NoteProperty' -Value '' -PassThru |
        Add-Member -Name Enabled -MemberType 'NoteProperty' -Value '' -PassThru |
        Add-Member -Name HitCount -MemberType 'NoteProperty' -Value '' -PassThru |
        Add-Member -Name Id -MemberType 'NoteProperty' -Value '' -PassThru |
        Add-Member -Name Script -MemberType 'NoteProperty' -Value '' -PassThru
    }


    if ( "Get-PSCallStack" -eq $_cmdlet )
    {
        $global:_dummy = Get-PSCallStack
    }


    if ( "Get-PSDrive" -eq $_cmdlet )
    {
        $global:_dummy = Get-PSDrive Function
    }


    if ( "Get-PSProvider" -eq $_cmdlet )
    {
        $global:_dummy = Get-PSProvider FileSystem
    }


    if ( "Get-PSSnapin" -eq $_cmdlet )
    {
        $global:_dummy = Get-PSSnapin Microsoft.PowerShell.Core
    }


    if ( "Get-Service" -eq $_cmdlet )
    {
        $global:_dummy = (Get-Service)[0]
    }


    if ( "Get-TraceSource" -eq $_cmdlet )
    {
        $global:_dummy = Get-TraceSource AddMember
    }


    if ( "Get-UICulture" -eq $_cmdlet )
    {
        $global:_dummy = Get-UICulture
    }


    if ( "Get-Variable" -eq $_cmdlet )
    {
        $global:_dummy = Get-Variable _
    }


    if ( "Get-WmiObject" -eq $_cmdlet )
    {
        $global:_dummy = @(iex $str[$i+1])[0]
    }


    if ( "Group-Object" -eq $_cmdlet )
    {
        $global:_dummy = 1 | group
    }


    if ( "Measure-Command" -eq $_cmdlet )
    {
        $global:_dummy = Measure-Command {}
    }


    if ( "Measure-Object" -eq $_cmdlet )
    {
        $global:_dummy = Measure-Object
    }


    if ( "New-PSDrive" -eq $_cmdlet )
    {
        $global:_dummy =  Get-PSDrive Alias
    }


    if ( "New-TimeSpan" -eq $_cmdlet )
    {
        $global:_dummy = New-TimeSpan
    }


    if ( "Resolve-Path" -eq $_cmdlet )
    {
        $global:_dummy = $PWD
    }


    if ( "Select-String" -eq $_cmdlet )
    {
        $global:_dummy = " " | Select-String " "
    }


    if ( "Set-Date" -eq $_cmdlet )
    {
        $global:_dummy =  Get-Date
    }

    if ( $property -ne $null)
    {
        foreach ( $name in $property.Split(";", "RemoveEmptyEntries" -as [System.StringSplitOptions]) )
        {
        $global:_dummy = @($global:_dummy.$name)[0]
        }
    }
}

function Set-CommandLine ( [string]$script ) { $global:_cmdline.Add($script) }

function Get-CommandLine ( [string]$name ) {
$name = $name -replace '\?','`?'
$global:_cmdline -like "$name*"
}


function TabExpansion {
            # This is the default function to use for tab expansion. It handles simple
            # member expansion on variables, variable name expansion and parameter completion
            # on commands. It doesn't understand strings so strings containing ; | ( or { may
            # cause expansion to fail.

            param($line, $lastWord)

            & {
                # Helper function to write out the matching set of members. It depends
                # on dynamic scoping to get $_base, _$expression and $_pat
                function Write-Members ($sep='.')
                {

                    # evaluate the expression to get the object to examine...
                    Invoke-Expression ('$_val=' + $_expression)

                    if ( $_expression -match '^\$global:_dummy' )
                    {
                        $temp = $_expression -replace '^\$global:_dummy(.*)','$1'
                        $_expression = '$_' + $temp
                    }


                    $_method = [Management.Automation.PSMemberTypes] `
                        'Method,CodeMethod,ScriptMethod,ParameterizedProperty'

                    if ($sep -eq '.')
                    {
                        $members = 
                            (
                                [Object[]](Get-Member -InputObject $_val.PSextended $_pat) + 
                                [Object[]](Get-Member -InputObject $_val.PSadapted $_pat) + 
                                [Object[]](Get-Member -InputObject $_val.PSbase $_pat)
                            )
                        if ( $_val -is [Hashtable] )
                        {
                            [Microsoft.PowerShell.Commands.MemberDefinition[]]$_keys = $null
                            foreach ( $_name in $_val.Keys )
                            {
                                $_keys += `
                                New-Object Microsoft.PowerShell.Commands.MemberDefinition `
                                [int],$_name,"Property",0
                            }

                            $members += [Object[]]$_keys | ? { $_.Name -like $_pat }
                        }

                        foreach ($_m in $members | sort membertype,name -Unique)
                            {
                                if ($_m.MemberType -band $_method)
                                {
                                    # Return a method...
                                    $_base + $_expression + $sep + $_m.name + '('
                                }
                                else {
                                    # Return a property...
                                    $_base + $_expression + $sep + $_m.name
                                }
                            }
                        }

                    else
                    {
                    foreach ($_m in Get-Member -Static -InputObject $_val $_pat |
                        Sort-Object membertype,name)
                       {
                           if ($_m.MemberType -band $_method)
                           {
                               # Return a method...
                               $_base + $_expression + $sep + $_m.name + '('
                           }
                           else {
                               # Return a property...
                               $_base + $_expression + $sep + $_m.name
                           }
                        }
                    }
                }


                switch ([int]$line[-1])
                {
                    # Ctrl+D several date/time formats
                    4 {
                        "[DateTime]::Now"
                        [DateTime]::Now
                        [DateTime]::Now.ToString("yyyyMMdd")
                        [DateTime]::Now.ToString("MMddyyyy")
                        [DateTime]::Now.ToString("yyyyMMddHHmmss")
                        [DateTime]::Now.ToString("MMddyyyyHHmmss")
                        'd f g m o r t u y'.Split(" ") | % { [DateTime]::Now.ToString($_) }
                        break TabExpansion;
                    }

                    # Ctrl+K put parentheses behind space or semi-coron or pipe operator
                    11 {
                        if ( $line -ne $( "=" + [Char]11 ) )
                        {
                            if ( $line[-2] -eq 11 )
                            {
                                $left = '$' + "("
                                $line = $line.Substring(0,$line.length-2)
                            }
                            else
                            {
                                $left = "("
                                $line = $line.Substring(0,$line.length-1)
                            }

                            $global:_ctrlk = @()
                            $l = $line.Length
                            while ( $l -ge 0 )
                            {
                                $i = $line.Substring(0,$l).LastIndexOfAny(" ;|")
                                $global:_ctrlk += $line.Insert($i+1, $left) + ")"
                                $l = $i
                            }
                            $global:_ctrlk += $line
                            [Windows.Forms.SendKeys]::SendWait("{Esc}=^K{TAB}")
                        }
                        else {
                            $global:_ctrlk
                        }
                        break TabExpansion;
                    }

                    # Ctrl+L a part of history commands expansion
                    12 {
                        Get-CommandLine $lastWord.SubString(0, $lastword.Length-1)
                        break TabExpansion;
                    }

                    # Ctrl+P hand-operated pop from command buffer stack
                    16 {
                        $_base = $lastword.SubString(0, $lastword.Length-1)
                        $_buf = $global:_cmdstack.Pop()
                        if ( $_buf.Contains("'") )
                        {
                            $line = ($line.SubString(0, $line.Length-1) + $_buf) -replace '([[\]\(\)+{}?~%])','{$1}'
                            [System.Windows.Forms.SendKeys]::SendWait("{Esc}$line")
                        }
                        else {
                            $_base + $_buf
                        }
                        break TabExpansion;
                    }

                    # Ctrl+R $Host.UI.RawUI.
                    18 {
                        '$Host.UI.RawUI.'
                        '$Host.UI.RawUI'
                        break TabExpansion;
                    }

                    # Ctrl+V paste clipboard
                    22 {
                        $_base = $lastword.SubString(0, $lastword.Length-1)
                        $global:_clip = New-Object System.Windows.Forms.TextBox
                        $global:_clip.Multiline = $true
                        $global:_clip.Paste()
                        $line = ($line.SubString(0, $line.Length-1) + $global:_clip.Text) -replace '([[\]\(\)+{}?~%])','{$1}'
                        [System.Windows.Forms.SendKeys]::SendWait("{Esc}$line")
                        break TabExpansion;
                    }

                    # Ctrl+X cut current line
                    24 {
                        $_clip = new-object System.Windows.Forms.TextBox;
                        $_clip.Multiline = $true;
                        $_clip.Text = $line.SubString(0, $line.Length-1)
                        $_clip.SelectAll()
                        $_clip.Copy()
                        [System.Windows.Forms.SendKeys]::SendWait("{ESC}")
                        break TabExpansion;
                    }

                    # Ctrl+Z cut last word in current line
                    26 {
                        $line.SubString(0, $line.Length-1) -match '(^(.*\s)([^\s]*)$)|(^[^\s]*$)' | Out-Null
                        $_clip = new-object System.Windows.Forms.TextBox;
                        $_clip.Multiline = $true;
                        $_clip.Text = $Matches[3]
                        $_clip.SelectAll()
                        $_clip.Copy()
                        [System.Windows.Forms.SendKeys]::SendWait("{ESC}")
                        $line = $Matches[2] -replace '([[\]\(\)+{}?~%])','{$1}'
                        [System.Windows.Forms.SendKeys]::SendWait($line)
                        break TabExpansion;
                    }
                }

                switch ( [int]$line[-2] )
                {

                    # Ctrl+K put character behind space or semi-coron or pipe operator
                    11 {
                        switch ( $line[-1] )
                        {
                            '{' { $right = '}' }
                            '(' { $right = ')' }
                            '[' { $right = ']' }
                        }

                        $left = $line[-1]
                        $delimiter = " ;|"

                        if ( $line[-3] -eq 11 )
                        {
                            if ( $line[-1] -eq '%' -or $line[-1] -eq '?' )
                            {
                                $left = ' ' + $left + ' {'; $right = '}'
                                $delimiter = '|'
                            }
                            else
                            {
                                $left = '$' + $left
                            }
                            $line = $line.Substring(0,$line.length-3)
                        }
                        else
                        {
                            $line = $line.Substring(0,$line.length-2)
                        }

                        $global:_ctrlk = @()
                        $l = $line.Length
                        while ( $l -ge 0 )
                        {
                            $i = $line.Substring(0,$l).LastIndexOfAny($delimiter)
                            $global:_ctrlk += $line.Insert($i+1, $left) + $right
                            $l = $i
                        }
                        $global:_ctrlk += $line
                        [Windows.Forms.SendKeys]::SendWait("{Esc}=^K{TAB}")
                        break TabExpansion;
                    }

                    # Ctrl+X cut words with a character after Ctrl+X until the character
                    24 {
                        $line.SubString(0, $line.Length-2) -match "(^(.*$($line[-1]))([^$($line[-1])]*)`$)|(^[^\$($line[-1])]*`$)" | Out-Null
                        $_clip = new-object System.Windows.Forms.TextBox;
                        $_clip.Multiline = $true;
                        $_clip.Text = $Matches[3]
                        $_clip.SelectAll()
                        $_clip.Copy()
                        [System.Windows.Forms.SendKeys]::SendWait("{ESC}")
                        $line = $Matches[2] -replace '([[\]\(\)+{}?~%])','{$1}'
                        [System.Windows.Forms.SendKeys]::SendWait($line)
                        break TabExpansion;
                    }
                }

                switch -regex ($lastWord)
                {

                    # Handle property and method expansion at '$_'
                    '(^.*)(\$_\.)(\w*)$' {
                        $_base = $matches[1]
                        $_expression = '$global:_dummy'
                        $_pat = $matches[3] + '*'
                        $global:_dummy = $null
                        Get-PipeLineObject
                        if ( $global:_dummy -eq $null )
                        {

                            if ( $global:_exp -match '^\$.*\(.*$' )
                            {
                                $type = ( iex $_exp.Split("(")[0] ).OverloadDefinitions[0].Split(" ")[0] -replace '\[[^\[\]]*\]$' -as [type]

                                if ( $_expression -match '^\$global:_dummy' )
                                {
                                    $temp = $_expression -replace '^\$global:_dummy(.*)','$1'
                                    $_expression = '$_' + $temp
                                }

                                foreach ( $_m in $type.GetMembers() | sort membertype,name | group name | ? { $_.Name -like $_pat } | % { $_.Group[0] } )
                                {
                                   if ($_m.MemberType -eq "Method")
                                   {
                                       $_base + $_expression + '.' + $_m.name + '('
                                   }
                                   else {
                                       $_base + $_expression + '.' + $_m.name
                                   }
                                }
                                break;
                            }
                            elseif ( $global:_exp -match '^\[.*\:\:.*\(.*$' )
                            {
                                $tname, $mname = $_exp.Split(":(", "RemoveEmptyEntries"-as [System.StringSplitOptions])[0,1]
                                $type = @(iex ($tname + '.GetMember("' + $mname + '")'))[0].ReturnType.FullName -replace '\[[^\[\]]*\]$' -as [type]

                                if ( $_expression -match '^\$global:_dummy' )
                                {
                                    $temp = $_expression -replace '^\$global:_dummy(.*)','$1'
                                    $_expression = '$_' + $temp
                                }

                                foreach ( $_m in $type.GetMembers() | sort membertype,name | group name | ? { $_.Name -like $_pat } | % { $_.Group[0] } )
                                {
                                   if ($_m.MemberType -eq "Method")
                                   {
                                       $_base + $_expression + '.' + $_m.name + '('
                                   }
                                   else {
                                       $_base + $_expression + '.' + $_m.name
                                   }
                                }
                                break;
                            }
                            elseif ( $global:_exp -match '^(\$\w+(\[[0-9,\.]+\])*(\.\w+(\[[0-9,\.]+\])*)*)$' )
                            {
                                $global:_dummy = @(iex $Matches[1])[0]
                            }
                            else
                            {
                                $global:_dummy =  $global:_mix
                            }
                        }

                        Write-Members
                        break;
                    }

                    # Handle property and method expansion rooted at variables...
                    # e.g. $a.b.<tab>
                    '(^.*)(\$(\w|\.)+)\.(\w*)$' {
                        $_base = $matches[1]
                        $_expression = $matches[2]
                        [void] ( iex "$_expression.IsDataLanguageOnly" ) # for [ScriptBlock]
                        $_pat = $matches[4] + '*'
                        if ( $_expression -match '^\$_\.' )
                        {
                            $_expression = $_expression -replace '^\$_(.*)',('$global:_dummy' + '$1')
                        }
                        Write-Members
                        break;
                    }

                    # Handle simple property and method expansion on static members...
                    # e.g. [datetime]::n<tab>
                    '(^.*)(\[(\w|\.)+\])\:\:(\w*)$' {
                        $_base = $matches[1]
                        $_expression = $matches[2]
                        $_pat = $matches[4] + '*'
                        Write-Members '::'
                        break;
                    }

                    # Handle complex property and method expansion on static members
                    # where there are intermediate properties...
                    # e.g. [datetime]::now.d<tab>
                    '(^.*)(\[(\w|\.)+\]\:\:(\w+\.)+)(\w*)$' {
                        $_base = $matches[1]  # everything before the expression
                        $_expression = $matches[2].TrimEnd('.') # expression less trailing '.'
                        $_pat = $matches[5] + '*'  # the member to look for...
                        Write-Members
                        break;
                    }

                    # Handle property and method expansion rooted at variables...
                    # e.g. { 1+1 }.inv<tab>
                    '(^.*})\.(\w*)$' {
                        $_base = $matches[1]
                        $_pat = $matches[2] + '*'
                        foreach ( $_m in {} | Get-Member $_pat | sort membertype,name )
                        {
                            if ($_m.MemberType -eq "Method")
                            {
                                $_base + '.' + $_m.name + '('
                            }
                            else {
                                $_base + '.' + $_m.name
                            }
                        }
                        break;
                    }

                    # Handle variable name expansion...
                    '(^.*\$)(\w+)$' {
                        $_prefix = $matches[1]
                        $_varName = $matches[2]
                        foreach ($_v in Get-ChildItem ('variable:' + $_varName + '*'))
                        {
                            $_prefix + $_v.name
                        }
                        break;
                    }

                    # Handle item name expansion in variable notation...
                    '(^.*\${)(((\w+):([\\/]?))[^\\/]+([\\/][^\\/]*)*)$' {
                        $_prefix = $matches[1]
                        $_driveName = $matches[3]
                        $_itemName = $matches[2] + "*"
                        Get-ChildItem $_itemName  |
                        % {
                            if ( $matches[5] -and $_.PSProvider.Name -eq "FileSystem" )
                            {
                                $output = $_prefix + $_.FullName
                            }
                            elseif ( $_.PSProvider.Name -eq "FileSystem" -and $matches[6] )
                            {
                                $cd = (Get-Location -PSDrive $matches[4]).Path
                                $output = $_prefix + $_driveName + $_.FullName.Substring($cd.Length+1)
                            }
                            elseif ( $_.PSProvider.Name -eq "FileSystem" )
                            {
                                $cd = (Get-Location -PSDrive $matches[4]).Path
                                $output = $_prefix + $_driveName + $_.FullName.Substring($cd.Length+1)
                            }
                            else
                            {
                                $output = $_prefix + $_driveName + $_.Name
                            }

                            if ( $_.PSIsContainer )
                            {
                                $output
                            }
                            else
                            {
                                $output + "}"
                            }
                        }
                        break;
                    }

                    # Handle PSDrive name expansion in variable notation...
                    '(^.*\${)(\w+)$' {
                        $_prefix = $matches[1]
                        $_driveName = $matches[2] + "*"
                        Get-PSDrive $_driveName | % { $_prefix + $_ + ':' }
                        break;
                    }

                    # Handle env&function drives variable name expansion...
                    '(^.*\$)(.*\:)(\w+)$' {
                        $_prefix = $matches[1]
                        $_drive = $matches[2]
                        $_varName = $matches[3]
                        if ($_drive -eq "env:" -or $_drive -eq "function:")
                        {
                            foreach ($_v in Get-ChildItem ($_drive + $_varName + '*'))
                            {
                                $_prefix + $_drive + $_v.name
                            }
                        }
                        break;
                    }

                    # Handle array's element property and method expansion
                    # where there are intermediate properties...
                    # e.g. foo[0].n.b<tab>
                    '(^.*)(\$((\w+\.)|(\w+(\[(\w|,)+\])+\.))+)(\w*)$'
                    {
                        $_base = $matches[1]
                        $_expression = $matches[2].TrimEnd('.')
                        $_pat = $Matches[8] + '*'
                        [void] ( iex "$_expression.IsDataLanguageOnly" ) # for [ScriptBlock]
                        if ( $_expression -match '^\$_\.' )
                        {
                            $_expression = $_expression -replace '^\$_(.*)',('$global:_dummy' + '$1')
                        }
                        Write-Members
                        break;
                    }

                    # Handle property and method expansion rooted at type object...
                    # e.g. [System.Type].a<tab>
                    '(^\[(\w|\.)+\])\.(\w*)$'
                    {
                        if ( $(iex $Matches[1]) -isnot [System.Type] ) { break; }
                        $_expression = $Matches[1]
                        $_pat = $Matches[$matches.Count-1] + '*'
                        Write-Members
                        break;
                    }

                    # Handle complex property and method expansion on type object members
                    # where there are intermediate properties...
                    # e.g. [datetime].Assembly.a<tab>
                    '^(\[(\w|\.)+\]\.(\w+\.)+)(\w*)$' {
                        $_expression = $matches

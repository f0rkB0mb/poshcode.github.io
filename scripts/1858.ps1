<#
   Name     : Universal NLog Logging Module (NLog.psm1)
   Version  : 0.6 2010-05-17
   Author   : Joel Bennett (MVP)
   Site     : http://www.HuddledMasses.org/

   Version History:
   0.6 - Removed a few references to Log4Net that had been left behind (oops).
   
   0.5 - Port to NLog from Log4Net ( http://nlog-project.org )
         Include support for Growl plugin for NLog, but left out the rotating log files stuff (I'll get to that later).
         http://ryanfarley.com/blog/archive/2010/05/06/announcing-the-growl-for-windows-target-for-nlog.aspx

   0.4 - Bugfix, Viewer and Documentation release.
         Fixed a few typo-bugs
         Added documentation (man page) comments for Get-Logger.
         Changed a few parameter names (sorry) to make the default parameters more unique (so you have to type less on the command-line)
         Changed the default logger to use the logger module's folder as a backup
            (Some people might not have the Profile path -- this module could be installed anywhere and loaded by file name)
         Fixed up the xml output with a nice stylesheet http`://poshcode.org/1750 that formats and makes the page refresh.
   
   0.3 - Cleanupable release.
         Added Udp, Email,  Xml and RollingXml, as well as a "Chainsaw":http`://logging.apache.org/log4j/docs/chainsaw.html logger based on "Szymon Kobalczyk's configuration":http`://geekswithblogs.net/kobush/archive/2005/07/15/46627.aspx.
         Note: there is a "KNOWN BUG with Log4Net UDP":http`://odalet.wordpress.com/2007/01/13/log4net-ip-parsing-bug-when-used-with-framework-net-20/ which can be patched, but hasn't been released.
         Added a Close-Logger method to clean up the Xml logger 
         NOTE: the Rolling XML Logger produces invalid XML, and the XML logger only produces valid xml after it's been closed...
               I did contribute an "XSLT stylesheet for Log4Net":http`://poshcode.org/1746 which you could use as well
         
   0.2 - Configless release. 
         Now configures with inline XML, and supports switches to create "reasonable" default loggers
         Changed all the functions to Write-*Log so they don't overwrite the cmdlets
         Added -Logger parameter to take the name of the logger to use (it must be created beforehand via Get-Logger)
         Created aliases for Write-* to override the cmdlets -- these are easy for users to remove without breaking the module
         ** NEED to write some docs, but basically, this is stupid simple to use, just:
            Import-Module Logger
            Write-Verbose "This message will be saved in your profile folder in a file named PowerShellLogger.log (by default)"
         To change the defaults for your system, edit the last line in the module!!
   0.1 - Initial release. http`://poshcode.org/1744 (Required config: http`://poshcode.org/1743)

   Uses NLog 2.0 : http://nlog-project.org
   Documentation : http://nlog-project.org/documentation.html
   
   NOTES:
   By default, this overwrites the Write-* cmdlets for Error, Warning, Debug, Verbose, and even Host.
   This means that you may end up logging a lot of stuff you didn't intend to log (ie: verbose output from other scripts)
   
   To avoid this behavior, remove the aliases after importing it
   Import-Module Logger; Remove-Item Alias:Write-*
   Write-Warning "This is your warning"
   Write-Debug   "You should know that..."
   Write-Verbose "Everything would be logged, otherwise"   

   ***** NOTE: IT ONLY OVERRIDES THE DEFAULTS FOR SCRIPTS *****
   It currently has no effect on error/verbose/warning that is logged from cmdlets.
   
#>

Add-Type -Path $PSScriptRoot\NLog.dll

function Get-RelativePath {
<#
.SYNOPSIS
   Get a path to a file (or folder) relative to another folder
.DESCRIPTION
   Converts the FilePath to a relative path rooted in the specified Folder
.PARAMETER Folder
   The folder to build a relative path from
.PARAMETER FilePath
   The File (or folder) to build a relative path TO
.PARAMETER Resolve
   If true, the file and folder paths must exist
.Example
   Get-RelativePath ~\Documents\WindowsPowerShell\Logs\ ~\Documents\WindowsPowershell\Modules\Logger\log4net.xslt
   
   ..\Modules\Logger\log4net.xslt
   
   Returns a path to log4net.xslt relative to the Logs folder
#>
[CmdletBinding()]
param(
   [Parameter(Mandatory=$true, Position=0)]
   [string]$Folder
, 
   [Parameter(Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true)]
   [Alias("FullName")]
   [string]$FilePath
,
   [switch]$Resolve
)
process {
   $from = $Folder = split-path $Folder -NoQualifier -Resolve:$Resolve
   $to = $filePath = split-path $filePath -NoQualifier -Resolve:$Resolve

   while($from -and $to -and ($from -ne $to)) {
      if($from.Length -gt $to.Length) {
         $from = split-path $from
      } else {
         $to = split-path $to
      }
   }

   $filepath = $filepath -replace "^"+[regex]::Escape($to)+"\\"
   $from = $Folder
   while($from -and $to -and $from -gt $to ) {
      $from = split-path $from
      $filepath = join-path ".." $filepath
   }
   Write-Output $filepath
}
}

function Get-Logger {
<#
.SYNOPSIS
   Get an existing Logger by name, or create a new logger
.DESCRIPTION
   Returns a logger matching the name (wildcards allowed) provided. 
   
   If the logger already exists, it is returned with it's settings as-is, unless the -Force switch is specified, in which case the new settings are used
   
   If only one logger matches the name, that logger becomes the new default logger.

.PARAMETER Name
   The name of the logger to find or create. If no name is specified, all existing loggers are returned.

.PARAMETER Level
   The level at which to log in this new logger. Defaults to "DEBUG" 
   Possible levels are as follows (each level includes all levels above it):
   
   FATAL
   ERROR
   WARN  (aka WARNING)
   INFO  (aka VERBOSE, HOST)
   DEBUG
   
.PARAMETER MessagePattern
   The pattern for loggers which use patterns (mostly the file loggers). Defaults to: 
   ' ${longdate} ${level:uppercase=true} ${logger} [${ndc}] [${ndc}] - ${message}${newline}'
   
   For a complete list of possible pattern names, see:
   http://nlog-project.org/layoutrenderers.html

.PARAMETER Growl
   Outputs log messages to growl
   For reference see:
   http://ryanfarley.com/blog/archive/2010/05/06/announcing-the-growl-for-windows-target-for-nlog.aspx
.PARAMETER Folder
   The folder where log files are kept. Defaults to your Documents\WindowsPowerShell folder.
   NOTE: if the specified folder does not exist, the fallback is your Documents\WindowsPowerShell folder,
         but if that doesn't exist, the folder where this file is stored is used.

.PARAMETER EmailTo
   An email address to send WARNING or above messages to. REQUIRES that your $PSEmailServer variable be set
.PARAMETER Console
   Creates a colored console logger
.PARAMETER EventLog
   Creates an EventLog logger
.PARAMETER TraceLog
   Creates a .Net Trace logger
.PARAMETER DebugLog
   Creates a .Net Debug logger
.PARAMETER FileLog
   Creates a file logger. Note the LogLock parameter!
.PARAMETER RollingFileLog
   Creates a rolling file logger with a max size of 250KB. Note the LogLock parameter!   
.PARAMETER XmlLog
   Creates an Xml-formatted file logger. Note the LogLock parameter!
   
   Note: the XmlLog will output an XML Header and will add a footer when the logger is closed.
   This results in a log file which is readable in xml viewers like IE, particularly if you have a copy of the XSLT stylesheet for Log4Net (http://poshcode.org/1750) named log4net.xslt in the same folder with the log file.
   
   WARNING: Because of this, it does not APPEND to the file, but overwrites it each time you create the logger.
.PARAMETER RollingXmlLog
   Creates a rolling file Xml logger with a max size of 500KB. Note the LogLock parameter!
   
   Note: the rolling xml logger cannot create "valid" xml because it appends to the end of the file (and therefore can't guarantee the file is well-formed XML).
   In order to get a valid Xml file, you can use a "*View.xml" file with contents like this (which this script will create):
   
   <?xml version="1.0" ?>
   <?xml-stylesheet type="text/xsl" href="log4net.xslt"?>
   <!DOCTYPE events [<!ENTITY data SYSTEM "PowerShellLogger.xml">]>
   <log4net:events version="1.2" xmlns:log4net="http://logging.apache.org/log4net/schemas/log4net-events-1.2">
      &data;
   </log4net:events>
.PARAMETER LogLock
   Determines the type of file locking used (defaults to SHARED): 
   SHARED is the "MinimalLocking" model which opens the file once for each AcquireLock/ReleaseLock cycle, thus holding the lock for the minimal amount of time. This method of locking is considerably slower than...
   
   EXCLUSIVE is the "ExclusiveLocking" model which opens the file once for writing and holds it open until the logger is closed, maintaining an exclusive lock on the file the whole time..
.PARAMETER UdpSend
   Creates an UdpAppender which sends messages to the localmachine port 8080
   We'll probably tweak this in a future release, but for now if you need to change that you need to edit the script
.PARAMETER ChainsawSend
   Like UdpSend, creates an UdpAppender which sends messages to the localmachine port 8080. 
   This logger uses the log4j xml formatter which is somewhat different than the default, and uses their namespace.   
.PARAMETER Force
   Force resetting the logger switches even if the logger already exists
#>
param( 
   [Parameter(Mandatory=$false, Position=0)]
   [string]$Name = "*"
,
   [Parameter(Mandatory=$false)]
   # Actual Values: Trace, Debug, Info, Warn, Error, Fatal
   [ValidateSet("Verbose","Trace","Debug","Info","Host","Warn","Warning","Error","Fatal")]
   [string]$Level = "Trace"
,
   [Parameter(Mandatory=$false)]
   #" %date %-5level %logger [%property{NDC}] - %message%newline"
   $MessagePattern = ' ${longdate} ${level:uppercase=true} ${logger} - ${message}'
,
   [Parameter(Mandatory=$false)]
   [string]$Folder = $(Split-Path $Profile.CurrentUserAllHosts)
   
,  [String]$EmailTo
,  [Switch]$Force
,  [Switch]$ConsoleLog
,  [Switch]$EventLog
,  [Switch]$TraceLog
,  [Switch]$DebugLog
,  [Switch]$FileLog
#,  [Switch]$RollingFileLog
,  [Switch]$XmlLog
#,  [Switch]$RollingXmlLog
,  [Switch]$UdpSend
,  [Switch]$ChainsawSend
,  [Switch]$Growl
#  ,
   #  [Parameter(Mandatory=$false, Position=99)]
   #  [ValidateSet("Shared","Exclusive")]
   #  [String]$LogLock = "Shared"
)
   ## Make sure the folder exists
   if(!(Test-Path $Folder)) {
      $Folder = Split-Path $Profile.CurrentUserAllHosts
      if(!(Test-Path $Folder)) {
         $Folder = $PSScriptRoot
      }
   }
   
   $Script:NLogLoggersCollection | Where-Object { $_.Name -Like $Name } | Tee -var LoggerOutputBuffer
   
   if((!(test-path Variable:LoggerOutputBuffer) -or $Force) -and !$Name.Contains('*')) {
      if($Level -eq "VERBOSE") { $Level = "Trace" }
      if($Level -eq "HOST")    { $Level = "Info" }
      if($Level -eq "WARNING") { $Level = "Warn" }

      $Targets = @()
      if(test-path Variable:Email)        { 
         if(!$PSEmailServer) { throw "You need to specify your SMTP mail server by setting the global $PSEmailServer variable" }
         $Targets += "Mail"
         $Null,$Domain = $email -split "@",2
      } else { $Domain = "no.com" }
      
      #  if($LogLock -eq "Shared") { 
         #  $LockMode = "MinimalLock"
      #  } else {
         #  $LockMode = "ExclusiveLock"
      #  }
      
      $xslt = ""
      if(Test-Path $PSScriptRoot\log4net.xslt) {
         $xslt = @"
<?xml-stylesheet type="text/xsl" href="$(Get-RelativePath $Folder $PSScriptRoot\NLog.xslt)"?>
"@
      }
      Set-Content "${Folder}\${Name}View.Xml" @"
<?xml version="1.0" ?>
$xslt
<!DOCTYPE events [<!ENTITY data SYSTEM "$Name.xml">]>
<events version="1.2" xmlns:log4net="http`://logging.apache.org/log4net/schemas/log4net-events-1.2">
<logname>$Name</logname>
   &data;
</events>
"@
      if($EventLog)        { $Targets += "EventLog" }
      if($TraceLog)        { $Targets += "Trace" }
      if($DebugLog)        { $Targets += "Debug" }
      if($FileLog)         { $Targets += "File" }
      # if($RollingFileLog)  { $Targets += "<appender-ref ref=""RollingFileAppender"" />`n" }
      if($UdpSend)         { $Targets += "Udp" } 
      if($Growl)           { $Targets += "Growl" } 
      if($ChainsawSend)    { $Targets += "Chainsaw" } 
      if($XmlLog)          { $Targets += "Xml" } 
      # if($RollingXmlLog)   { $Targets += "<appender-ref ref=""RollingXmlAppender"" />`n"
      if($VerbosePreference -gt "SilentlyContinue") { "Created XML viewer for you at: ${Folder}\${Name}View.Xml" }
     
      $xslt = $xslt -replace "<","&lt;" -replace ">","&gt;" -replace '"',"'"
      if($ConsoleLog -or ($Targets.Count -eq 0)) { $Targets += "Console" }
      
      $extensions = ""
      if($Growl -and (Test-Path $PSScriptRoot\NLog.Targets.GrowlNotify.dll)){
         $extensions = @"
      <extensions>
         <add assembly="NLog.Targets.GrowlNotify" />
      </extensions>
"@ }

      $OFS = ","
      [xml]$config = @"
<nlog xmlns="http://www.nlog-project.org/schemas/NLog.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
   $extensions
   <targets>
      <target name="Console"  xsi:type="ColoredConsole"                               layout="$MessagePattern"/>
      <target name="File"     xsi:type="File" fileName="$Folder\$Name.log"            layout="$MessagePattern"/>
      <target name="Xml"      xsi:type="File" fileName="$Folder\$Name.xml"            layout="`${log4jxmlevent}"/>
      $(if($EventLog){ '<target name="EventLog" xsi:type="EventLog" log="Application" source="$Name"    layout="$MessagePattern"/>' })      
      <target name="Trace"    xsi:type="Trace"                                        layout="$MessagePattern"/>
      <target name="Debug"    xsi:type="Debugger"                                     layout="$MessagePattern"/>
      <target name="Udp"      xsi:type="Network" address="udp://localhost:8080"       layout="$MessagePattern"/>
      <target name="Chainsaw" xsi:type="Chainsaw" address="udp://localhost:8080" />
      $(if($Growl){ '<target name="Growl"    xsi:type="GrowlNotify"                   layout="$MessagePattern"/>' })
      <target name="Mail"     xsi:type="FilteringWrapper" condition="level > LogLevel.Debug or contains(message,'email')" >
         <target xsi:type="Mail" addNewLines="True" smtpServer="$PSEmailServer"       layout="$MessagePattern"
                                 from="PoshLogger@$Domain" to="$EmailTo" subject="PowerShell Logger Message" />
      </target>
   </targets> 
   <rules>
      <logger name="$Name" minlevel="$Level" writeTo="$Targets"/>
   </rules> 
</nlog>
"@
   $config.Save("${PSScriptRoot}\NLog.config")
      [NLog.LogManager]::Configuration = New-Object 'NLog.Config.XmlLoggingConfiguration' $config.nlog, $PSScriptRoot\NLog.config
      $Script:NLogLoggersCollection += $Script:Logger = [NLog.LogManager]::GetLogger($Name)
      write-output $Script:Logger
   }
   elseif($LoggerOutputBuffer.Count -eq 1) {
      $script:Logger = $LoggerOutputBuffer[0]
      write-output $Script:Logger
   }
   
}

function Set-Logger {
param(
   [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
   [NLog.Logger]$Logger
)
   $script:Logger = $Logger
}


function Push-LogContext {
param( 
   [Parameter(Mandatory=$true)]
   [string]$Name
)
   [NLog.Contexts.NestedDiagnosticsContext]::Push($Name)
}
function Pop-LogContext {
   [NLog.Contexts.NestedDiagnosticsContext]::Pop()
}

function Write-DebugLog {
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Msg')]
    [AllowEmptyString()]
    [System.String]
    ${Message}
,
   [Parameter(Mandatory=$false, Position=99)]
   ${Logger})

begin
{
    try {
        if($PSBoundParameters.ContainsKey("Logger")) {
            if($Logger -is [NLog.Logger]) { Set-Logger $Logger } else { $script:Logger = Get-Logger "$Logger" }
            $null = $PSBoundParameters.Remove("Logger")
        }
        
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Debug', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $script:logger.Debug($Message) #Write-Debug
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Write-Debug
.ForwardHelpCategory Cmdlet

#>
}
function Write-VerboseLog {

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Msg')]
    [AllowEmptyString()]
    [System.String]
    ${Message}
,
   [Parameter(Mandatory=$false, Position=99)]
   ${Logger})

begin
{
    try {
        if($PSBoundParameters.ContainsKey("Logger")) {
            if($Logger -is [NLog.Logger]) { Set-Logger $Logger } else { $script:Logger = Get-Logger "$Logger" }
            $null = $PSBoundParameters.Remove("Logger")
        }

        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Verbose', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $script:logger.Trace($Message)
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Write-Verbose
.ForwardHelpCategory Cmdlet

#>
}
function Write-WarningLog {
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Alias('Msg')]
    [AllowEmptyString()]
    [System.String]
    ${Message}
,
   [Parameter(Mandatory=$false, Position=99)]
   ${Logger})

begin
{
    try {
        if($PSBoundParameters.ContainsKey("Logger")) {
            if($Logger -is [NLog.Logger]) { Set-Logger $Logger } else { $script:Logger = Get-Logger "$Logger" }
            $null = $PSBoundParameters.Remove("Logger")
        }

        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Warning', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $script:logger.Warn($Message)  #Write-Warning
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Write-Warning
.ForwardHelpCategory Cmdlet

#>
}
function Write-ErrorLog {
[CmdletBinding(DefaultParameterSetName='NoException')]
param(
    [Parameter(ParameterSetName='WithException', Mandatory=$true)]
    [System.Exception]
    ${Exception},

    [Parameter(ParameterSetName='NoException', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='WithException')]
    [Alias('Msg')]
    [AllowNull()]
    [AllowEmptyString()]
    [System.String]
    ${Message},

    [Parameter(ParameterSetName='ErrorRecord', Mandatory=$true)]
    [System.Management.Automation.ErrorRecord]
    ${ErrorRecord},

    [Parameter(ParameterSetName='NoException')]
    [Parameter(ParameterSetName='WithException')]
    [System.Management.Automation.ErrorCategory]
    ${Category},

    [Parameter(ParameterSetName='WithException')]
    [Parameter(ParameterSetName='NoException')]
    [System.String]
    ${ErrorId},

    [Parameter(ParameterSetName='NoException')]
    [Parameter(ParameterSetName='WithException')]
    [System.Object]
    ${TargetObject},

    [System.String]
    ${RecommendedAction},

    [Alias('Activity')]
    [System.String]
    ${CategoryActivity},

    [Alias('Reason')]
    [System.String]
    ${CategoryReason},

    [Alias('TargetName')]
    [System.String]
    ${CategoryTargetName},

    [Alias('TargetType')]
    [System.String]
    ${CategoryTargetType}
,
   [Parameter(Mandatory=$false, Position=99)]
   ${Logger})

begin
{
    try {
        if($PSBoundParameters.ContainsKey("Logger")) {
            if($Logger -is [NLog.Logger]) { Set-Logger $Logger } else { $script:Logger = Get-Logger "$Logger" }
            $null = $PSBoundParameters.Remove("Logger")
        }

        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Error', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $script:logger.ErrorException($Message,$Exception) #Write-Error
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Write-Error
.ForwardHelpCategory Cmdlet

#>
}
function Write-HostLog {
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, Position=1, ValueFromPipeline=$true)]
    [System.Object]
    ${Object},

    [Switch]
    ${NoNewline},

    [System.Object]
    ${Separator} = $OFS,

    [System.ConsoleColor]
    ${ForegroundColor},

    [System.ConsoleColor]
    ${BackgroundColor},
    
   [Parameter(Mandatory=$false, Position=99)]
   ${Logger})

begin
{
    try {
        if($PSBoundParameters.ContainsKey("Logger")) {
            if($Logger -is [NLog.Logger]) { Set-Logger $Logger } else { $script:Logger = Get-Logger "$Logger" }
            $null = $PSBoundParameters.Remove("Logger")
        }

        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Host', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $script:logger.Info(($Object -join $Separator | Out-String))  #Write-Verbose
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Write-Host
.ForwardHelpCategory Cmdlet

#>
}

Set-Alias Write-Debug Write-DebugLog
Set-Alias Write-Verbose Write-VerboseLog
Set-Alias Write-Warning Write-WarningLog
Set-Alias Write-Error Write-ErrorLog
#Set-Alias Write-Host Write-HostLog

Export-ModuleMember -Function * -Alias *

$NLogLoggersCollection = @()

## THIS IS THE DEFAULT LOGGER. CONFIGURE AS YOU SEE FIT
$script:Logger = Get-Logger "PowerShellLogger" -File # -Console -Growl

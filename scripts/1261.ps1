[CmdletBinding()]
param(
    [Parameter(ParameterSetName='Object', Mandatory=$true, ValueFromPipeline=$true)]
    [AllowEmptyString()]
    [AllowNull()]
    [System.Management.Automation.PSObject]
    ${InputObject},

    [Parameter(Mandatory=$true, Position=0)]
    [System.String[]]
    ${Pattern},

    [Parameter(ParameterSetName='File', Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true)]
    [Alias('PSPath')]
    [System.String[]]
    ${Path},

    [Switch]
    ${SimpleMatch},

    [Switch]
    ${CaseSensitive},

    [Switch]
    ${Quiet},

    [Switch]
    ${List},

    [ValidateNotNullOrEmpty()]
    [System.String[]]
    ${Include},

    [ValidateNotNullOrEmpty()]
    [System.String[]]
    ${Exclude},

    [Switch]
    ${NotMatch},

    [Switch]
    ${AllMatches},

    [ValidateSet('unicode','utf7','utf8','utf32','ascii','bigendianunicode','default','oem')]
    [ValidateNotNullOrEmpty()]
    [System.String]
    ${Encoding},

    [ValidateNotNullOrEmpty()]
    [ValidateCount(1, 2)]
    [ValidateRange(0, 2147483647)]
    [System.Int32[]]
    ${Context})

begin
{
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Select-String', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
           
        # wrapper generated by New-ProxyCommand
        # http://blogs.msdn.com/powershell/archive/2009/01/04/extending-and-or-modifing-commands-with-proxies.aspx 

        # ------- modification added by Bernd Kriszio -- http://pauerschell.blogspot.com/
        # 
        #
        if (! $Encoding)
        {
            # it is ridiculous to call a parameter default which is not
            $PSBoundParameters.Encoding = 'default'

            <#
                # finally I want a values default_or_oem for -Encoding
                # to find strings in unicode, ansii and oem coded files
                # but it is not that simple
                @(Select-String * -pattern Ärger -encoding default) +
                @(Select-String * -pattern Ärger -encoding oem) |sort-object | Get-Unique
           #> 
          
        }
        # ---------------------------------------------------------------------
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
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

.ForwardHelpTargetName Select-String
.ForwardHelpCategory Cmdlet

#>



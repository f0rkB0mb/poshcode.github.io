<#
.SYNOPSIS
	Write message to screen with mix colors.
.DESCRIPTION
	Works like write-host but using color codes in the message will change the text colors.

    Support pipeline.  Output to pipeline is a string without color code.  Useful for writing same string to a log file.
.PARAMETER Message
	String to write to the screen.
	
	To change color in the string use the 2 flags inside the message string:
	"~C=Foregroundcolor:Backgroundcolor~" = To change the color of the text.
	"~ORG~" = To change text back to original colors.  (Optional)
	
	Use PowerShell colors.  There is one color code called 'org' that means keep the original color.
.PARAMETER Indent
    Number of space to indent the string.  Will indent everywhere there is a newline.
.EXAMPLE
	Display a mix color message.  Like Linux bootup screen showing device status in color.
	PS> Write-MixColorsHost "(~C=Red:Black~ Error ~ORG~)  USB failed to load" 
.EXAMPLE
	Display text in normal color and then change to Red with Black text to end of message.
	PS> Write-MixColorsHost "Remote system OK?  ~C=Red:Black~Darkstar down!" 
.EXAMPLE
	Display text in colors
	PS> Write-MixColorsHost "Color test: ~C=Red:org~'Red with orginal background color'~ORG~  ~C=White:Red~'White with red'~ORG~ Back to orginal colors." 
.EXAMPLE
    (Using Pipeline) Pipe color coded string.
    "(~C=White:Red~Test_1~Org~) (~C=Green:Black~Test_2~Org~)" | Write-MixColorsHost
.EXAMPLE
    (Using Pipeline) Pipe color coded string to Write-MixColorsHost and then pipe that to string without color codes.  Example for writing to log file.
    "(~C=White:Red~Test_1~Org~) (~C=Green:Black~Test_2~Org~)" | Write-MixColorsHost | Out-String
.NOTES
	--- PowerShell colors ---
	Black,Blue,Cyan,DarkBlue,DarkCyan,DarkGray,DarkGreen,DarkMagenta
	DarkRed,DarkYellow,Gray,Green,Magenta,Red,White,Yellow
	
	Author     : Mark Hubers   mark.hubers@hubers-lab.com
	Version    : 1.0  July-21-2013
#>
function Write-MixColorsHost {
	[cmdletbinding()]
	Param(
        [Parameter(Position=0,ValueFromPipeline=$true)] [string] $Message ='',
		[Parameter(Position=1)] [ValidateRange(0,80)]   [Int16]  $Indent = 0
	)


	Process {
        ### Get the original screen color and save them.
        $OrgBackgroundcolor = $Host.UI.RawUI.BackgroundColor
        $OrgForegroundcolor = $Host.UI.RawUI.ForegroundColor
		
		### Deal with indent 
        if ($Indent -gt 0) {
			[string] $Indentstr = " " * $Indent
			### Add indent to start of message
			$Message = "{0}{1}" -f $Indentstr,$Message 
			### Add indent for each newline if any exists
			$Message = [regex]::Replace($Message, "`n", "`n$Indentstr")
		} 

		### Do we have color tokens in the message? If not s
		if ( $Message -match "~C=(\w+):(\w+)~" ) {
			### Dealing with color tokens output.
			$consoleMeg = $Message
			$consoleMeg = "Write-Host -NoNewline `"$consoleMeg`"; Write-Host `"`""
			$consoleMeg = [regex]::Replace($consoleMeg, "~C=org:", "~C=$($OrgForegroundcolor):", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
			$consoleMeg = [regex]::Replace($consoleMeg, ":org~", ":$($OrgBackgroundcolor)~", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
			$consoleMeg = [regex]::Replace($consoleMeg, "~C=(\w+):(\w+)~", '"; Write-Host -NoNewline -ForegroundColor $1 -backgroundcolor $2 "')
			$consoleMeg = [regex]::Replace($consoleMeg, "~ORG~", "`"; Write-Host -NoNewline -ForegroundColor $OrgForegroundcolor -backgroundcolor $OrgBackgroundcolor `"", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
			$consoleMeg -split ";" | foreach { Invoke-Expression $($_)	}
		} else {
			### No color tokens so deal as a normal string.
			Write-host $Message
		}
		
		### If using in a pipeline and that it followed by others pipes then clean up the string value without color code.
		if ( $PSCmdlet.MyInvocation.PipelinePosition -lt $PSCmdlet.MyInvocation.PipelineLength ) {
			### String without color code.  To pass down the pipe.  Useful for writing to a file.
			$WithoutColorCodeMsg = [regex]::Replace($Message, "~C=\w+:\w+~", '', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
			$WithoutColorCodeMsg = [regex]::Replace($WithoutColorCodeMsg, "~ORG~", '', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
			return $WithoutColorCodeMsg
		}
	}
}

#
# Script from SVN Utility
# ~~~~~~~~~~~~~~~~~~~~~~~
# This script processes template files and produces and output file.
# Its a simple macro processor really.
# We use it to extract the latest version of our database procedurrads and functions
# from our source code control server to create deployment scripts.
#
# This will assume you have svn command line client in your path.
# This currently cannot authenticate with svn to retrieve data. So just simple svn: supported.
# This is written and tested with Microsoft Windows Powershell v1.0.
#
# When run it will look for all files with ".dro" extension in the current
# directory and process them. If the ".dro" file does not specify the 
# OuputFile directive then the output file will have the same name as the
# input file with ".dro" replaced by ".out"
#
# GETTING STARTED
# ~~~~~~~~~~~~~~~
# Go to a directory containing a .dro file and execute "ScriptSVN.ps1" It will process all .dro files it finds.
# Look at $exampleInputFile below to see a sample input file content.
#
# This example will fail to get this example to work you will need
#	1. SVN Server called sccserver.
#   2. Files under the following path on SVN server
#		svn://sccserver/trunk/database/maindb/Procedure/ProcedureA.sql
#		svn://sccserver/trunk/database/maindb/Procedure/ProcedureB.sql
#		svn://sccserver/trunk/database/maindb/Procedure/ProcedureD.sql
#	3. The ProcedureD file must have a revision 43 available.
#
# File Format SYNTAX
# ~~~~~~~~~~~~~~~~~~
# 1.	'#' marks start of script comment
#		Comments characters are converted to $comment on output to match output format.
#		Currently understands Single Quote strings and will mostly not identify a # in a string as a comment.
# 2.	'{' '}' mark start and end of a script directive.
#		Only recognised if the '{' is first non white space on a line. [simplifies search match a lot]
#		Only recognised if both start and end on same line.
#		The result of the directive is output to the file.
#		The output result is bracketed before and after by comments identifying the directive and parameters.
#		White space preceding a directive is prepended to each line output from directive [maintains indenting].
#		Extra data following a directive is completely ignored at the moment. 
# 3.	Other lines are output as they are
#
# A directive may have parameters.
# Directive parameters must use double quotes to quote things with spaces.
# For simplicity will always end up with a newline as last char in file.
# Simple understanding of single quoted strings wont find comment characters inside single quoted strings.
# Single quoted strings are supported because this was primarilly setup for SQL rollout scripts.
# Double quoted strings are not supported anywhere but inside directives.
#
# DIRECTIVES
# ~~~~~~~~~~
# OutputFile
#	set the name of file to write output.
#	No lines that produce output in file must precede the line its on [so make it first]
#	Or only after SourceControl line.
# SourceControl
#	Set the source control access string base path.
#	Must have trailing slash [ no it does not check it has it ]
#	eg.  svn://scc/project/trunk/Database/DBName/ for DBName procedures
# Reference
#	Extract a file from SourceControl with given path. eg. path  "Procedures/spnEmailMessageInsert.sql"
#	First parameter is path to file to fetch from source control.
#	Second parameter is an optional revision to retrieve of that file
#	Third paremter is an optional string to output to file as well [not sure how useful this is]
#		Inside this third parameter the string is processed for some special characters
#		"\n" represents a new line. useful for "GO\n".
#		"\t" represents a tab.
#		The conversion only occurs for output data not for the trace data output to file.
#
# Example. Build.cmd file that converts the .dro file(s) into our file
#	"powershell C:\Scripts\rollscript.ps1"
#
# HISTORY
# 2008/12/11 rluiten	Created.
# 2008/12/15 rluiten	Setup a v3.2 folder to test and fixed a bug or three.
#						Useful now maybe.
# 2008/12/17 rluiten	Added explicit revision retrieval to Reference.
#						Reference now looks up the revision to be able to output to file.
# 2009/02/23 rluiten	Corrected end of line outputs to CRLF.
#
# SOME EXTRA NOTES
# ~~~~~~~~~~~~~~~~
# We export our procedures and functions as a unit that drop themseles if they exist
# create themselves and then set permissions. This is the functional block of code we manage
# and track in our source code control server. This allows us to export the code from SQL again
# with another small script and do a file comparison to check we havnt missed a change or
# something hasnt snuck out to production without being in source control.
#
# Dont put identation in front of a {Reference} directive to a procedure as it will add indenting
# to the start of every line and your exported code if you wish to diff your database back to
# your source code control server will cause every line to be different.
#
# This utility is general and could be used for other stuff than SQL.
# However the single quote processing of strings not inside directives may limit some scenarios.
# This is the first script I have written so probably lots of things I can do better.
# Happy to have feedback.
# Hope someone finds this useful saves us here a lot of time keeping our deployment scripts
# correct as we work.
#
$exampleInputFile = @"
{SourceControl "svn://sccserver/trunk/database/maindb/"}
{OutputFile "Test2.sql"}
#{hello world}

{Reference "Procedure/ProcedureA.sql" }
{Reference "Procedure/ProcedureB.sql" "" "print 'dont forget to do job 222'\n"}
#{Reference "Procedure/ProcedureC.sql" } -- commented out for now
{Reference "Procedure/ProcedureD.sql" "43"}	-- extract specific revision file

select 'This is a test'
select 'What a nice day.'
	#{Me to}
# not here
-- Zzzz ' this and # that '  # and here
-- Aaaa# ' foiousf ds'  # and here
-- Bbbb # ' foiousf ds  # and here
--select 'Yyyy'
"@

$commentStart = "#"
$comment = "--"
$version = "3"

# directives must be first non white space on line and not be empty.
# doesnt matter what follows a directive
# the content of the directive will always be group 3 of regex.
# group 4 is data following directive
$matchDirective=[Regex]"^(\s*)({([^{]+)})(.*)$"

# matching only single quote strings for now - and assume a string goes from first quote on line to last quote on line.
# groups 0 whole match, 1 - before string, 2 - string, 3 - after string
$matchSingleQuoteString=[Regex]@"
^([^']*)(['].*?['])([^']*)$
"@

# returns array. 
# array 0 - prefix string to directive. [will always be whitespace]
# array 1 - directive text inside brackets
# array 2 - post fix data after directive
function split-directive([string]$str)
{
	$myMatches = $matchDirective.match($str)
	if ($myMatches.Success)
	{
		return $myMatches.Groups[1], $myMatches.Groups[3], $myMatches.Groups[4]
	}
}

# return the index of the comment character on the line. -1 if no comment on line 
function get-commentindex([string]$str)
{
	$startCommentIndex = -1
	$myMatches = $matchSingleQuoteString.match($str)

	# check for comment char before and after string in group 1 and 3.
	if ($myMatches.Success)	# found a string in our line so look around it for comments
	{
		$commentIndex = ([string]$myMatches.Groups[1]).IndexOf($commentStart)
		if ($commentIndex -gt -1)
		{	# comment in group 1
			$startCommentIndex = $myMatches.Groups[1].Index + $commentIndex
		}
		else
		{
			$commentIndex = ([string]$myMatches.Groups[3]).IndexOf($commentStart)
			if ($commentIndex -gt -1)
			{
				$startCommentIndex = $myMatches.Groups[3].Index + $commentIndex
			}
		}
	}
	else	# no string so just first index of comment
	{
		$startCommentIndex = $str.IndexOf($commentStart)
	}
	return $startCommentIndex
}

# returns array
# array 0 - non comment part of line
# array 1 - comment part of line including comment char
function split-comment([string]$str)
{
	$startCommentIndex = get-commentindex $str
	if ($startCommentIndex -gt -1)
	{
		return $str.Substring(0, $startCommentIndex), $str.Substring($startCommentIndex)
	}
	else
	{
		return $str
	}
}

## got from http://poshcode.org/496 thank you Jaykul :)
################################################################################
## Convert-Delimiter - A function to convert between different delimiters. 
## E.g.: commas to tabs, tabs to spaces, spaces to commas, etc.
################################################################################
	## Written primarily as a way of enabling the use of Import-CSV when
	## the source file was a columnar text file with data like services.txt:
	##         ip              service         port
	##         13.13.13.1      http            8000
	##         13.13.13.2      https           8001
	##         13.13.13.1      irc             6665-6669
	## 
	## Sample Use:  
	##    Get-Content services.txt | Convert-Delimiter " +" "," | Set-Content services.csv
	##         would convert the file above into something that could passed to:
	##         Import-Csv services.csv
	##
	##    Get-Content Delimited.csv | Convert-Delimiter "," "`t" | Set-Content Delimited.tab
	##         would convert a simple comma-separated-values file to a tab-delimited file
	################################################################################
	## Version History
	## Version 1.0
	##	  First working version
	## Version 2.0
	##    Fixed the quoting so it adds quotes in case they're neeeded
	## Version 2.1
	##    Remove quotes which aren't needed
	## Version 2.2
	##    Trim spaces off the ends, they confuse things
	## Version 2.3
	##    Allow empty columns: as in: there,are,six,"comma, delimited",,columns
	## Version 2.3
	##    Replaced Trim() with regex to do similar job.
	##    if a parameter is "" <-- empty string this captures the "Quotes" as its value not empty string ???
Function Convert-Delimiter([regex]$from,[string]$to) 
{
   begin
   {
	  $z = [char](222)
   }
   process
   {
	  #$_ = $_.Trim()	# converted Trim into regex replace as powershell 1 does not have it ?
	  $_ = $_ -replace "^\s+", "" -replace "\s+$", ""
	  $_ = $_ -replace "(?:`"((?:(?:[^`"]|`"`"))+)(?:`"$from|`"`$))|(?:$from)|(?:((?:.(?!$from))*.)(?:$from|`$))","$z`$1`$2$z$to"
	  $_ = $_ -replace "$z(?:$to|$z)?`$","$z"
	  $_ = $_ -replace "`"`"","`"" -replace "`"","`"`"" 
	  $_ = $_ -replace "$z((?:[^$z`"](?!$to))+)$z($to|`$)","`$1`$2"
	  $_ = $_ -replace "$z","`"" -replace "$z","`""
	  $_
   }
}

# Use source code control client [svn] to retrieve referenced file.
Function get-reference([string]$scc, [string]$filePath, [string]$rev, [string]$post, [string]$whiteSpacePre)
{
	$svn = 'svn.exe'

	if ($rev -eq $null -or $rev -eq "")
	{
		# figure out the revision of head if we dont have it.
		$result = @(& $svn info $scc$filePath)	# ensure its an array even if only one
		$revResult = @($result -like "Revision: *")
		if ($revResult.Length -eq 1)
		{
			$tmp = $revResult[0]
			$regexRevision = [regex]"^Revision: (\d+)$"
			$myMatches = $regexRevision.match($tmp)
			if ($myMatches.Success)
			{
				$rev = $myMatches.Groups[1]
			}
		}
		else
		{
			write-error "Cannot find revision for $scc$filePath."
			exit
		}
	}
	
	# example of svn 'svn -r 1234 cat svn://scc/project/trunk/database/DBName/Procedure/procedure.sql'
	write-host "Reference [$rev] $filePath"
	#write-host "$svn -r $rev cat $scc$filePath"
	$result = & $svn -r $rev cat $scc$filePath
	 
	# prefix each line
	for ($i = 0; $i -lt $result.Length; $i++)
	{
		$result[$i] =  $whiteSpacePre + $result[$i]
	}
	
	$fileContent = [string]::join("`r`n", $result)
	
	append-outputString "$comment ** Start Reference [$scc] [$filePath] [$rev] [$post]`r`n"; 
	append-outputString "$fileContent`r`n"				# additional newline after data
	if ($post -ne $null -and $post -ne "")
	{
		$convertedPost = $post -replace "\\n", "`r`n"  -replace "\\t", "`t"
		append-outputString $convertedPost
	}
	append-outputString "$comment ** End Reference [$scc] [$filePath] [$rev] [$post]`r`n"; 
}

# procedures to wrap up global string buffer for processed output.
function init-outputString()
{
	$global:outputString = ""
	$global:sourceControl = ""
	$global:outputFile = ""
}
function append-outputString([string]$str)
{
	$global:outputString += $str
}
function write-outputString([string]$file)
{
	write-output $global:outputString | out-file -filePath $file -encoding oem
}

function execute-directive($splitDirective, [string]$whiteSpacePre)
{
	$keyword = $splitDirective[0]
	switch ($keyword)
	{
		"SourceControl"
		{
			write-host  "$comment $keyword `"$($splitDirective[1])`""
			append-outputString "$whiteSpacePre$comment $keyword `"$($splitDirective[1])`""
			$global:sourceControl = $splitDirective[1]
		}
		"OutputFile"	
		{
			append-outputString "$whiteSpacePre$comment $keyword `"$($splitDirective[1])`""
			$global:outputFile = $splitDirective[1]
		}
		"Reference"
		{
			get-reference $global:sourceControl $splitDirective[1] $splitDirective[2] $splitDirective[3] $whiteSpacePre
		}
		default
		{
			write-error "Unknown directive `"$keyword`" exiting..."
			exit
		}
	}
}

function process-directive([string]$directive, [string]$whiteSpacePre)
{
	$reDelimit = $directive | Convert-Delimiter " " "!"
	$splitDirective = $reDelimit.Split("!")
	
	for ($i = 0; $i -lt $splitDirective.Length; $i++)
	{
		$tmp = $splitDirective[$i]
		if ($tmp -eq "`"`"`"`"")		# convert """" to empty string -- side effect of Convert-Delimiter
		{
			$splitDirective[$i] = "";		# empty string
		}
	}
	execute-directive $splitDirective $whiteSpacePre
}

function process-file([string]$inputFile, [string]$outputFile)
{
	init-outputString
	$global:outputFile = $outputFile
	
	if (!(test-path -pathType Leaf $inputFile))
	{
		write-error "Cannot open input file `"$inputFile`""
		exit
	}
	
	$outmsg = "$comment ScriptSVN $version processing file `"$inputFile`""
	write-host $outmsg
	append-outputString "$outmsg`r`n"
	
	$inputLines = @(get-content -path $inputFile)	# read file @ to ensure we get an array
	foreach ($line in $inputLines)
	{
		$activeStr, $commentStr = split-comment $line
		$whiteSpacePre, $directive, $poststr = split-directive $activeStr
		if ($directive -eq $null -or $directive.Length -eq 0)
		{
			append-outputString "$activeStr"	# no directive to just output the line
		}
		else
		{
			process-directive $directive $whiteSpacePre
		}
	
		# output comment
		if ($commentStr.Length -gt 0)
		{
			# convert input comment format to output format
			$afterComment = $commentStr.Substring($commentStart.Length)
			append-outputString "$comment$afterComment`r`n"
		}
		else
		{
			append-outputString "`r`n" # just new line
		}
	}
	write-host  "$comment OutputFile `"$($global:outputFile)`""
	write-outputString $global:outputFile 
}

# by default process all file ending in file extension in current directory
$files = @(get-childitem "*.dro")

if ($files.Length -eq 0)
{
	write-host "No files found for processing."
	write-host "This utility processes files ending in `".dro`" "
}

foreach ($f in $files)
{
	$outFile = $f -replace ".dro",".out"
	process-file $f $outFile
}


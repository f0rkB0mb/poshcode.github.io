#########################################################
## Set-DfsnForDR - v5.1 (September 2014)               ##
## =================================================== ##
## CAVEAT UTILITOR!                                    ##
## This program comes with no warranty and no support! ##
#########################################################

$title             = "Set-DfsnForDR - v5.1 (September 2014)" # TITLE
$workingPath       = $env:USERPROFILE                        # The users profile (where we expect the optional Set-DfsnForDR.ini to be)
$domainServersFile = $workingPath + "\Set-DfsnForDR.ini"     # This is the default file name and location for the DomainServersFile
$backupPath        = $workingPath + "\DFSN_BACKUP"           # The default backup folder (where namespace backups go)

#############################
# Generic Display Functions #
#############################

Function Pad-R{                                  # Function Pad-R
	Param([string]$string,[int]$int)             # Takes in a -string $string, and -int $int
	$string.PadRight($int," ").SubString(0,$int) # Pads it right to $padR with " " and cuts it down to size if it was too big to start with	
}                                                # END of function Pad-R

Function Columnize{                                                                # Function Columnize
	$i = 0                                                                         # Initialize counter $i = 0
	while($i -lt $args.count){                                                     # While $i is less than the count of arguments
        Write-Host ((Pad-R $args[$i] $args[$i+1]) + " ") -F $args[$i+2] -NoNewline # Write to screen $args[i] adjusted to size $args[i], " ", and in color $args[$i+2], with no new line after
        $i += 3                                                                    # Accumulate count by 3 (since have sets of three arguments)
    }                                                                              # END of while $i < count of arguments
	Write-Host                                                                     # Starts a new line for the next row
}                                                                                  # END of Columnize

Function Wr-E{Write-Host}                                 # Writes a Carriage Return (Enter)
Function Wr-C{Write-Host ($args[0]) -F Cyan}              # Writes supplied argument text in Cyan
Function Wr-G{Write-Host ($args[0]) -F Green}             # Writes supplied argument text in Green
Function Wr-R{Write-Host ($args[0]) -F Red}               # Writes supplied argument text in Red
Function Wr-W{Write-Host ($args[0]) -F White}             # Writes supplied argument text in White
Function Wr-Y{Write-Host ($args[0]) -F Yellow}            # Writes supplied argument text in Yellow
Function Wn-C{Write-Host ($args[0]) -F Cyan -NoNewline}   # Writes supplied argument text in Cyan (no new line after)
Function Wn-G{Write-Host ($args[0]) -F Green -NoNewline}  # Writes supplied argument text in Green (no new line after)
Function Wn-R{Write-Host ($args[0]) -F Red -NoNewline}    # Writes supplied argument text in Red (no new line after)
Function Wn-W{Write-Host ($args[0]) -F White -NoNewline}  # Writes supplied argument text in White (no new line after)
Function Wn-Y{Write-Host ($args[0]) -F Yellow -NoNewline} # Writes supplied argument text in Yellow (no new line after)
Function Rd-W{                                            # Read from host in White (because default isn't)
    If($args){Write-Host ($args[0]) -F White -NoNewline}  # If supplied $args then write to the screen $args[0] first with NoNewLine
    return (Read-Host "?")}                               # Then prompt!

Function Prompt-Keys{ # ------------------------------------------------------- # This expects key presses so the args should all be only one character long!
	Param([switch]$anykey,[switch]$echo)                                        # Allows any key to be pressed / Allows the key to be echoed to screen
	If(!$anykey -and !$args[0]){return $false}                                  # No args when not using the -anykey is not a valid option
	If($args[0]){                                                               # Might have no $args[0] if using the -anykey option
		If($args[0].count -ne 1){$answers = $args[0]}                           # If the 1st argument - $args[0] - is an array, use this for the list of possible answers
		else{$answers  = $args[0..(($args.count)-1)]}                           # Otherwise, take all the other arguments for the list of possible answers
	}                                                                           # END of If ($args[0]
	while($true){                                                               # Infinite loop! Escape via valid keypress or anykey if -anykey set!
		If ($echo){$keyPress = $host.UI.RawUI.ReadKey("IncludeKeyDown")}        # The Key Press (ECHO allowed)
		else      {$keyPress = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")} # The Key Press (no ECHO)
		If($anyKey -and !$args[0]){return $true}                                # If $anyKey and no $args[0] we an return now
		$keyPress = $keyPress.character.ToString().ToUpper()                    # Compare in upper case (and return in upper case)
		foreach($answer in $answers){                                           # Loop through the answers
			if($keyPress -eq $answer.ToUpper()){return $keyPress}               # Check if the answer to the prompt equals a valid answer, and if so then return
		}                                                                       # END of foreach $answers
		If($anyKey){return $true}                                               # If -anykey don't loop
	}                                                                           # END of while $true
} # --------------------------------------------------------------------------- # END of Prompt-Keys
	
Function Set-Window{ # ---------------------------------------------------------- # Set-Window
	Param([string]$textcolor,[string]$background,[string]$title,[int]$percentMax) # -textcolor COLOR -background COLOR -title TITLE -percentMax %MAX_of_SCREEN_SIZE
	$window = (get-host).UI.RawUI                                                 # Gets the current Window properties
	If($textcolor)      {$window.ForegroundColor = $textcolor}                    # If $textcolor parameter, sets the textcolor
	If($background -and ($window.BackgroundColor -ne $background)){               # If $background parameters and it's not equal to what it is set to already
        $window.BackgroundColor = $background;cls}                                # ... set the background and do a CLS
	If($title)          {$window.WindowTitle = $title}                            # Set's the Window Title!
	$buffer            = $window.BufferSize                                       # Gets buffersize
	$buffer.Height     = 9999                                                     # ... set maximum buffer hit
	$window.BufferSize = $buffer                                                  # ... apply
	If($perCentMax){                                                              # If $perCentMax parameter
		$maxX = [int](($window.MaxPhysicalWindowSize.Width)*$percentMax/100)      # ... find our new X size
		$maxY = [int](($window.MaxPhysicalWindowSize.Height)*$percentMax/100)     # ... find our new Y size
		$buffer.Width = $maxX                                                     # ... buffer = maxX
		$window.BufferSize = $buffer                                              # ... apply
		$size = $window.WindowSize                                                # ... get WindowSize
		$size.Width = $maxX                                                       # ... set maxX
		$size.Height = $maxY                                                      # ... set maxY
		$window.WindowSize = $size                                                # ... apply
	}                                                                             # END of $perCentMax
} # ----------------------------------------------------------------------------- # END of Set-Window

##################
# CORE FUNCTIONS #
##################

Function Check-OSVersion{ # ----------------------------- # Checks the OS Version of the machine the script is running on
	Param([int]$major,[int]$minor)                        # INPUT = -major MAJORVERSION -minor MINORVERSION (e.g 2008R2 is 6 1)
	$currentOS = [System.Environment]::OSVersion.Version  # Get the current OSVersion
	if     ($currentOS.major -lt $major){return $null}    # Current major version less than required major version    - return FALSE
	elseif ($currentOS.major -gt $major){return $true}    # Current major version greater than required major version - return TRUE
	elseif ($currentOS.minor -lt $minor){return $null}    # Current minor version less than required minor version    - return FALSE
	else                                {return $true}}   # Current minor version greater than or equal to the minor  - return TRUE

Function Got-DFSUtil{ # ------------ # Tests if have access to DFSUtil
	Wr-E; $testDfsUtil = dfsutil.exe # This will output a big red error to screen if it fails and leave $testDfsUtil as $null
	return $testDfsUtil}             # Return $testDfsUtil (either it's $null or has something in)
	
Function Create-Folder { # ------------------------------------------------------- # INPUT = The folder or path to a folder for a new folder
	If(!$args[0]){ return $null }                                                  # If no/null argument supplied, return NULL
	If(Test-Path $args[0] -ErrorAction SilentlyContinue){ return ($args[0]) }      # If it already exists, it returns back the name of the folder
	Else {[Void](New-item $args[0] -type directory -ErrorAction SilentlyContinue)} # Otherwise try and create it
	If(Test-Path $args[0] -ErrorAction SilentlyContinue){ return ($args[0]) }      # If folder now exists, return back the name of the folder
	Else { return $null }                                                          # Otherwise return NULL
} # ------------------------------------------------------------------------------ # END Create-Folder

Function Prompt-ForDomainServersFile{                                           # Takes no input
    Wr-W "This program allows loading of a file with:"                          # Display to screen
    Wr-W "Line 1 = A domain name for Domain-based Namespaces"                   # Display to screen
    Wr-W "Line 2 = A comma separated list of servers for Standalone Namespaces" # Display to screen
    Wr-W "The file contents are not checked for validity.";Wr-E                 # Display to screen
    $readIn = Rd-W "Enter filepath";Wr-E                                        # Read input
    return $readIn                                                              # Return what was read
}                                                                               # END of Prompt-ForDomainServersFile

Function Prompt-ForDomain{                                               # Function takes no input
    $readIn = Rd-W "Enter domain name";Wr-E                              # Read in the domain name
    $getDFSUtil = Get-DFSUtil -Domain $readIn                            # Run Get-DFSUtil -Domain on the domain
    If(!$getDFSUtil){                                                    # If was unsuccessful
        Wr-R "Unsuccessful querying domain $readIn for namespaces.";Wr-E # ... says it was unsuccessful
        return $false                                                    # return FALSE
    }                                                                    #
    Wr-W ">>>>>>> List of Namespaces in $readIn";Wr-E                    # Display the list of Namespaces
    $getDFSUtil | foreach {Wr-W $_};Wr-E                                 # Cycles through the Get-DFSUtil output
    return $readIn                                                       # return the domain name given in the prompt
}                                                                        # END of Prompt-ForDomain

Function Prompt-ForServer{                                                   # Function takes no input
    $readIn = Rd-W "Enter server name (or servers separated by commas)";Wr-E # Read in the server name(s)
    $split = $readIn.Split(",")                                              # We allow comma separated servers, so split by this
    foreach ($server in $split) {                                            # Cycle through the comma seperated list (or just a list of one)
        $getDFSUtil = Get-DFSUtil -Server $server                            # Run Get-DFSUtil -Server on the server
        If(!$getDFSUtil){                                                    # If was unsuccessful
            Wr-R "Unsuccessful querying server $server for namespaces.";Wr-E # ... say it was unsuccessful
            return $false                                                    # return FALSE
        }                                                                    #
        Wr-W ">>>>>>> List of Namespaces on $server";Wr-E                    # Display the list of Namespaces
        $getDFSUtil | foreach {Wr-W $_};Wr-E                                 # Cycles through the Get-DFSUtil output
    }                                                                        # END of cycling through servers
    return $readIn                                                           # return the server name(s) given in the prompt
}                                                                            # END of Prompt-ForServer

Function Display-Namespaces{ # -------------------------- # Takes domain and/or server(s) as input
    Param($domain,$server)                                # Define the parameters
    $listNamespaces = @()                                 # Define an array for the list of namespaces
    If($domain){                                          # If supplied a domain name
        Wr-W ">>>>>>> List of Namespaces in $domain";Wr-E # A heading
        $list = Get-DFSUtil -Domain $domain               # Get the list of name spaces in the domain
        foreach($item in $list){                          # FOR $list
            $namespace = "\\" + $domain + "\" + $item     # Format Namespaces for domain
            $listNamespaces += $namespace                 # Add to $listNamespaces
            Wr-W $namespace                               # Display the namespaces
        }                                                 # END $list
        Wr-E                                              # 
    }                                                     # END of if $domain
    If($server){                                          # If supplied server(s)
        $split = $server.Split(",")                       # We allow comma separated servers, so split by this
        $split | foreach {                                # For each item (or just one)
            Wr-W ">>>>>>> List of Namespaces on $_";Wr-E  # A heading
            $list = Get-DFSUtil -Server $_                # Get the list of name spaces in the standalone namespace
            foreach($item in $list){                      # FOR $list
                $namespace = "\" + $item                  # Standalone namespaces just need a "\" on the front of "\COMPUTER"
                $listNamespaces += $namespace             # Add to $listNamespaces
                Wr-W $namespace                           # Display the namespaces
            }                                             # END $list
            Wr-E                                          #
        }                                                 # END of $split for loop
    }                                                     # END of if $server
    , $listNamespaces                                     # Return the list of Namespaces
} # ----------------------------------------------------- # END of Display-Namespaces

Function Get-DFSUtil {                                             # Expected parameters: -Domain OR -Server
	Param([string]$Domain,[string]$Server)                         # Define parameters -Domain and -Server
	If($Domain){$dfsutilOut = dfsutil domain $Domain}              # Run> dfsutil domain DOMAINNAME
	If($Server){$dfsutilOut = dfsutil server $Server}              # Run> dfsutil server SERVERNAME
    If(!$dfsutilOut){return $false}                                # If no results, return FALSE
    If($dfsutilOut[0].contains("Could not complete the command")){ # dfsutil failed
        return $false                                              # return FALSE
    }                                                              # END of if "Could not complete"
	$dfsNameSpaces = @()                                           # Initialize the array $dfsNameSpaces
	Foreach ($line in $dfsutilOut) {                               # Cycle through the lines in the supplied (as 1st argument) array
		$line = $line.Trim()                                       # Trim spaces from ends of line!
		$tmp  = $line.ToLower()                                    # $tmp (TeMPorary) is $line in lowercase (makes matching easier)
		If(($tmp -eq "") -or                                       # not interested in blank lines
		   ($tmp.StartsWith("roots on")) -or                       # not interested in this line
		   ($tmp.StartsWith("done with")) -or                      # not interested in this line
		   ($tmp.StartsWith("done processing"))){}                 # not interested in this line {do nothing...}
		else {$dfsNameSpaces += $line}                             # Construct $dfsNameSpaces
	}                                                              # END of Foreach in $args[0]
	, $dfsNameSpaces                                               # Return $dfsNameSpaces
}                                                                  # END of Function Get-DFSUtil

Function Prompt-ForNamespace { # ----------------------------------------- # Input is the list of namespaces from MAIN ($gotNameSpaces)
    Param($namespaces)                                                     # Define parameter $namespaces
    Wr-W ">>>>>>> List of Namespaces";Wr-E                                 # A heading
    $namespaces | foreach {Wr-W $_};Wr-E                                   # Write to screen all the namespaces
    $choice = Rd-W "Enter namespace";Wr-E                                  # Prompt for the namespace
    If(!$choice){return "ALL"}                                             # If user presses enter, return ALL
    ## Note: We cannot use -match for the matching because regex is confused by \ ##
    foreach ($namespace in $namespaces) {                                  # START: Cycle through $namespaces
        If ( $namespace.ToUpper() -eq $choice.ToUpper() ) {return $choice} # If a match of the $choice in the $namespaces, return $choice ...
    }                                                                      # END  : Cycle through $namespaces
    Wr-R "Unable to match $choice from the list of namespaces!"            # ... no match and say so
    Wr-E; return "ALL"                                                     # ... and return "ALL"
} # ---------------------------------------------------------------------- # END Prompt-ForNamespace

Function Backup-Namespaces { # --------------------------- # Backs up namespaces and returns an array with the filename(s) in
    Param($domain,$server,$namespace,$path)                # Parameters -domain and/or -server, with -path
    Wn-W "Namespaces being backed up to "; Wr-C $path;Wr-E # Display
    $filenames = @()                                       # Initialize $filenames array
    $date = Get-Date -uformat "%Y%m%d%H%M"                 # Get the date
    If($namespace -ne "ALL"){ # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ # If have the $namespace parameter (but not for ALL)
        $split = $namespace.Split("\")                                                      # We have \\SERVER or DOMAIN\NAMESPACE - [0] \ [1] \ [2] \ [3]
        $filename = $path + "\" + $split[2] + "." + $split[3] + "." + $date + ".dfsnbackup" # Create filename
        [Void](Get-DFSUtilRootExport $namespace $filename)                                  # Run Get-DFSUtilRootExport
        Wn-G "$namespace"; Wn-W " backed up to "; Wr-C "$filename"; Wr-E                    # write to screen
        return $filename                                                                    # Return just one filename (since chosen to do 1 specific namespace)
    } # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ # END of $namespace (NOTE: $namespace is overwritten later in this FN)
    If($domain){ # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ # If DOMAIN
        $list = Get-DFSUtil -Domain $domain                                               # Get the list of namespaces
        foreach($item in $list){                                                          # cycle the list
            $filename = $path + "\" + $domain + "." + $item + "." + $date + ".dfsnbackup" # create filename
            $namespace = "\\" + $domain + "\" + $item                                     # format namespace for dfsutil
            [Void](Get-DFSUtilRootExport $namespace $filename)                            # Run Get-DFSUtilRootExport
            $filenames += $filename                                                       # accumulate filenames
            Wn-G "$namespace"; Wn-W " backed up to "; Wr-C "$filename"                    # write to screen
        }                                                                                 # END of $list
    } # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ # END of if DOMAIN
    If($server){ # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ # If SERVER(s)
        $elements = $server.Split(",")                                                             # We allow comma separated servers, so split by this
        foreach($element in $elements){                                                            # For each item (or just one)
            $list = Get-DFSUtil -Server $element                                                   # Get the list of namespaces
            foreach($item in $list){                                                               # cycle the list
                $split = $item.Split("\")                                                          # Server items are \SERVER\NAMESPACE so we split them ([0] \ [1] SERVER \ [2] NAMESPACE)
                $filename = $path + "\" + $element + "." + $split[2] + "." + $date + ".dfsnbackup" # create filename
                $item = "\" + $item                                                                # format namespace for dfsutil
                [Void](Get-DFSUtilRootExport $item $filename)                                      # Run Get-DFSUtilRootExport
                $filenames += $filename                                                            # accumulate filenames
                Wn-G "$item"; Wn-W " backed up to "; Wr-C "$filename"                              # write to screen
            }                                                                                      # END of $list
        }                                                                                          # END of $split for loop
    };Wr-E # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ # END of SERVER
	, $filenames # Return $filenames
} # ------------ # END of Backup-Namespaces

Function Get-DFSUtilRootExport {                            # Expected parameters: -Namespace AND -Backup
    Param([string]$Namespace,[string]$Backup)               # Define parameters -Namespace and -Backup
    $dfsutilout = dfsutil root export $Namespace $Backup    # Get the DFS Namespace information and write to $Backup
    $tmp = $dfsutilout[1].ToString().ToLower()              # $tmp (TeMPorary) is $dfsutilout in lowercase (makes matching easier)
    If($tmp.Contains("done processing this")){return $true} # Means successfully done a dfsutil root export
    $false                                                  # ... otherwise it failed!
}                                                           # END of Function Get0DFSUtilRootExport

Function Display-TableOfLinks{ # ---------------------------------------------------------------------- # START of Display-TableOfLinks
    Param($backupFiles)                                                                                 # Define param -backupfiles
	If(!$global:tableOfLinks){                                                                          # (v5.1) If $global:tableOfLinks is NULL
		[Void](Build-ArrayOfLinks $backupFiles)                                                         # ... build array of links
		$global:ToLcount = $global:tableOfLinks.count}                                                  # ... and count rows in the array (global)
    $r = 0;$x1 = 45;$x2 = 45;$x3 = 9;$x4 = 15                                                           # Initialize row accumulator r=0 and column widths for the table
   	Columnize "Namespace Link" $x1 White "Target" $x2 White "State" $x3 White "PriorityClass" $x4 White # Column Headings
	Columnize "--------------" $x1 White "------" $x2 White "-----" $x3 White "-------------" $x4 White # ... underlined
    while ($r -lt $global:ToLcount){                                                                    # While the row count is less than the number of rows (of 4) we have in the array
        Columnize ($global:tableOfLinks[$r]) $x1 White ($global:tableOfLinks[$r+1]) $x2 White ($global:tableOfLinks[$r+2]) $x3 White ($global:tableOfLinks[$r+3]) $x4 White
        $r += 4                                                                                         # Accumulate the array by 4 for the next row
    }                                                                                                   # END of while $r -lt $rows
    Wr-E                                                                                                # Write to screen a carriage return
} # --------------------------------------------------------------------------------------------------- # END of FN (AKA - Display-DFSUtilRootExportTable modified)

Function Build-ArrayOfLinks{ # --------------------------------------------------------- # Cycles through all the backup files building the array of links
    Param($backupFiles)                                                                  # Define param -backupfiles
	$fileCount = $backupFiles.Count                                                      # A count of backup files
	$onFileNum = 1                                                                       # Initialize "On File Number" = 0 
    foreach ($file in $backupFiles){                                                     # Cycle through backup files
		Wn-W ("Reading backup file " + $onFileNum + "/" + $fileCount + " - ");Wn-C $file # (v5.1) Display progress	
		[Void](Get-DFSUtilRootExportTable $file)                                         # (v5.1) Get-DFSUtilRootExportTable updates $global:tableOfLinks!
		$onFileNum ++                                                                    # Accumulate number of file we're on (progress display)
    }                                                                                    # END of $backupFiles
	Wr-E                                                                                 # 
} # ------------------------------------------------------------------------------------ # END of Build-ArrayOfLinks

Function Get-DFSUtilRootExportTable { # ---------------------------------- # Expected parameter: -Filename
	# INPUT = $Filename of a DFSUTIL ROOT EXPORT file!                     #
	# OUTPUT = NONE! (Updates $global:tableOfLinks)                        #
	# USED BY = Function Build-ArrayOfLinks                                #
    Param([string]$Filename)                                               # Define parameter -Filename
    $tmp = Test-Path $Filename                                             # Test for $filename
    If(!$tmp){Wr-R "Filename $Filename not found!";return $null}           # Return NULL and display a warning if $filename not found
    $contents = Get-Content -Path $Filename                                # Get the contents of $Filename
    If(!$contents){Wr-R "Filename $Filename has no content!";return $null} # Return NULL and display a warning if no content
    $recording = $false                                                    # Variable turns on/off recording from the file
	If (!$global:tableOfLinks){$global:tableOfLinks = @()}                 # (v5.1) A check that $global:tableOfLinks is not null, and if it is, to initialize as an array
	$split = $Filename.split("\")                                          # (v5.1) We record full back to backup file and 
    $split = $split[($split.count)-1]                                      # (v5.1) ... just want the end bit (the file name)
    $split = $split.Split(".")                                             # (v5.1) Split backup file name on "."
    $namespacePrefix = "\\" + $split[0] + "\" + $split[1] +"\"             # (v5.1) The (DEFAULT) filename is DOMAIN/COMPUTER[0].NAMESPACE[1]
    Foreach ($line in $contents){                                          # Go through all the lines in $contents
		Wn-C "."                                                           # (v5.1) Display progress 
        $tmp = $line.ToLower()                                             # $tmp (TeMPorary) is $line in lowercase (makes matching easier)  
        If($tmp.Contains("</link>")){$recording = $false}                  # STOP recording contents of the file with "</link>"
        If($recording){                                                    # This bit only activates if $recording for servernames
            $split = $line.Split([char]34)                                 # Split $line on Quotations
            $state = $split[1]                                             # State is [0] " [1] STATE
            $priorityClass = $split[3]                                     # Priority Class is [0] " [1] STATE " [2] " [3] PriorityClass
            $split = $line.Split(">")                                      # Split $line on >
            $split = $split[1]                                             # Take [1] ( [0] > [1] )
            $split = $split.Split("<")                                     # Split the above on <
            $target = $split[0]                                            # Target is [0] Target < [1]
			$global:tableOfLinks += $link                                  # (v5.1) Contruct array: link         
			$global:tableOfLinks += $target                                # (v5.1) Contruct array: target       
			$global:tableOfLinks += $state                                 # (v5.1) Contruct array: state        
			$global:tableOfLinks += $priorityClass                         # (v5.1) Contruct array: priorityClass
        }                                                                  # END of $recording 
        If($tmp.Contains("<link name=")){                                  # If the line contains "<link name="
            $recording = $true                                             # ... start recording from the next line
            $link = $line.Split([char]34)                                  # Split the line on "
            $link = $link[1]                                               # The link is [0] " [1] LINK "
			$link = $namespacePrefix + $link                               # (v5.1) Formats the link as a full path
			If($link.contains(".DFSFolderLink")){$recording = $false}      # FIX for condition where a DFS link has no targets and temporary link name="<LINK>\.DFSFolderLink"
        }                                                                  # END of $tmp contains "<link name ="            
    }                                                                      # END of foreach $line n $contents
	Wr-E                                                                   # (v5.1) Display progress - carriage return after the progress dots ...
} # ---------------------------------------------------------------------- # END of function Get-DFSUtilRootTable

Function Display-TargetServers{ # ---------------------- # START: Display-TargetServers
	# INPUT = NONE but uses $global:tableOfLinks
	# OUTPUT = NONE but constructs and/or displays $global:targets (hashtable with all targets in alphabetical order and how many times they've occurred!)
	If(!$global:targets){                                # If we don't already have the $global:targets hash table
		$global:targets = @{}                            # Initializes $global:targets as a hash table
		$i = 0                                           # Initialize $i = 0 (location in the table of links)
		while ($i -lt $global:ToLcount){                 # Goes through all the entries in the Table of Links
			$target = $global:tableOfLinks[$i+1]         # Because $table has 4 entries per row [0] Namespace Link [1] Target ...
			$server = $target.Split("\")[2]              # The server is ... [0] \ [1] \ [2] SERVERNAME \ [3] ...
			$count = $global:targets.Get_Item($server)   # Get count of number of links with this server (note: we don't check capitalization of server name)
			If(!$count){                                 # If no count ...
				$global:targets.Set_Item($server,1)      # ... start with a count of 1
			} else {                                     # otherwise
				$count++                                 # accumulate the counter
				$global:targets.Set_Item($server,$count) # and set the hashtable for $server with value $count
			}                                            # END of If !$count else $count
			$i += 4                                      # Accumulate $i by 4 (represents 4 entries per row in the table)
		}                                                # END of while Less Than $sizeOfLinksTable
	}                                                    # END of If !$global:targets
	$str = $global:targets.GetEnumerator() | Sort-Object -Property Name | Format-Table -Autosize | Out-String
	$str = $str.Trim()                                   # Trim carriage returns from front and end!
	Wr-W $str; Wr-E                                      # Write table to screen
} # ---------------------------------------------------- # END: Display-TargetServers

Function Prompt-ForTarget{ # -------------------------------------------------------------------------- # FN: Prompt-ForTarget
	$answer = Rd-W "Enter target FQDN/NETBIOS";Wr-E                                                     # The prompt
	If(!$answer){return $null}                                                                          # If no answer return NULL
	If(!$global:targets.get_item($answer)){                                                             # If no match
		Wr-R "$answer is not a valid target from the List of 'Servers with Targets in the Namespaces'!" # ... say no match
		Wr-E; return $null}                                                                             # And return NULL
	return $answer} # --------------------------------------------------------------------------------- # Else return $answer

########################
# Update DFS Functions #
########################

Function Update-DFSUtil{ # ------------------- # Function Update-DFSUtil
	# INPUT: $global variables:tableOfLinks,TolCount,first,last,enabled,disabled
    Param([switch]$ShowCommands,[switch]$Safe) # Define switches
   	If(!$ShowCommands){                        # Not showing table headers or any headers if -ShowCommands!
        $x1 = 45;$x2 = 45;$x3 = 9;$x4 = 15     # Column widths for tables (row output done in Update-DFSUtilProperty)
        Columnize "Namespace Link" $x1 White "Target" $x2 White "State" $x3 White "PriorityClass" $x4 White
	    Columnize "--------------" $x1 White "------" $x2 White "-----" $x3 White "-------------" $x4 White} # END !$showCommands
    # \/ This next 4 lines use Update-DFSUtilProperty to do DFSUTIL property updates for different properties \/ #
    If($global:first)   {[Void](Update-DFSUtilProperty -Match ($global:first)    -P1 "priorityclass" -P2 "set" -S1 "GlobalHigh" -Column "PriorityClass" -Display "GlobalHigh")}
    If($global:last)    {[Void](Update-DFSUtilProperty -Match ($global:last)     -P1 "priorityclass" -P2 "set" -S1 "GlobalLow"  -Column "PriorityClass" -Display "GlobalLow")}
    If($global:enabled) {[Void](Update-DFSUtilProperty -Match ($global:enabled)  -P1 "state"         -P2 "online"               -Column "State"         -Display "ONLINE")}
    If($global:disabled){[Void](Update-DFSUtilProperty -Match ($global:disabled) -P1 "state"         -P2 "offline"              -Column "State"         -Display "OFFLINE")}
	Wr-E                                       # ... blank line before the menu title
} # ------------------------------------------ # Note: (v5.1) Removed $m since we now check the target is valid on input!

Function Update-DFSUtilProperty { # ---------- # This Function is used inside Update-DFSUtil ONLY
    Param($Match,$P1,$P2,$S1,$Column,$Display) # Define parameters -Match -P1 -P2 -S1 -Column -Display
    $i = 0                                     # Initialize i as 0 (counts where we are in $arrayOfLinks FROM Update-DFSUtil)
    If ($safe -and !$ShowCommands)     {Wr-E; Wr-G "Running in safe mode, no updates will be actioned!";Wr-E}
    elseif (!$safe -and !$ShowCommands){Wr-E; Wr-C "DFSUtil property Updates being actioned!";Wr-E}
    while ($i -lt $global:ToLcount){                        # WHILE < count of $global:TableOfLinks
        $target       = $global:tableOfLinks[$i+1]          # Target is taken from $arrayOfLinks
        $targetServer = ($target.split("\"))[2]             # Because we have \\SERVER\ or [0]\[1]\[2]SERVER\
        If( $targetServer.ToLower() -eq $Match.ToLower() ){ # If we have a match (has to be a PERFECT MATCH, letter for letter, but not case sensitive)
            $namespaceLink = $global:tableOfLinks[$i]       # Get the namespace link from $arrayOfLinks
            $state         = $global:tableOfLinks[$i+2]     # Get original state from $arrayOfLinks
            $priorityClass = $global:tableOfLinks[$i+3]     # Get original priority class from $arrayOfLinks
            If($ShowCommands){                                             # IF we're just showing the commands ($showCommands from the parent function)
                Wr-C "dfsutil property $P1 $P2 $namespaceLink $target $S1" # Display the command that would get run
            } else {                                                       # ELSE (!$ShowCommands)
                If(!$safe){ # @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ # @@ ATTENTION - THE DFS UPDATE BIT @@
                    $commandOut = dfsutil property $P1 $P2 $namespaceLink $target $S1 # THIS BIT ONLY RUNS IF SAFE MODE IS NOT ENABLED!
                } # @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ # @@ END OF DFS UPDATE BIT          @@
                If($Column -eq "PriorityClass"){Columnize $namespaceLink $x1 White $target $x2 White $state $x3 White $Display $x4 Cyan}
                If($Column -eq "State"){Columnize $namespaceLink $x1 White $target $x2 White $Display $x3 Cyan $priorityClass $x4 White}
            }                # END of not showing commands
        }                    # END of if $Match
	    $i += 4              # Accumulate $i by 4 ($array of links is a 1xY array - Y is in multiples of 4)
    }                        # END of while < $count
} # ------------------------ # Note: (v5.1) Removed $recordMatches since we now checks the target is valid on input!

##################
## MAIN PROGRAM ##
##################

# Basic Checks.
If($PSIse)                {Wr-E;Wr-R "This program cannot run in PowerShell ISE. ISE does not support ReadKey!";Wr-E;EXIT}
If(!(Check-OSVersion 6 0)){Wr-E;Wr-R "This program requires Windows Version 6.0 (Windows 2008) or better!";Wr-E;Prompt-Keys -AnyKey;EXIT}
If(!(Got-DFSUtil))        {Wr-E;Wr-R "This program requires access to DFSUTIL.EXE!";Wr-E;Prompt-Keys -AnyKey;EXIT}
# Note: We do not check AD rights permissions to DFS, but if the account doesn't have enough permission data gathering will fail!

Set-Window White Black $title 80            # Set White text, Black background, Window Title, @ 80% max window size
Wr-E;Wr-W "<<<<<<<<< $title >>>>>>>>>";Wr-E # Display TITLE

$modes = "Set Referral Priority Class (For Clustered ONTAP)","Set State Online/Offline (For Data ONTAP 7-Mode)" # Initialize available modes
$safeModes = "Safe Mode ENABLED (Updates NOT possible)!","Safe Mode DISABLED (UPDATES will be ACTIONED)!"       # Initialize description for safe modes
$mode  = 0;$safeMode = $true                                                                                    # Initialize mode for CDOT and safe mode TRUE

$nsChoice = "ALL"; $loadFile = $true # Initialize selection of ALL namespaces; enable loading the Domain Servers File on first run
$global:tableOfLinks = $global:ToLcount = $global:targets = $null                                                   # Global variables we set to NULL
$global:first = $global:last = $global:enabled = $global:disabled = $null                                           # Global variables we set to NULL
$reset1 = $reset2 = $reset4 = $reset4 = $domainName = $servers = $gotNameSpaces = $domainOrServer = $backup = $null # Non-global ones we set to NULL

$backupPath = Create-Folder $backupPath # This returns back the default $backupPath if it was created or already exists
Wn-W "Checking for the default Domain and Servers file at "; Wr-C $domainServersFile; Wr-E # Display on first running the script

while($true){ # START of 'MAIN MENU SYSTEM' ... a perpetual loop

    If($loadFile){                                     # If $loadFile then load the domainServersFile
        If(Test-Path $domainServersFile){              # Check if a $domainServersFile exists
            $content = Get-Content $domainServersFile  # Get the file contents
            If($content[0]){$domainName = $content[0]} # Domain is on the first line (or blank)
            If($content[1]){$servers = $content[1]}    # Servers (separated by commas) are on the second line (or blank)
        } else {                                       # Otherwise, no file                                                   
            $domainServersFile = $null                 # Set the string $domainServersFile to NULL
        }                                              # NOTE: There is (currently) no error checking in here for the validity of the file contents
        $loadFile = $null                              # Will not reload the file on subsequent starts of the main menu (unless a new file is selected for loading)
    }                                                  # END: If $loadFile

    If ($reset1){$reset1 = $gotNameSpaces = $null; $nsChoice = "ALL"; $reset2 = $true}
    If ($reset2){$reset2 = $backup = $null; $reset3 = $true}
	If ($reset3){$reset3 = $global:tableOfLinks = $global:targets = $null; $reset4 = $true}
	If ($reset4){$reset4 = $global:first = $global:last = $global:enabled = $global:disabled = $null; $safeMode = $true}

    ## MAIN MENU ##
    
    Wr-W "<<<<<<<<< MAIN MENU >>>>>>>>>";Wr-E             # MAIN MENU
    $PROMPTKEYS = "X","Q","B","1","2","3"                 # Initialize the key selections array with always available options
    If($domainName -or $servers){$domainOrServer = $true  # Set the $domainOrServer flag to TRUE if we have any
    } else {                     $domainOrServer = $null} # ... otherwise set it to NULL

    # ~~~~~ DISPLAY: Options B,1 - 3 ~~~~~ #
	If($backupPath) {            Wn-W "    <B>   Change backup folder. Current = ";Wr-C $backupPath}
	else {                       Wr-R "    <B>   Select a backup folder!"}    
    If($domainServersFile){      Wn-W "    <1>   Reload Domain and Server(s) from file. Last loaded = ";Wr-C $domainServersFile}
    else{                        Wr-W "    <1>   Load Domain and Server(s) from file"}
    If($domainName){             Wn-W "    <2>   Change Domain. Currently selected = ";Wr-G $domainName}
    else{                        Wr-W "    <2>   Enter Domain Name (for Domain-based namespaces)"}
    If($servers){                Wn-W "    <3>   Change Server(s). Currently selected = ";Wr-G $servers}
    else{                        Wr-W "    <3>   Enter Server Name(s) (for Standalone namespaces)"}
    # ~~~~~ DISPLAY: Options 4 - 8 ~~~~~ #
    If($domainOrServer){    Wr-E;Wr-W "    <4>   Display Namespaces";$PROMPTKEYS += "4"}
    If($gotNameSpaces){          Wn-W "    <5>   Select an individual namespace/select ALL. Currently selected = ";Wr-C $nsChoice;$PROMPTKEYS += "5"}
    If($gotNameSpaces -and $backupPath){
								 Wr-W "    <6>   Backup Namespaces";$PROMPTKEYS += "6"}
    If($backup){                 Wr-W "    <7>   Display Table of Links, Target, State and PriorityClass";$PROMPTKEYS += "7"}
    If($global:tableOfLinks){    Wr-W "    <8>   Display List of Servers with Targets in the Namespaces";$PROMPTKEYS += "8"}
    # ~~~~~ DISPLAY: Options T,F,L,E,D ~~~~~ #
    $common = "Set Server whose Targets are to be set as"                        
    If($global:targets){    Wr-E;Wn-W "    <T>   (T)oggle Mode of Operation. Current = ";Wr-C $modes[$mode];$PROMPTKEYS += "T"
        If($mode -eq 0){ $PROMPTKEYS += "F","L"
            If($global:first){   Wn-W "    <F>   $common Priority (F)irst. "; Wr-G ("Selected = " + $global:first)}
            else{                Wr-W "    <F>   $common Priority (F)irst."}
            If($global:last){    Wn-W "    <L>   $common Priority (L)ast . "; Wr-G ("Selected = " + $global:last)}
            else{                Wr-W "    <L>   $common Priority (L)ast ."}
        } else { $PROMPTKEYS += "E","D"
            If($global:enabled){ Wn-W "    <E>   $common (E)nabled . "; Wr-C ("Selected = " + $global:enabled)}
            else{                Wr-W "    <E>   $common (E)nabled ."}
            If($global:disabled){Wn-W "    <D>   $common (D)isabled. "; Wr-C ("Selected = " + $global:disabled)}
            else{                Wr-W "    <D>   $common (D)isabled."}}} 
    # ~~~~~ DISPLAY: Options C,S,U ~~~~~ #
    If($global:last -or $global:first -or $global:enabled -or $global:disabled){
        $PROMPTKEYS += "S","C","U"
                            Wr-E;Wr-C "    <C>   Display DFSUTIL (C)ommands that will be run."
        If($safeMode){           Wn-G "    <S>   Toggle (S)afe Mode On/Off. Current = "; Wr-G $safeModes[0]
                                 Wr-G "    <U>   (U)PDATE DFS!"
        } else {                 Wn-Y "    <S>   Toggle (S)afe Mode On/Off. Current = "; Wr-Y $safeModes[1]
                                 Wr-Y "    <U>   (U)PDATE DFS!"}}
    # ~~~~~ DISPLAY: Exit and Press a Key ~~~~~ #
                            Wr-E;Wr-W "    <X/Q> E(X)it/(Q)uit!"
                            Wr-E;Wn-G "    <<<<< Press a Key: "

    ## Handle the Keys ##
    
    $key = Prompt-Keys $PROMPTKEYS;Wr-Y $key; Wr-E
    
    # <<<<<<< HANDLE: X,B,1,2,3 >>>>>>> #
    If(($key -eq "X") -or ($key -eq "Q")){EXIT}
	If($key -eq "B"){$backupPath = Rd-W "Enter backup folder path"; $backupPath = Create-Folder $backupPath; Wr-E; $reset2 = $true}
    If($key -eq "1"){$domainServersFile = Prompt-ForDomainServersFile; $loadFile = $true; $reset1 = $true}
    If($key -eq "2"){$domainName = Prompt-ForDomain; $reset1 = $true}
    If($key -eq "3"){$servers = Prompt-ForServer; $reset1 = $true}
    # <<<<<<< HANDLE: 4 - 8 >>>>>>> #
    If($key -eq "4"){$gotNameSpaces = Display-Namespaces $domainName $servers} # KEY: "4" get's a properly formatted table of Namespaces
    If($key -eq "5"){                                                          # KEY: "5" selection
        $newChoice = Prompt-ForNamespace $gotNameSpaces                        # Prompt for new choice if NameSpace
        If($newChoice -ne $nsChoice){$reset2 = $true}                          # If $newChoice is different to the old, we need to reset $reset2 set of variables
        $nsChoice = $newChoice                                                 # Always set $nsChoice to $newChoice
    }                                                                          # END: "5" selection
    If($key -eq "6"){                                                          # KEY: "6" for backup!
		$backup = Backup-Namespaces -Domain $domainName -Server $servers -Namespace $nsChoice -Path $backupPath
		$reset3 = $true}                                                       # Running a backup always re-initializes the $global:tableOfLinks to a NULL array
	If($key -eq "7"){[Void](Display-TableOfLinks $backup)}                     # KEY: "7" generates and/or displays $global:tableOfLinks
	If($key -eq "8"){[Void](Display-TargetServers)}                            # KEY: "8" generates and/or displays $global:targets (hashtable of target servers & occurrences) 
    # <<<<<<< HANDLE: T,F,L,E,D >>>>>>> #
    If($key -eq "T"){                                     # KEY: "T" (T)oggle
        If($mode -eq 0){$mode = 1}                        # Mode now "Set State"
        else           {$mode = 0}                        # Mode now "Set PriorityClass"
        $reset4}                                          # Toggling mode resets these variables
    If($key -eq "F"){$global:first    = Prompt-ForTarget} # KEY: "F"
	If($key -eq "L"){$global:last     = Prompt-ForTarget} # KEY: "L"
	If($key -eq "E"){$global:enabled  = Prompt-ForTarget} # KEY: "E"
	If($key -eq "D"){$global:disabled = Prompt-ForTarget} # KEY: "D"
    # <<<<<<< HANDLE: S,C,U >>>>>>> #
    If($key -eq "S"){                         # START: S selection for (S)afe
        If($safeMode){$safeMode = $null}      # ... not SAFE mode
        else         {$safeMode = $true}}     # ... now SAFE mode
    If($key -eq "C"){ # --------------------- # START: C selection for (C)ommands
        [Void](Update-DFSUtil -ShowCommands)} # ... RUN but just show commands
    If($key -eq "U"){ # --------------------- # START: U selection for (U)pdate
        If($safeMode){                        # ... If safe mode
            [Void](Update-DFSUtil -Safe)      # RUN Update-DFSUtil in safe mode
        } else {                              # ... else ...
            [Void](Update-DFSUtil)            # RUN Update-DFSUtil
            $reset2 = $true                   # ... after FULL run, run  $reset2 (will need to backup before more changes!)
        }                                     # END: NOT $safeMode
    } # ------------------------------------- # END:   R selection

} # END of 'MAIN MENU SYSTEM' ... loop back to start

#########################
## END of MAIN PROGRAM ##
#########################


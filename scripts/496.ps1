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

Function Convert-Delimiter([regex]$from,[string]$to) 
{
   begin
   {
      $z = [char](222)
   }
   process
   {
      $_ = $_.Trim()
      $_ = $_ -replace "(?:`"((?:(?:[^`"]|`"`"))+)(?:`"$from|`"`$))|(?:$from)|(?:((?:.(?!$from))*.)(?:$from|`$))","$z`$1`$2$z$to"
      $_ = $_ -replace "$z(?:$to|$z)?`$","$z"
      $_ = $_ -replace "`"`"","`"" -replace "`"","`"`"" 
      $_ = $_ -replace "$z((?:[^$z`"](?!$to))+)$z($to|`$)","`$1`$2"
      $_ = $_ -replace "$z","`"" -replace "$z","`""
      $_
   }
}

################################################################################
## Import-Delimited - A replacement function for Import-Csv that can handle other 
## delimiters, and can import text (and collect it together) from the pipeline!!
## Dependends on the Convert-Delimiter function.
################################################################################
## NOTICE that this means you can use this to import multitple CSV files as one:
## Sample Use:
##        ls ..\*.txt | export-csv textfiles.csv
##        ls *.doc | export-csv docs.csv
##        ls C:\Windows\System32\*.hlp | export-csv helpfiles.csv
##
##       $files = ls *.csv | Import-Delimited
## OR
##     Import-Delimited " +" services1.txt 
## OR
##     gc *.txt | Import-Delimited "  +"
################################################################################
## Version History
## Version 1.0
##    First working version
## Version 2.0
##    Filter #TYPE lines
##    Remove dependency on Convert-Delimiter if the files are already CSV
##    Change to use my Template-Pipeline format (removing the nested Import-String function)
## Version 2.1
##    Fix a stupid bug ...
##    Add filtering for lines starting with "--", hopefully that's not a problem for other people...
##    Added Write-DEBUG output for filtered lines...

Function Import-Delimited([regex]$delimiter=",", [string]$PsPath="")
{
    BEGIN {
        if ($PsPath.Length -gt 0) { 
            write-output ($PsPath | &($MyInvocation.InvocationName) $delimiter); 
        } else {
            $script:tmp = [IO.Path]::GetTempFileName()
            write-debug "Using tempfile $($script:tmp)"
        }
    }
    PROCESS {
        if($_ -and $_.Length -gt 0 ) {
            if(Test-Path $_) {
                if($delimiter -eq ",") {
                    Get-Content $_ | Where-Object {if($_.StartsWith("#TYPE") -or $_.StartsWith("--")){ write-debug "SKIPPING: $_"; $false;} else { $true }} | Add-Content $script:tmp
                } else {
                    Get-Content $_ | Convert-Delimiter $delimiter "," | Where-Object { if( $_.StartsWith("--") ) { write-debug "SKIPPING: $_"; $false;} else { $true }} | Add-Content $script:tmp
                }
            } 
            else {
                if($delimiter -eq ",") {
                    $_ | Where-Object {-not $_.StartsWith("#TYPE")} | Add-Content $script:tmp
                } else {
                    $_ | Convert-Delimiter $delimiter "," | Add-Content $script:tmp
                }
            }
        }
    }
    END {
        # Need to guard against running this twice when you pass PsPath
        if ($PsPath.Length -eq 0) {
            Import-Csv $script:tmp
        }
    }
}


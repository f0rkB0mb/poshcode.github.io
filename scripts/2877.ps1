# functions to print overwriting multi-line messages.  Test script will accept a file/filespec/dir and iterate through all files in all subdirs printing a test message + file name to demostrate.
# e.g. PS>.\writefilename.ps1 c:\
# call WriteFileName [string]
# after done writing series of overwriting messages, call WriteFileNameEnd

function WriteFileName ( [string]$writestr )                        # this function prints multiline messages on top of each other, good for iterating through filenames without filling
{                                                                   # the console with a huge wall of text.  Call this function to print each of the filename messages, then call WriteFileNameEnd when done
                                                                    # before printing anything else, so that you are not printing into a long file name with extra characters from it visible.
    if ($Host.Name -match 'ise') 
    { write-host $writestr; return }
                                                                            
    if ($global:wfnlastlen -eq $null) {$global:wfnlastlen=0}              
    $ctop=[console]::cursortop
    $cleft=[console]::cursorleft	

	$oldwritestrlen=$writestr.length
    
    $rem=$null
	$writelines = [math]::divrem($writestr.length+$cleft, [console]::bufferwidth, [ref]$rem)
	#if ($rem -ne 0) {$writelines+=1}

    $cwe = ($writelines-(([console]::bufferheight-1)-$ctop))                                       # calculate where text has scroll back to.
    if ($cwe -gt 0) {$ctop-=($cwe)}
    
	write-host "$writestr" -nonewline    
	$global:wfnoldctop=[console]::cursortop
	$global:wfnoldcleft=[console]::cursorleft
	
	if ($global:wfnlastlen -gt $writestr.length)
	{
		write-host (" " * ($global:wfnlastlen-$writestr.length)) -nonewline                    # this only overwrites previously written text if needed, so no need to compute buffer movement on this
	}
	
	
	$global:wfnlastlen = $oldwritestrlen

    if ($ctop -lt 0) {$ctop=$cleft=0}
	[console]::cursortop=$ctop
	[console]::cursorleft=$cleft
}
function WriteFileNameEnd ( $switch=$true)                                                      # call this function when you are done overwriting messages on top of each other
{                                                                                               # and before printing something else.  Default switch=$true, which prints a newline, $false restores cursor position same line.
    if ($Host.Name -match 'ise') 
    { return }
    if ($global:wfnoldctop -ne $null -and $global:wfnoldcleft -ne $null) 
    {
        [console]::cursortop=$global:wfnoldctop
        [console]::cursorleft=$wfnoldcleft  
        if ($global:wfnoldcleft -ne 0 -and $switch)
        {
            write-host ""
        }
    }    
    $global:wfnoldctop=$null
    $global:wfnlastlen=$null
    $global:wfnoldcleft=$null
}

    write-host "Checking: " -nonewline
    dir $args -recurse -ea 0 -force | %{WriteFileName ("$($_.fullname) ..."*(get-random -min 1 -max 100))}
    
    #WriteFileName "Final Test String."
    WriteFileNameEnd
    write-host "Done! exiting."

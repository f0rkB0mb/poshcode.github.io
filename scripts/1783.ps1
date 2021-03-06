# new version has more error handling, "-delete" and "-noprompt" options.

function Get-MD5([System.IO.FileInfo] $file = $(throw 'Usage: Get-MD5 [System.IO.FileInfo]'))

{
  	$stream = $null;
  	$cryptoServiceProvider = [System.Security.Cryptography.MD5CryptoServiceProvider];
  	$hashAlgorithm = new-object $cryptoServiceProvider
  	$stream = $file.OpenRead();
  	$hashByteArray = $hashAlgorithm.ComputeHash($stream);
  	$stream.Close();

  	## We have to be sure that we close the file stream if any exceptions are thrown.

  	trap
  	{
   		if ($stream -ne $null)
    		{
			$stream.Close();
		}
  		break;
	}	

 	foreach ($byte in $hashByteArray) { if ($byte -lt 16) {$result += “0{0:X}” -f $byte } else { $result += “{0:X}” -f $byte }}
	return [string]$result;
}

$starttime=[datetime]::now

write-host "Usage: finddupe.ps1 <directory/file #1> <directory/file #2> ... <directory/file #N> [-delete] [-noprompt]"

$matches = 0     	# initialize number of matches for summary.
$filesdeleted = 0 	# number of files deleted.
$bytesrec = 0 		# Number of bytes recovered.
$del = $false 		# delete duplicates
$noprompt = $false  	# delete without prompting toggle

$args | ?{$_ -eq "-delete"} |%{$del=$true}
$args | ?{$_ -eq "-noprompt"} | %{$noprompt=$true}

$files=@(dir -ea 0 -recurse ($args | ?{$_ -ne "-delete" -and $_ -ne "-noprompt"} |?{if ((get-item -ea 0 $_) -eq $null){write-host "`aError: " -f red -nonewline; write-host "$_ not found.";exit} else {$_}})|?{$_.psiscontainer -ne $true} )

if ($files.count -lt 2) {"Need at least two files to compare.`a";exit}

for ($i=0;$i -ne $files.count; $i++)  # Cycle thru all files
{
	if ($files[$i] -eq $null) {continue}

	$filecheck = $files[$i]
	$files[$i] = $null	

	for ($c=0;$c -ne $files.count; $c++)
	{
		if ($files[$c] -eq $null) {continue}
#		write-host "Comparing $filecheck and $($files[$c])     `r" -nonewline
	
		if ($filecheck.length -eq $files[$c].length)
		{
			#write-host "Comparing MD5 of $($filecheck.fullname) and $($files[$c].fullname)     `r" -nonewline	

			if ($filecheck.md5 -eq $null) 
			{ 
				$md5 = (get-md5 $filecheck.fullname)
				$filecheck = $filecheck | %{add-member -inputobject $_ -name MD5 -membertype noteproperty -value $md5 -passthru}			
			}
			if ($files[$c].md5 -eq $null) 
			{ 
				$md5 = (get-md5 $files[$c].fullname)
				$files[$c] = $files[$c] | %{add-member -inputobject $_ -name MD5 -membertype noteproperty -value $md5 -passthru}				
			}
			
			if ($filecheck.md5 -eq $files[$c].md5) 
			{
				
				write-host "Size and MD5 match: " -fore red -nonewline
				write-host "`"$($filecheck.fullname)`"" -nonewline
				write-host " and " -nonewline
				write-host "`"$($files[$c].fullname)`""

				$matches += 1
				
				if ($del -eq $true)
				{
					if ($noprompt -eq $true)
					{
						del $files[$c].fullname
						write-host "Deleted duplicate: " -f red -nonewline
						write-host "$($files[$c].fullname)."
					}
					else
					{
						del $files[$c].fullname -confirm
					}
					if ((get-item -ea 0 $files[$c].fullname) -eq $null)
					{
						$filesdeleted += 1
						$bytesrec += $files[$c].length
					}

				}
	
				$files[$c] = $null
			}
		}
	}
}
write-host ""
write-host "Number of Files checked: $($files.count)."	# Display useful info; files checked and matches found.
write-host "Number of duplicates found: $matches."
Write-host "Number of duplicates deleted: $filesdeleted." # Display number of duplicate files deleted and bytes recovered.
write-host "$bytesrec bytes recovered."	
write-host ""
write-host "Time to run: $(([datetime]::now)-$starttime|select hours, minutes, seconds, milliseconds)"
write-host ""

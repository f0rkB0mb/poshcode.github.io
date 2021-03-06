# Parse tables within HTML files and return the rows as PowerShell objects.
# The idea here is similar to (though not nearly as complete as) Perl's HTML::TableParse.
# This function should run anywhere but it's a bit slow because of the COM interface
# it uses. There seem to be a few .NET libraries out there that would make it a lot
# faster but you may not have those installed. Please improve this if you 
#
# One other quirk is that this function will only return one table at a time, through
# the tableNumber parameter. If you need to extract multiiple tables you need to make
# multiple calls. This was done because PowerShell seems to make it difficult to make
# arrays of arrays, preferring one big happy array instead. Please improve if you
# know how.
#
# TODO: Make it run faster.

function get-rowInner {
	param($inputObject, $unique=0, $trim=0)

	$values = @()
	foreach ($obj in $inputObject) {
		if ($obj.nodeName -eq "TD" -or $obj.nodeName -eq "TH") {
			$value = $obj.innerText
			if ($trim) {
				$value = $value.trim()
			}
			if ($unique) {
				if ($values -contains $value) {
					$i = 2
					while ($values -contains ($value + $i)) {
						$i++
					}
					$values += ($value + $i)
				} else {
					$values += $value
				}
			} else {
				$values += $value
			}
		}
	}

	if ($values.length -gt 0) {
		return $values
	} else {
		return $null
	}
}	

function get-row {
	param($inputObject, $unique=0, $trim=0)

	if ($inputObject.nodeName -eq "TR") {
		# We are at the row level.
		return get-rowInner -inputObject $inputObject.childnodes -unique $unique -trim $trim
	} else {
		# Rows can be nested inside other tags.
		foreach ($node in $inputObject.childnodes) {
			$row = get-row -inputObject $node -unique $unique -trim $trim
			if ($row -ne $null) {
				return $row
			}
		}
	}
}

function get-table {
	param($inputObjects)

	# We treat the first row as column headings.
	$headings = $null
	$rows = @()

	foreach ($obj in $inputObjects) {
		if ($headings -eq $null) {
			# The first row will be the headings.
			$headings = get-row -inputObject $obj -unique 1 -trim 1
			continue
		}

		$row = get-row -inputObject $obj
		if ($row -ne $null -and $row.length -eq $headings.length) {
			$rowObject = new-object psobject
			for ($i = 0; $i -lt $headings.length; $i++) {
				$value = $row[$i]
				if ($value -eq $null) {
					$value = ""
				}
				$rowObject | add-member -type noteproperty -name $headings[$i] -value $value
			}
			$rows += $rowObject
		}
	}

	return $rows
}

function Parse-HtmlTableRecursive {
	param($inputObjects)

	foreach ($_ in $inputObjects) {
		if ( ($_ | Get-Member -Name nodename) -and ($_.nodeName -eq "TBODY") ) {
			if (--$global:htmlParseCount -eq 0) {
				return get-table -inputObjects $_.childnodes
			}
		}

		if ( ($_ | Get-Member -Name childnodes) -and ($_.childnodes -ne $null) ) {
			$table = Parse-HtmlTableRecursive -inputObjects $_.childnodes
			if ($table) {
				return $table
			}
		}
	}

	return $null
}

function Parse-HtmlTable {
	param($url, $tableNumber=1)

	$client = new-object net.webclient
	$htmltext = $client.downloadstring($url)

	# For testing local files
	#$temp = gc $url
	#$htmltext = ''
	#for ($i = 0; $i -lt $temp.length; $i++) {
	#	$htmltext += $temp[$i]
	#}

	$global:htmlParseCount = $tableNumber
	$h = new-object -com "HTMLFILE"
	$h.IHTMLDocument2_write($htmltext)
	$ret = Parse-HtmlTableRecursive -inputObject $h.body
	remove-variable -scope global htmlParseCount
	return $ret
}

# Example: Get the 250 most common words in the English language.
# Parse-HtmlTable -url http://esl.about.com/library/vocabulary/bl1000_list1.htm
# Parse-HtmlTable -url http://esl.about.com/library/vocabulary/bl1000_list1.htm | select Word, Word2

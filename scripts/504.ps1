###################################################################
# Update Columns in PowerPacks
###################################################################
# (c) Dmitry Sotnikov
# http://dmitrysotnikov.wordpress.com
###################################################################
# This script is designed to work around a PowerPack export
# issue in PowerGUI 1.5.1 (fixed in subsequent releases
# The script goes though the PowerGUI configuration
# and PowerPack file and updates the file with column
# selection info from PowerGUI config
###################################################################

###################################################################
# Make sure you set these paths to the old and new pack accordingly
###################################################################
$powergui_cfg_path = "$($env:APPDATA)\Quest Software\PowerGUI\quest.powergui.xml"
$powerpack_path = 'c:\scripts\aliases.powerpack'
$updated_powerpack_path = 'C:\scripts\new.powerpack'

##################################################
# First extract column data from PowerGUI config
##################################################

# load local PowerGUI configuration
$pg = [xml] (gc $powergui_cfg_path)

# locate column-by-type storage
$uiviews = $null
foreach ($c in $pg.configuration.items.container) {
	if ($c.Name -eq 'UI View') { $uiviews = $c; break; }
}

# hash-table to store columns by type
$columns = @{}

if ( $uiviews -ne $null ) {
	# for each of these types, create a hash table, storing the column names
	foreach ($c in $uiviews.items.container.items.container) {
		"Type: $($c.Type)"
		$properties = @()
		if ( $c.items.container -ne $null ) {
			foreach ($col in $c.items.container) {$col.Name; $properties += $col.Name }
			if ($properties.Length -gt 0) { $columns[$c.Type] = $properties }
		} elseif ( $c.items.item -ne $null ) {
			foreach ($col in $c.items.item) {$col.Name; $properties += $col.Name }
			if ($properties.Length -gt 0) { $columns[$c.Type] = $properties }
		} 
	}
	" === Hash Table === "
	$columns
}

##################################################################
# Now go through the PowerPack and add column data when required
##################################################################

$pp = [xml] (gc $powerpack_path)

# This function adds column data to a tree node or link
function AssignTypes {
	param($segment)
	if ( $segment -ne $null ) {
		$segment.returntype
		if ($segment.items.container.name -notlike "properties*") {
			# no properties assigned
			" --- No columns assigned"
			if ( ($segment.returntype -ne $null) -and $columns.ContainsKey($segment.returntype) ) {
				# construct the columns section
				" --- Found columns by type"
				$cont = $pp.CreateElement("container")
				$cont.SetAttribute("id", [Guid]::NewGuid().ToString())
				$cont.SetAttribute("name", "properties_a807f902-4b43-4b22-86d8-724abc4c3d4a")
				$segment["items"].AppendChild($cont)
				$subitems = $pp.CreateElement("items")
				$cont.AppendChild($subitems)
				foreach ($c in $columns[$segment.returntype]) {
					$item = $pp.CreateElement("item")
					$item.SetAttribute("id", [Guid]::NewGuid().ToString())
					$item.SetAttribute("name", $c)
					$subitems.AppendChild($item)
				}
			}
		} else {
			" --- Columns already assigned"
		}
	}
}

# This function recurses through the navigation tree 
function IterateTree {
	param($segment)
	if (($segment.Type -like 'Script*') -or ($segment.Type -like 'CmdLet*')) {
		# found a node, check whether it has columns assigned
		AssignTypes $segment
	}
	if ($segment.items.container -ne $null) {
		$segment.items.container | ForEach-Object { IterateTree $_ }
	}
}

" === Tree === "
IterateTree $pp.configuration.items.container[0]

" === Links === "
$pp.configuration.items.container[1].items.container | 
		where { $_.id -eq '481eccc0-43f8-47b8-9660-f100dff38e14' } | ForEach-Object {
			# Do both container and item because of possible format variation
			$_.items.container | ForEach-Object { AssignTypes $_ }	
			$_.items.item | ForEach-Object { AssignTypes $_ }	
		}

# Save updated file
$pp.Save($updated_powerpack_path)


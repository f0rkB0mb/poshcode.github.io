$systems | ForEach {
	# Populate $currentcomp with item for processing
	$currentcomp = $_
	# Try to perform the following code-block on the specified system. If there are problems, drop to "Catch" block below.
	Try {
		$progressstr = (Get-Timestamp) + " - Attempting to process system: " + $currentcomp
		$progressstr | Out-File $progresslog -Append
		# Populate $adminmembers with results returned by Get-LocalGroupMembers function (detailed above) for specified system's Administrators group
		$adminmembers = Get-LocalGroupMembers -computer $currentcomp -groupnames "Administrators"
		# Populate $localusers with results returned by Get-LocalGroupMembers function (detailed above) for specified system
		$localusers = Get-LocalUsers -computer $currentcomp
		
		# Create a hash table to store information about this specific computer
		$systemhash = @{
			# Save array of system's local administrator group members to property "Administrators"
			"Administrators" = $adminmembers.Get_Item("Administrators");
			# Save array of system's enabled local user accounts to property "LocalUsersEnabled"
			"LocalUsersEnabled" = $localusers.Get_Item("Enabled");
			# Save array of system's disabled local user accounts to property "LocalUsersDisabled"
			"LocalUsersDisabled" = $localusers.Get_Item("Disabled");
			# Use Get-Timestamp to record exactly when this information was exported, save as "ExportTime" property
			"ExportTime" = Get-Timestamp
			}
		
		# Add the information about the specified system to the $localhash with the system name as the key
		$localhash.Add($currentcomp,$systemhash)
		
		# Add confirmation to progress log
		$progressstr = (Get-Timestamp) + " - Completed processing for system: " + $currentcomp
		$progressstr | Out-File $progresslog -Append
		}
		
	# If there are any problems retrieving the group information...
	Catch [Exception] {
		# Build a log file entry with details of what went wrong
		$errorstring = "Unable to retrieve information about local groups/users for system " + $currentcomp + ". Error message: " + $_
		# And output it to the error log
		$errorstring | Out-File $errorlog -Append
		}
	}

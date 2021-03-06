#########################################
#Name: VMWare Quick Migration Function
#Author: Justin Grote <jgrote NOSPAMAT enpointe DOT com>
#Credit: Inspired by Mike DiPetrillo's Quick Migration Script: http://www.mikedipetrillo.com/mikedvirtualization/2008/10/quick-migration-for-vmware-the-power-of-powershell.html
#Source: http://poshcode.org/1246
#Version: 0.1
#Last Revised: 31 July 2009
#
#Description: Performs the fucntional equivalent of a Hyper-V Quick Migration by suspending a VM, 
#	moving it to a new host, and resuming it. This does not require vMotion licensing.
#	it works by providing required VM objects via the pipeline or the second argument, 
#	and specifying the Destination host in the first argument.
#	The commeand accepts both text strings and VMHost objects for the VMHost Parameter
#

#Prerequisites:
#	Powershell v1
#	VMWare PowerCLI 4.0 (May work with earlier version but not tested)
#
#Instructions to Install: Save this script and import into your session with, for example, . C:\temp\quickmigrate.ps1
#	You can also include it in your PowerCLI profile to have it automatically included.
#Command Usage: get-vm MyTestVM | Quick-MigrateVM "MyTestHost2"
#########################################
function QuickMigrate-VM {
	PARAM(
		$NewVMHost = ""
		, [VMware.VimAutomation.Client20.VirtualMachineImpl]$VMsToMigrate = $null
	)
	BEGIN {
		if (!$NewVMHost){
			Write-Error "No Destination VMHost Specified. You must specify a host to migrate to. `n Example: Get-VM `"Test`" | QuickMigrate-VM `"Host1`""
			break
		}
		elseif ($VMsToMigrate) {
			Write-Output $InputObject | &($MyInvocation.InvocationName) -NewVMHost $newVMHost
		}
		else {
			#If NewVMHost was provided as a String, convert it into a VMHost Object.
			if ($NewVMHost.GetType().Name -eq "String") {
				set-variable -name destinationVMHost -value (get-vmhost $NewVMHost) -scope 1
			}
			#Make sure that we have a VMHost object to work with.
			if (! $destinationVMHost -or (! $destinationVMHost.GetType().Name -eq "VMHostImpl")) {
				write-error "Destination VM Host was not found or you provided the wrong object type. Please provide a VMHostImpl object or specify the fully qualified name of a VM Host"
				break
			}
			write-host -fore white "===Begin Quick Migration==="
		}
	}
	
	PROCESS {
		$step = 0
		$skip = $false
		#In the Event of an error, output the error, and skip the rest of the current item.
		#This is a workaround for the fact that "continue" doesn't work in a function process loop.
		trap {
			write-host -fore yellow "`tSKIPPED: "$_.Exception.Message
			set-variable -name skip -value ($true) -scope 1
			continue
		}
		$vmToMigrate = $_
		
		### Validation Checks
		if($_ -is [VMware.VimAutomation.Client20.VirtualMachineImpl]) {
			write-host -fore white "Quick Migrating $($vmToMigrate.Name) to $NewVMHost..."
		}
		else {
			throw "Object Passed was not a Virtual Machine object. Object must be of type VMware.VimAutomation.Client20.VirtualMachineImpl."
		}
		# Check for connected devices
		if (! $skip -and (get-cddrive $vmToMigrate).ConnectionState.Connected -ieq "TRUE") {
			throw "Connected CD Drive. Please disconnect and try again."
		}
		if (! $skip -and (get-floppydrive $vmToMigrate).ConnectionState.Connected -ieq "TRUE") {
			throw "Connected Floppy Drive. Please disconnect and try again."
		}
		
		# Make sure the current VM Host and the Destination Host are different.
		$sourceVMHost = get-vmhost -vm $vmToMigrate
		if (! $skip -and ($sourceVMHost.Name -eq $destinationVMHost.Name)) {
			throw "Source and Destination Hosts are the same."
		}
		
		###Validation Complete, begin Migration
		if (! $skip) {
			$step++
			write-host -fore cyan "`t$($step. Suspending" $vmToMigrate.Name"..."
			$suspend = Suspend-VM -VM $vmToMigrate -confirm:$false
		}
		if (! $skip) {
			$step++
			write-host -fore cyan "`t($step). Moving" $vmToMigrate.Name "to" $destinationVMHost.Name"..."
			$migrate = Get-VM $vmToMigrate | Move-VM -Destination $destinationVMHost
		}
		if (! $skip) {
			$step++
			write-host -fore cyan "`t($step). Resuming" $vmToMigrate.Name"..."
			$resume = Start-VM -VM $vmToMigrate
		}
		write-host -fore green "`tCOMPLETED"
	}

		END { write-host -fore white "===END Quick Migration===" }
}

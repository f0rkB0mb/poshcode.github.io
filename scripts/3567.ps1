Function Global:Get-NestedGroups {
	<#
		.SYNOPSIS
			Enumerate all AD group memberships of an account (including nested membership).
		.DESCRIPTION
			This script will return the AD group objects for each group the user is a member of.
		.PARAMETER UserName
			The username whose group memberships to find.
		.EXAMPLE
			Get-NestedGroups johndoe | Out-GridView
			Get-NestedGroups johndoe, janedoe | % { $_ | Out-GridView }
			Get-ADUser -Filter "cn -like 'john*'" | % { Get-NestedGroups $_ | Sort-Object Name | Out-GridView -Title "Groupmembership for $($_)" }
			"johndoe","janedoe" | % { Get-NestedGroups $_ | Sort-Object Name | Export-CSV Groupmembership-$($_.Name).csv -Delimiter ";" }
			"johndoe","janedoe" | Get-NestedGroups | % { Sort-Object Name | Out-GridView }
		.NOTES
			ScriptName : Get-NestedGroups
			Created By : Gilbert van Griensven
			Date Coded : 06/17/2012
			Updated    : 08/11/2012

			The script iterates through all nested groups and skips circular nested groups.
		.LINK
	#>
	[CmdletBinding(SupportsShouldProcess=$True)]
	Param (
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,HelpMessage="Please enter a username")] $UserName
	)
	Begin {
		$PipelineInput = -not $PSBoundParameters.ContainsKey("UserName")
		Write-Verbose "Looking for ActiveDirectory module"
		$Script:ADModuleUnload = $False
		If (!(Get-Module ActiveDirectory)) {
			Write-Verbose "ActiveDirectory module not loaded - checking availability"
			If (Get-Module -ListAvailable | ? {$_.Name -eq "ActiveDirectory"}) {
				Write-Verbose "ActiveDirectory module is available - loading module"
				Import-Module ActiveDirectory
			} Else {
				Write-Verbose "ActiveDirectory Module is not available"
				$Script:ADModuleUnload = $True
			}
		} Else {
			Write-Verbose "ActiveDirectory Module is already loaded"
			$Script:ADModuleUnload = $True
		}
		Function GetNestedGroups {
			Get-ADGroup $_ -Properties MemberOf | Select-Object -ExpandProperty MemberOf | % {
				If (!(($Script:GroupMembership | Select-Object -ExpandProperty DistinguishedName) -contains (Get-ADGroup $_).DistinguishedName)) {
					$Script:GroupMembership += (Get-ADGroup $_)
					GetNestedGroups $_
				}
			}
		}
		Function GetDirectGroups {
			$InputType = $_.GetType().Name
			If (($InputType -ne "ADUser") -and ($InputType -ne "String")) {
				Write-Error "Invalid input type `'$($_.GetType().FullName)`'" -Category InvalidType -TargetObject $_
				Break
			}
			If ($InputType -eq "String") {
				Try {
					Write-Verbose "Querying Active Directory for user `'$($_)`'"
					$UserObject = Get-ADUser $_
				}
				Catch {
					Write-Verbose "$_"
					Write-Error $_ -Category ObjectNotFound -TargetObject $_
					Break
				}
			} Else { $UserObject = $_ }
			$Script:GroupMembership = @()
			$Script:GroupMembership += (Get-ADGroup "Domain Users")
			Get-ADUser $UserObject -Properties MemberOf | Select-Object -ExpandProperty MemberOf | % {
				$Script:GroupMembership += (Get-ADGroup $_)
			}
			$Script:GroupMembership | ForEach-Object {GetNestedGroups $_}
		}
	}
	Process {
		If ($PipelineInput) {
			GetDirectGroups $_
			, $Script:GroupMembership
		} Else {
			$UserName | ForEach-Object {
				GetDirectGroups $_
				$Script:GroupMembership
			}
		}
	}
	End {
		If (!($Script:ADModuleUnload)) {
			Write-Verbose "Removing module ActiveDirectory"
			Remove-Module ActiveDirectory -ErrorAction SilentlyContinue
		}
	}
}

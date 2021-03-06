<?xml version="1.0" encoding="utf-8" ?>
<Types>
	<Type>
	<Name>System.Management.Automation.FunctionInfo</Name>
		<Members>
			<ScriptProperty> 
				<Name>Verb</Name> 
				<GetScriptBlock>
					if ($this.Name.Contains("-")) {
						$this.Name.Substring(0,$this.Name.Indexof("-"))
					} else {
						$null
					}
				</GetScriptBlock> 
			</ScriptProperty>
			<ScriptProperty> 
				<Name>Noun</Name> 
				<GetScriptBlock>
					if ($this.Name.Contains("-")){
						$this.Name.Substring(($this.Name.Indexof("-")+1),($this.Name.length - ($this.Name.Indexof("-")+1)))
					} else {
						$this.Name
					}
				</GetScriptBlock> 
			</ScriptProperty> 
			<ScriptProperty> 
				<Name>Prefix</Name> 
				<GetScriptBlock>
					$prefix_val = $((gmo $this.Module).ExportedFunctions.Values + (gcm -mo $this.ModuleName -CommandType "Function") |
					where { $_.Verb -eq $this.Verb } |
					group {	$_.Definition } |
					% {
						$names = $_.Group |
						Select -Expand Name;
						$ofs = "-";
						$verb,[string]$noun = @($names)[0] -split "-";
						foreach($name in $names){
							if ( $name.contains("-") ) {
								$name.substring($name.IndexOf("-") + 1, $name.LastIndexOf($noun) - $name.IndexOf("-") - 1 )
							}
						}
					} | where {$_} | select -unique | foreach { $_ | where {$this.Noun -match $_ } })
					if ( $prefix_val ) {
						$prefix_val
					} else {
						$null
					}
				</GetScriptBlock> 
			</ScriptProperty> 
			<ScriptProperty> 
				<Name>InternalName</Name> 
				<GetScriptBlock> 
					$prefix = $this.Prefix
					if ($prefix) {
						"$($this.Verb)-$($this.Noun.Replace($prefix, $null))"
					} else {
						"$($this.Name)"
					}
				</GetScriptBlock> 
			</ScriptProperty> 
		</Members>
	</Type>    
</Types>

# Process command line parameter (if present).
	[bool] $DISABLE_PROXY = $false;
    	foreach ($param in $MyInvocation.UnboundArguments) {
		if ($param -like 'disable') { $DISABLE_PROXY = $true; }
	}
	
# Apply/refresh the organization's default proxy settings.
@@	[string] $proxyServer   = '###.###.###.###:####';
@@	[string] $proxyOverride = '*.local;192.168.*;<local>';
@@	[int]    $migrateProxy  = 1;
@@	[int]    $proxyHttp11   = 1;
	
	REG ADD """HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings"" /v ""ProxyServer"" /t REG_SZ /d ""$proxyServer"" /f" | Out-Null;
	REG ADD """HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings"" /v ""ProxyOverride"" /t REG_SZ /d ""$proxyOverride"" /f" | Out-Null;
	REG ADD """HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings"" /v ""MigrateProxy"" /t REG_DWORD /d $migrateProxy /f" | Out-Null;
	REG ADD """HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings"" /v ""ProxyHttp1.1"" /t REG_DWORD /d $proxyHttp11 /f" | Out-Null;

<# 
Define a function to start a 'hidden' Internet Explorer process. 
This is needed since there is no easy way to programmatically 'refresh'
the user's proxy settings after they have been changed in the registry.
#>
function Start-HiddenIEProcess () {
	[object] $ieProcess = $null;
	
	# Launch Internet Explorer (use 32-bit version only) in a hidden window.
		if (Test-Path "$env:PROGRAMFILES(X86)\Internet Explorer\iexplore.exe") {	
			$ieProcess = Start-Process -Passthru -FilePath "$env:PROGRAMFILES(X86)\Internet Explorer\iexplore.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue;
		} else {		
			$ieProcess = Start-Process -Passthru -FilePath "$env:PROGRAMFILES\Internet Explorer\iexplore.exe" -WindowStyle Hidden;
		}
	# Wait for Internet Explorer to load fully.
		[int] $count = 10;
		do {
			if (($ieProcess.WaitForInputIdle())) {
				$waiting = $false; # IE is ready.
				$count   = 0;
			} else { 
				Start-Sleep 1;     # Sleep for another second.
				$count--;          # Decrement wait counter.
			}
		} while ($waiting -or ($count -gt 0));
		
	# Check to see if our new process exists.
		if ((Get-Process -Name iexplore -ErrorAction SilentlyContinue)) {
			return $true;
		} else {
			return $false;
		}
} # END

<# 
Define a function to toggle the user's proxy settings by altering the
required registry entry and then forcing a 'refresh' of the proxy status
by utilizing a hidden/temporary Internet Explorer process. 
#>
function Set-ProxyState ([bool] $disable) {
	# Kill existing IE processes.
		Stop-Process -Name iexplore -Force -ErrorAction SilentlyContinue;
		
	# Toggle proxy state.
		if ($disable) {
			Write-Host 'DISABLING user''s proxy settings...';
			REG ADD '"HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "ProxyEnable" /t REG_DWORD /d 0 /f' | Out-Null; # Disable proxy.
		} else {
			Write-Host 'ENABLING user''s proxy settings...';
			REG ADD '"HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "ProxyEnable" /t REG_DWORD /d 1 /f' | Out-Null; # Enable proxy.
		}
		
	# Start a new/hidden IE process temporarily.
		Start-HiddenIEProcess;
		
	# Kill existing IE processes.
		Stop-Process -Name iexplore -Force -ErrorAction SilentlyContinue;
		
	Write-Host '[DONE]';
		
	return $null;
} # END

# Toggle the user's proxy settings.
	$null = Set-ProxyState $DISABLE_PROXY;

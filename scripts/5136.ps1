# Force .NET Framework optimization to happen (causes high CPU by mscorsvw.exe)
# By default the optimization only uses a single CPU core.
# Running "NGEN.EXE executeQueuedItems" forces optimization to happen on all cores.
# http://blogs.msdn.com/b/dotnet/archive/2013/08/06/wondering-why-mscorsvw-exe-has-high-cpu-usage-you-can-speed-it-up.aspx

Remove-Item variable:frameworks
# get all framework paths (adding 64-bit if necessary):
$frameworks = @("$env:SystemRoot\Microsoft.NET\Framework")
If (Test-Path "$env:SystemRoot\Microsoft.NET\Framework64") {
    $frameworks += "$env:SystemRoot\Microsoft.NET\Framework64"
}

ForEach ($framework in $frameworks) {
    # find the latest version of NGEN.EXE in the current framework path:
    $ngen_path = Join-Path (Join-Path $framework -childPath (gci $framework | where { ($_.PSIsContainer) -and (Test-Path (Join-Path $_.FullName -childPath "ngen.exe")) } | Sort Name -Descending | Select -First 1).Name) -childPath "ngen.exe"
    # execute the optimization command:
    Write-Host "$ngen_path executeQueuedItems"
    Start-Process $ngen_path -ArgumentList "executeQueuedItems" -Wait
}


function Test-Help {
    <#
    .Synopsis
        Test-Help -Function Get-USB
    .Description
        Test-Help was written to get information why that !@##$%#$%# help is not working ;)
        Should work fine both with v1 and v2 comments.
        Using fancy regex that probably could be shorter, more elegant and so long and so forth... ;)
    .Example
        Test-Help -Function Test-Help
        If you want to find mistakes made by other - try to find yours first. ;)
    .Link
        Not yet implemented
    .Parameter Function
        Name of the function to be tested.
    .Notes
        Ver 0.2 - not yet implemented - testing of position in definition of function (has to be at the or at the bottom...)
        Ver 0.1 - added testing for v1 comments
        Ver 0.0 - simple test for v2 comment based help

    #>
    param ([string]$Function)
    try {
        $Definition = (Get-Command -CommandType function -Name $function -ErrorAction Stop).definition -split '\n'
        $regKey = [regex]'^\s*\.(?<KEY>\w+)($|\s*($|(?<PARAM>[\w-]+))($|\s*(?<ERROR>\S*)$))'
        $regV1Comment = [regex]'^\s*#(.*)'
        $regComStart = [regex]'^\s*<#\s*$'
        $regComEnd = [regex]'^\s*#>\s*$'
        $IsComment = $false
        $KEYS = @('SYNOPSIS','DESCRIPTION','EXAMPLE','INPUTS','OUTPUTS','NOTES','LINK','COMPONENT','ROLE','FUNCTIONALITY')
        $EXTKEYS = @('PARAMETER','FORWARDHELPTARGETNAME','FORWARDHELPCATEGORY','REMOTEHELPRUNSPACE','EXTERNALHELP')
        foreach ($line in $Definition) {
            $line = $line -replace '\r', ''
            $invocation = "Line : $line Function : $function"
            if (($IsComment) -or ($regV1Comment.IsMatch($line)))  {
                # just in case - we get rid of # at the line beg
                $line = $regV1Comment.Replace($line,'$1')
                if ($RegKey.IsMatch($line)) {
                    # should contain keyword
                    $RegKey.Match($line) | ForEach-Object {
                        $Key = $_.Groups['KEY'].Value
                        $Par = $_.Groups['PARAM'].Value
                        $Err = $_.Groups['ERROR'].Value
                    }
                    if (![string]::IsNullOrEmpty($Err)) {
                        Write-Host -ForegroundColor Cyan "Unexpected token - not more than two: $Err $invocation"
                        continue
                    }
                    if ($KEYS -contains $Key) {
                        if (![string]::IsNullOrEmpty($Par)) {
                            Write-Host -ForegroundColor Yellow "Unexpected token - keyword without additional parameters: $Par $invocation"
                            continue
                        }
                    } else {
                        if ($EXTKEYS -contains $Key) {
                            if ([string]::IsNullOrEmpty($Par)) {
                                Write-Host -ForegroundColor Magenta "Missing token - $Key should be followed by something, $invocation"
                            }
                        } else {
                            # Looks like spelling mistake...
                            Write-Host -ForegroundColor Green "Key probably with spelling mistake: $Key $invocation"
                        }
                    } 
                } else {
                    if ($RegComEnd.IsMatch($line)) {
                        $IsComment = $false
                    }
                }
            } else {
                if ($RegComStart.IsMatch($line)) {
                    $IsComment = $true
                }
            }
        }
    } catch {
        Write-Host -ForegroundColor Red "Error: $_ "
    }
}

function Get-UACManifest
{
<#
.SYNOPSIS

Output the UAC manifest for an executable.

Author: Matthew Graeber (@mattifestation)
License: BSD 3-Clause

.DESCRIPTION

Get-UACManifest is useful for discovering executables that run elevated or bypass UAC.

.PARAMETER FilePath

Specifies a path to one or more executables.

.EXAMPLE

Get-ChildItem C:\Windows\System32 | Get-UACManifest

Description
-----------
Outputs the UAC manifests for all executables in C:\Windows\System32.

.EXAMPLE

ls -r C:\Windows\System32\* | Get-UACManifest | ? { $_.Level -eq 'requireAdministrator' -bor $_.Level -eq 'highestAvailable' }

Description
-----------
Outputs all executables in System32 that run with elevated privileges
#>

    [CmdletBinding()] Param (
        [Parameter(Position = 1, Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
        [String[]]
        $FilePath
    )

    BEGIN
    {
        $Assembly = [Reflection.Assembly]::LoadWithPartialName('System.Deployment')
        $SystemUtils = $Assembly.GetTypes() | ? {$_.FullName -eq 'System.Deployment.Application.Win32InterOp.SystemUtils'}
        $GetManifestFromPEResources = $SystemUtils.GetMethod('GetManifestFromPEResources')
    }
    PROCESS
    {
        foreach ($File in $FilePath)
        {
            $TempPath = ''
            try { $TempPath = Get-ChildItem $File -ErrorAction SilentlyContinue } catch {}

            if ($TempPath -and (!$TempPath.PSIsContainer))
            {
                $FullFilePath = $TempPath
                
                $ManifestBytes = New-Object Byte[](0)
                $ManifestBytes = try { $GetManifestFromPEResources.Invoke($null, @("$FullFilePath")) } catch {}

                if ($ManifestBytes.Length -gt 0)
                {
                    $Encoder = [System.Text.Encoding]::ASCII
                    $ManifestText = $Encoder.GetString($ManifestBytes)

                    Write-Verbose "$FullFilePath Manifest:`n$ManifestText"

                    try
                    {
                        $Manifest = [Xml] $ManifestText
                    }
                    catch
                    {
                        return
                    }

                    $UACManifest = $Manifest.assembly.trustInfo.security.requestedPrivileges.requestedExecutionLevel

                    if ($UACManifest)
                    {
                        if ($UACManifest.uiAccess -eq $null)
                        {
                            $Access = $False
                        }
                        elseif ($UACManifest.uiAccess.ToLower() -eq 'false')
                        {
                            $Access = $False
                        }
                        elseif ($UACManifest.uiAccess.ToLower() -eq 'true')
                        {
                            $Access = $True
                        }
                
                        $Result = @{
                            Path = $FullFilePath.ToString()
                            Level = $UACManifest.level
                            BypassUAC = $Access
                        }

                        New-Object PSObject -Property $Result
                    }
                }
            }
        }
    }
    END {}
}


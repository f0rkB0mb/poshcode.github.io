param(
    [Parameter(position=0)]$SrcFolder = '\\YourWorkstation\PathHere',
    [switch]$NoBackupDestinationProfile
)

Write-Host "START [$($MyInvocation.MyCommand.Name)] $(get-date -f yyyyMMdd.HHmmss)"
$global:dirPSProfile = (Split-Path -Parent $profile)

filter DirHelper(
    [Parameter(Position=0)]$Path,
    [Parameter(Position=1)][Scriptblock]$DirExistsScriptBlock
) {
    [bool]$backupProfile = !(Test-Path -PathType Container $Path)
    if (!(Test-Path -PathType Container $Path)) {
        md $Path -Verbose
    }
    else  {
        if ($DirExistsScriptBlock -ne $null) {
            & $DirExistsScriptBlock
        }
    }
    cd $Path
}

DirHelper $dirPSProfile { $back = Join-Path (Split-Path $Path -Parent) '_GetCTBackup'
    Write-Warning "Found profile directory. Attempting backup before continuing. [$back]"
    Write-Host ('xcopy /iy "{0}" "{1}"' -f $path,$back)
    xcopy /iy "$Path" "$back"
}

if (Get-Command robocopy.exe -ErrorAction SilentlyContinue) {
    robocopy $SrcFolder $dirPSProfile /S
} else {
    $proc = &{ if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") { "64" } else { "" } }
    xcopy /d/y/i "$SrcFolder\bin\RichCopy*" "$dirPSProfile\bin"
    
    $cmd = '"{0}\bin\RichCopy{1}.exe"'-f $dirPSProfile,$proc
    $cmdArgs = ( $SrcFolder,'"{0}"','/TD','64','/TS','32','/SC','64','/FEF','_Scratch.ps1;*.7z' | %{ $_ -f $dirPSProfile })
    echo 'running command: {0} {1}' -f $cmd,($cmdArgs -join ' ')
    Start-Process -Wait $cmd $cmdArgs
}

Write-Host "END   [$($MyInvocation.MyCommand.Name)] $(get-date -f yyyyMMdd.HHmmss)"


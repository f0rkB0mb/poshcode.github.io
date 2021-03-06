<#
Get-Command is a great stuff which can help you to locate almost any command or DLL.
But what if you want to find arbitrary file? For example, try to locate msconfig.exe
with Get-Command cmdlet:
PS> gcm -c Application msconfig.exe
And you'll get an error because Get-Command can not locate anything out of $env:path
or some special PowerShell's host directories. However, a way to find any file still
exists. Let's take a look at this.
#>

&{cmd /c dir /a-d /b /s %systemdrive%msconfig.exe}

<#
You can also use this trick when disk location of file is unknown. For example:
#>

[IO.DriveInfo]::GetDrives() | ? {$_.DriveType -eq 'Fixed'} | % {cmd /c dir /a-d /b /s ($_.Name + 'msconfig.exe')}
#is fater than next command
([IO.DriveInfo]::GetDrives() | ? {$_.DriveType -eq 'Fixed'} | % {gci $_.Name -r -i msconfig.exe -ea 0}).FullName

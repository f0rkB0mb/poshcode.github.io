<# 
    Set some Variables and start transcript.
    
    $MaximumHistoryCount is used to set the number of commands that are stored in History. Defaults to 64. Maximum 32767.
    $Transcript is used to set the path for Start-Transcript. I am logging everthing to my SkyDrive folder, using a file name like: username_computername-date.txt
    $env:PSModulePath is used to add custom location for modules.
    $cert is a variable I use to store my CodeSigningCert to sign scripts.

#>

New-Variable -Name Transcript -Scope Global
$MaximumHistoryCount = 1024

$Transcript = ${env:userprofile}+"\SkyDrive\powershell\"+${env:username}+"_"+${env:computername}+"-"+(get-date).toshortdatestring()+".txt" -replace "/","."
Start-Transcript -Append

$env:PSModulePath = $env:PSModulePath + ";\\fileserver\Scripts\PSMoules;C:\Users\thomas\SkyDrive\scripts\Modules"
$cert = Get-ChildItem Cert:\CurrentUser\my -CodeSigningCert | Where-Object {$_.subject -like "*thomas*"}


# If running PowerShell v3 set default parameter values
if ((Get-Host | Select-Object -ExpandProperty Version).Major -ge 3) {
    $PSDefaultParameterValues = @{
        "Send-MailMessage:From" = "thomas.torggler@ntsystems.it"
        "Send-MailMessage:SmtpServer" = "mymailserver.ntsystems.local"
    }
    # If current session has admin privileges, update powershell help files
    if(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Write-Host -ForegroundColor Yellow "You are Admin! Updating help..." 
        Update-Help -UICulture en-us
    } 
}

# Just a little tool to sign a file and update my module
function Update-TAK {
    # sign module file with CodeSigning certificate from cert:\currentuser\my
    Set-AuthenticodeSignature -FilePath 'C:\Users\thomas\SkyDrive\scripts\Modules\TAK\tak.psm1' -Certificate $Cert
    # update the module files on a network share
    copy-item c:\users\thomas\skydrive\scripts\tak\* \\fileserver\Scripts\PSMoules\tak
}

# Just a reminder, in case I forget the name of my Module :)
Write-Host -ForegroundColor Yellow .
Write-Host -ForegroundColor Yellow "Type: 'Import-Module TAK' to load Toms Admin toolKit"
Write-Host -ForegroundColor Yellow .

# Create a new PSDrive where all my scripts are located. And change location to that drive...
New-PSDrive -name X -PSProvider FileSystem -root ${env:userprofile}"\SkyDrive\scripts" | Out-Null
Set-Location X:

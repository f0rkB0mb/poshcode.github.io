﻿<#
.SYNOPSIS
Uses plink to run an ssh remote command.

.DESCRIPTION
Runs a remote command against an ssh server, instead of typing commands in an interactive session. The function returns a custom object with the command that was run and the output that was produced by that command.

.EXAMPLE
Run-SSHCommand -Plink C:\plink.exe -PrivateKey C:\Key.ppk -Server 192.186.0.1

Command                                                     Output
-------                                                     ------
ls /                                                        {.snap, COPYRIGHT, LICENSE.html, LICENSE.txt...}


The command runs the default command against the server 192.186.0.1

.EXAMPLE
Run-SSHCommand -Plink C:\plink.exe -PrivateKey C:\Key.ppk -Server 192.186.0.1 -Command 'mkdir /foo'

Command                                                     Output
-------                                                     ------
mkdir /foo                                                        


The command runs command 'mkdir /foo' which will make a directory named foo at the root of the file system. No output is generated by the command.

.EXAMPLE
'ls /', 'ls /ifs' | Run-SSHCommand -Plink C:\plink.exe -Key C:\Key.ppk -Node 192.186.0.1

Command                                                     Output
-------                                                     ------
ls /                                                        {.snap, COPYRIGHT, LICENSE.html, LICENSE.txt...}
ls /ifs                                                     {.ifsvar, .object, .snapshot, Data, FolderXY...}


The command takes input from the pipeline to process each command separately.

.EXAMPLE
Run-SSHCommand -Plink C:\plink.exe -PrivateKey C:\Key.ppk -Server 192.186.0.1 | Select-Object -ExpandProperty Output
COPYRIGHT
LICENSE.html
LICENSE.txt
bin
boot
compadmin
dev
etc
ifs
lib
libexec
media
mnt
proc
rescue
root
sbin
tmp
usr
var


The default command lists everything in the root of the file system. Then the output is piped to Select-Object where the output property is expanded.

.LINK
http://vikingtown.se/storage-scripting/?p=1
http://the.earth.li/~sgtatham/putty/0.62/htmldoc/Chapter7.html#plink

.NOTES
To setup plink with ssh server you need a public and private key. To generate a public and private key you should download Puttygen.
1.	Run PuTTY Key Generator
2.	Save the Private Key somewhere safe. Should be a “.ppk” file. Anyone with this key can login as root.
3.	Copy the contents from “Public Key for pasting into Open SSH authorized_keys file” into a text file named “authorized_keys” without an extension.
4.	Save that “authorized_keys” file to “/root/.ssh” on the ssh server.
5.	Save that file to each node you want to connect to.

#>
[cmdletbinding()]
param(
    #Path to plink.exe.
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateScript({(Test-Path -LiteralPath $_ -PathType Leaf) -and ($_ -like '*plink.exe')})]
    [string]$Plink,

    #Path to the private key used to connect to the node. Make sure the server has the correct public key.
    [Parameter(Mandatory=$true, Position=1)]
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})]
    [Alias('Key')]
    [string]$PrivateKey,

    #The IP address of the node you want to connect to.
    [Parameter(Mandatory=$true, Position=2)]
    [ValidateScript({[System.Net.IPAddress]::tryparse($_, [ref]([System.Net.IPAddress]::parse($_)))})]
    [Alias('ComputerName','Node')]
    [string]$Server,

    #The user name you want to connect with.
    [ValidateNotNullOrEmpty()]
    [string]$User = 'root',

    #The command(s) you want to run on the server.
    [Parameter(ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Command = 'ls /'  
)
begin{}
process{
    foreach($cmd in $Command){
        try{
            Write-Verbose "Running command $cmd"
            $Output = cmd /C "$Plink" -ssh -batch -i $PrivateKey $User@$Server $cmd 2> $null

            #The = will fail if cmd fails.

            #Why use catch throw if using $?
            if(!$?){
                if($Error[0].Exception.Message -like '*have no guarantee that the server is the computer you*'){
                    Write-Warning "$Server is untrusted. Login one time to $Server using an interactive session."
                    Write-Error "0: There was an error with the `"$cmd`" command because `"$($Error[0].Exception.Message)`""
                    break
                }
                else{
                    Write-Error "1: There was an error with the `"$cmd`" command because `"$($Error[0].Exception.Message)`""
                    continue
                }
            }
            else{
                Write-Output ([PSCustomObject]@{Command=$cmd;Output=$Output<#Invoke-Expression "$Plink -ssh -batch -i $PrivateKey $User@$Server $cmd" -ErrorAction Stop#>})
            }
        }
        catch{
            Write-Error "2: There was an error with the `"$cmd`" command because `"$($Error[0].Exception.Message)`""
        }
    }
}
end{}
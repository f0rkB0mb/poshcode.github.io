Function Get-HostsFile {
<#  
.SYNOPSIS  
   Retrieves the contents of a hosts file on a specified system
.DESCRIPTION
   Retrieves the contents of a hosts file on a specified system
.PARAMETER Computer
    Computer name to view host file from
.NOTES  
    Name: Get-HostsFile
    Author: Boe Prox
    DateCreated: 15Mar2011 
.LINK 
    http://boeprox.wordpress.com       
.EXAMPLE  
    Get-HostsFile "server1"

Description
-----------    
Retrieves the contents of the hosts file on 'server1'


#> 
[cmdletbinding(
	DefaultParameterSetName = 'Default',
	ConfirmImpact = 'low'
)]
    Param(
        [Parameter(
            ValueFromPipeline = $True)]
            [string[]]$Computer                                               
                        
        )
Begin {
    $psBoundParameters.GetEnumerator() | % {  
        Write-Verbose "Parameter: $_" 
        }
        If (!$PSBoundParameters['computer']) {
        Write-Verbose "No computer name given, using local computername"
        [string[]]$computer = $Env:Computername
        }
    $report = @()
    }
Process {
    Write-Verbose "Starting process of computers"
    ForEach ($c in $computer) {
        Write-Verbose "Testing connection of $c"
        If (Test-Connection -ComputerName $c -Quiet -Count 1) {
            Write-Verbose "Validating path to hosts file"
            If (Test-Path "\\$c\C$\Windows\system32\drivers\etc\hosts") {
                Switch -regex -file ("\\$c\c$\Windows\system32\drivers\etc\hosts") {
                    "^\d\w+" {
                        Write-Verbose "Adding IPV4 information to collection"
                        $temp = "" | Select Computer, IPV4, IPV6, Hostname, Notes
                        $new = $_.Split("") | ? {$_ -ne ""}
                        $temp.Computer = $c
                        $temp.IPV4 = $new[0]
                        $temp.HostName = $new[1]
                        If ($new[2] -eq $Null) {
                            $temp.Notes = $Null
                            }
                        Else {
                            $temp.Notes = $new[2]
                            }
                        $report += $temp
                        }
                    Default {
                        If (!("\s+" -match $_ -OR $_.StartsWith("#"))) {
                            Write-Verbose "Adding IPV6 information to collection"
                            $temp = "" | Select Computer, IPV4, IPV6, Hostname, Notes
                            $new = $_.Split("") | ? {$_ -ne ""}
                            $temp.Computer = $c
                            $temp.IPV6 = $new[0]
                            $temp.HostName = $new[1]
                            If ($new[2] -eq $Null) {
                                $temp.Notes = $Null
                                }
                            Else {
                                $temp.Notes = $new[2]
                                }
                            $report += $temp
                            }
                        }                        
                    }
                }#EndIF
            ElseIf (Test-Path "\\$c\C$\WinNT\system32\drivers\etc\hosts") {
                Switch -regex -file ("\\$c\c$\WinNT\system32\drivers\etc\hosts") {
                    "^#\w+" {
                        }
                    "^\d\w+" {
                        Write-Verbose "Adding IPV4 information to collection"
                        $temp = "" | Select Computer, IPV4,IPV6, Hostname, Notes
                        $new = $_.Split("") | ? {$_ -ne ""}
                        $temp.Computer = $c
                        $temp.IPV4 = $new[0]
                        $temp.HostName = $new[1]
                        If ($new[2] -eq $Null) {
                            $temp.Notes = $Null
                            }
                        Else {
                            $temp.Notes = $new[2]
                            }
                        $report += $temp
                        }
                    Default {
                        If (!("\s+" -match $_ -OR $_.StartsWith("#"))) {
                            Write-Verbose "Adding IPV6 information to collection"
                            $temp = "" | Select Computer, IPV4, IPV6, Hostname, Notes
                            $new = $_.Split("") | ? {$_ -ne ""}
                            $temp.Computer = $c
                            $temp.IPV6 = $new[0]
                            $temp.HostName = $new[1]
                            If ($new[2] -eq $Null) {
                                $temp.Notes = $Null
                                }
                            Else {
                                $temp.Notes = $new[2]
                                }
                            $report += $temp
                            }
                        }                        
                    }        
                }#End ElseIf
            Else {
                Write-Verbose "No host file found"
                $temp = "" | Select Computer, IPV4, IPV6, Hostname, Notes
                $temp.Computer = $c
                $temp.IPV4 = "NA"
                $temp.IPV6 = "NA"                
                $temp.Hostname = "NA"
                $temp.Notes = "Unable to locate host file"
                $report += $temp
                }#End Else
            }
        Else {
            Write-Verbose "No computer found"
            $temp = "" | Select Computer, IPV4, IPV6, Hostname, Notes
            $temp.Computer = $c
            $temp.IPV4 = "NA"
            $temp.IPV6 = "NA"            
            $temp.Hostname = "NA"
            $temp.Notes = "Unable to locate Computer"
            $report += $temp            
            }
        }
    }
End {
    Write-Output $report
    }
}

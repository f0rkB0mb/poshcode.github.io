function Get-SCCMUserComputer
{
    [CmdletBinding(DefaultParameterSetName="Identity")]
    [OutputType([PSObject])]
    Param
    (
        # Specify the SamAccountName for the User
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName="Identity")]
        [string[]]$identity,

        # Specify the Name ...ADSI will be used to find the Users matching the criteria
       [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName="Name")]
        [string]$Name,

        #specify the SCCMServer having SMS Namespace provider installed for the site. Default is the local machine.
        [Parameter(Mandatory=$false)]
        [Alias("SMSProvider")]
        [String]$SCCMServer=$env:COMPUTERNAME

    )

    Begin
    {
        #region open a CIM session
        $CIMSessionParams = @{
                    ComputerName = $SCCMServer
                    ErrorAction = 'Stop'
                    ErrorVariable = 'ProcessErrorCIM'
                }

        If ((Test-WSMan -ComputerName $SCCMServer -ErrorAction SilentlyContinue).ProductVersion -match 'Stack: 3.0')
        {
            Write-Verbose -Message "[BEGIN] WSMAN is responsive"
            $CimSession = New-CimSession @CIMSessionParams
            $CimProtocol = $CimSession.protocol
            Write-Verbose -Message "[BEGIN] [$CimProtocol] CIM SESSION - Opened"
        } 

        else 
        {
            Write-Verbose -Message "[PROCESS] Attempting to connect with protocol: DCOM"
            $CIMSessionParams.SessionOption = New-CimSessionOption -Protocol Dcom
            $CimSession = New-CimSession @CIMSessionParams
            $CimProtocol = $CimSession.protocol

            Write-Verbose -Message "[BEGIN] [$CimProtocol] CIM SESSION - Opened"
        }

        #endregion open a CIM session

        try
        {
           
            $sccmProvider = Get-CimInstance -query "select * from SMS_ProviderLocation where ProviderForLocalSite = true" -Namespace "root\sms" -CimSession $CimSession -ErrorAction Stop
            # Split up the namespace path
            $Splits = $sccmProvider.NamespacePath -split "\\", 4
            Write-Verbose "[BEGIN] Provider is located on $($sccmProvider.Machine) in namespace $($splits[3])"
 
            # Create a new hash to be passed on later
            $hash= @{"CimSession"=$CimSession;"NameSpace"=$Splits[3];"ErrorAction"="Stop"}
                                  
            
        }
        catch
        {
            Write-Warning "[BEGIN] $SCCMServer needs to have SMS Namespace Installed"
            throw $Error[0].Exception
        }
    }
    Process
    {
        Switch -exact ($PSCmdlet.ParameterSetName)
        {
            "Identity"
            {
                foreach ($id in $identity)
                {
                    $query = "Select NetbiosName from {0} where LastlogonUserName='{1}'" -f "SMS_R_System",$id
                    Get-CimInstance -Query $query @hash -PipelineVariable UserComputer | 
                        foreach -Process {
                                            [pscustomobject]@{
                                                                                                                            
                                                                SamAccountName = $id
                                                                ComputerName = $userComputer.netbiosname
                                                                }}
                                            
                }
            }
            
            "Name"
            {
                $adsisearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
                if ($Name -notmatch '\s+')
                {
                    $Name = "*$Name*" #Add wildcard * (asterix) if a single name is specified..will be a bit slow after this (ADSI search)
                }
                $adsisearcher.Filter ='(&(objectCategory=person)(objectClass=user)(name={0}))' -f $($($name -replace '\s+',' ')  -replace ' ','*')

                $users = $adsisearcher.FindAll() 
                if ($users.count -ne 0)
                {
                    if ($users.Count -ne 1)
                    {
                     $users = $users | select -ExpandProperty properties | 
                                foreach { [pscustomobject]@{Name=$_.name;SamAccountName=$_.samaccountname;Email=$_.mail;Title=$_.title;Location=$_.l} } |
                                    Out-GridView -OutputMode Single -Title "Select the User"
                    }
                    
                
                $query = "Select NetbiosName from {0} where LastlogonUserName='{1}'" -f "SMS_R_System",$($users.samaccountname)
                Get-CimInstance -Query $query @hash -PipelineVariable UserComputer | 
                    foreach -Process {
                                        [pscustomobject]@{
                                                            Name=$users.name
                                                            SamAccountName = $users.samaccountname
                                                            ComputerName = $userComputer.netbiosname
                                                            }}
                                    
                }
                else
                {
                    Write-Warning -Message "No Users could be found"
                }
            }
        }
    }
    End
    {
        Write-Verbose -Message "[END] Ending the Function"
    }
}

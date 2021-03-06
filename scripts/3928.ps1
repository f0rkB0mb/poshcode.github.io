# HelpModules 
#    A Module for generating module stubs so you can Update-Help (or Save-Help)
#    Includes two options for reading the help from those modules (StubFunctions or Get-ModuleHelp)
# 1.0 - 2013/2/1 - Initial release Friday, Feb 1st, 2013 
$PSModuleHelpRoot = Convert-Path "~\Documents\WindowsPowerShellModuleHelp"

function New-HelpModule {
  #.Synopsis
  #   Creates a dummy module and fetches the help files for it
  [CmdletBinding()]
  param(
    # The name of the module you want to create a dummy for.
    # TODO: currently works only for local modules
    # TODO: currently only handles one module at a time (you can pipe them)
    [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory=$true, Position=0)]
    [Alias("Name")]
    [String]$ModuleName,

    # A path to put the help modules in. Defaults to $PSModuleHelpRoot (which defaults to "~\Documents\WindowsPowerShellModuleHelp").
    [Parameter()]
    [String]$ModuleHelpRoot = $PSModuleHelpRoot,

    # If set, generates a Blank.psm1 with stub functions in it so that you can import the dummy module and use the built-in Get-Help instead of our Get-ModuleHelp
    #
    # Setting this may pollute your PowerShell session with dozens or hudreds of commands which don't do anything. You probably shouldn't, for instance, add your ModuleHelpRoot path to your PSModulePath if you do this.
    [Switch]$StubFunctions,

    # The culture you want to fetch help for (defaults to $PSUICulture)
    $HelpCulture = ${PSUICulture}
  )
  process {
    # Make the ModuleHelpRoot\ModuleName folder if it's not there
    $ModuleDir = mkdir ${ModuleHelpRoot}\${ModuleName}\ -Force 

    # Generate the stub ModuleManifest from an existing one
    # TODO: we need to do the Get-Module remotely on the server
    foreach($module in Get-Module $ModuleName -ListAvailable | Select Guid, HelpInfoUri, Version, ExportedCommands) {
      New-ModuleManifest -Path ${ModuleHelpRoot}\${ModuleName}\${ModuleName}.psd1 -Guid $module.Guid -HelpInfoUri $module.HelpInfoUri -ModuleVersion $module.Version -FunctionsToExport $module.ExportedCommands -RootModule "Blank.psm1"
    }

    # Update the help files -- this is why we're here.
    # TODO: if we're generating a lot of modules, it would be really to only do this once!
    PowerShell -NoProfile -Command "&{ `$Env:PSModulePath = '$ModuleHelpRoot'; Update-Help -Module '$ModuleName' -UICulture $HelpCulture}"

    # Generate stub FunctionsToExport
    if($StubFunctions) {
      foreach($file in Get-ChildItem ${ModuleHelpRoot}\${ModuleName}\${HelpCulture}\*.xml) {
        foreach($name in Select-Xml "//*[local-name() = 'details']/*[local-name() = 'name']" -Path $file | Select-Object -Expand Node | Select-Object -Expand "#text") {
          Add-Content "${ModuleHelpRoot}\${ModuleName}\Blank.psm1" ".ExternalHelp $($file.Name)`nfunction $name {}`n"
        }
      }
    }
  }
}

function Get-ModuleHelp {
  #.Synopsis
  #  Gets help from the XML help files directly without worrying about whether the commands actually exist.
  [CmdletBinding(DefaultParameterSetName="MamlCommandHelpInfo")]
  param(
    # The command you want help for
    [Alias("Name")]
    [Parameter(Mandatory=$true, Position = 0, ValueFromPipelineByPropertyName = $true)]
    $CommandName,
    # The name of the module the command is in
    # TODO: Search Get-Module -ListAvailable for modules which *say* they have the command
    [Parameter(Mandatory=$true, Position = 1, ValueFromPipelineByPropertyName = $true)]
    $ModuleName,

    # A path to search for help modules in. Defaults to $PSModuleHelpRoot (which defaults to "~\Documents\WindowsPowerShellModuleHelp").
    $ModuleHelpRoot = $PSModuleHelpRoot,

    # Displays only the detailed descriptions of the specified parameters. Wildcards are permitted.
    [Parameter(ParameterSetName="MamlCommandHelpInfo#parameter")]
    [String]$Parameter,

    # Displays only the name, synopsis, and examples".
    [Parameter(ParameterSetName="MamlCommandHelpInfo#ExamplesView")]
    [Switch]$Examples,

    # Displays the entire help topic for a cmdlet, including parameter descriptions and attributes, examples, input and output object types, and additional notes.
    [Parameter(ParameterSetName="MamlCommandHelpInfo#FullView")]
    [Switch]$Full,

    # Adds parameter descriptions and examples to the basic help display.
    [Parameter(ParameterSetName="MamlCommandHelpInfo#DetailedView")]
    [Switch]$Detailed,

    # The culture you want to fetch help for (defaults to $PSUICulture)
    $HelpCulture = ${PSUICulture}
  )
  process {
    Write-Verbose "Culture: $HelpCulture HelpSet: $($PSCmdlet.ParameterSetName)"
    $matched = $false
    foreach($node in Select-Xml "//*[local-name() = 'details']/*[local-name() = 'name' and text() = '$CommandName']/../.." -Path ${ModuleHelpRoot}\${ModuleName}\${PSUICulture}\*.xml | Select-Object -Expand Node) {
      if($Parameter) {
        foreach($param in $node.parameters.parameter) {
          if($param.name -like $Parameter) {
            $matched = $true
            $param | FixMaml -Type $($PSCmdlet.ParameterSetName)
          }
        }
        if(!$matched) {
          throw "No parameter matches criteria $Parameter" 
        }
      } else {
        $matched = $true
        $node | FixMaml -Type $($PSCmdlet.ParameterSetName)
      }
    }
  }
}

function FixMaml {
  #.Synopsis
  # Internal command for tweaking the XML just enough that PowerShell will format it properly
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline=$true)]
    $Node,

    [Parameter(Mandatory=$true)]
    $Type = "MamlCommandHelpInfo"
  )
  process {
    $node.PSTypeNames.Clear()
    $node.PSTypeNames.Add($type)       
    if($node.description) {
      Add-Member -Input $node NoteProperty description @(
        $Node.RemoveChild($node.description).para | % {
          $p = New-Object PSObject -Property @{ Text = $_ };
          $p.PSTypeNames.Clear(); 
          $p.PSTypeNames.Add("MamlParaTextItem"); 
          $p
        } )
    }
    if($node.details) {
      # Fix them, but don't output recursively
      $null = $node.details | FixMaml -Type $Type
    } 
    Write-Output $node   
  }
}

Export-ModuleMember -Function New-HelpModule, Get-ModuleHelp -Variable PSModuleHelpRoot
# SIG # Begin signature block
# MIIfIAYJKoZIhvcNAQcCoIIfETCCHw0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQ3oSz1in4p/LMkuRa71g9N9E
# ISSgghpSMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggRPMIIDuKADAgECAgQHJ1g9MA0GCSqGSIb3DQEBBQUAMHUxCzAJ
# BgNVBAYTAlVTMRgwFgYDVQQKEw9HVEUgQ29ycG9yYXRpb24xJzAlBgNVBAsTHkdU
# RSBDeWJlclRydXN0IFNvbHV0aW9ucywgSW5jLjEjMCEGA1UEAxMaR1RFIEN5YmVy
# VHJ1c3QgR2xvYmFsIFJvb3QwHhcNMTAwMTEzMTkyMDMyWhcNMTUwOTMwMTgxOTQ3
# WjBsMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQL
# ExB3d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJEaWdpQ2VydCBIaWdoIEFzc3Vy
# YW5jZSBFViBSb290IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# xszlc+b71LvlLS0ypt/lgT/JzSVJtnEqw9WUNGeiChywX2mmQLHEt7KP0JikqUFZ
# OtPclNY823Q4pErMTSWC90qlUxI47vNJbXGRfmO2q6Zfw6SE+E9iUb74xezbOJLj
# BuUIkQzEKEFV+8taiRV+ceg1v01yCT2+OjhQW3cxG42zxyRFmqesbQAUWgS3uhPr
# UQqYQUEiTmVhh4FBUKZ5XIneGUpX1S7mXRxTLH6YzRoGFqRoc9A0BBNcoXHTWnxV
# 215k4TeHMFYE5RG0KYAS8Xk5iKICEXwnZreIt3jyygqoOKsKZMK/Zl2VhMGhJR6H
# XRpQCyASzEG7bgtROLhLywIDAQABo4IBbzCCAWswEgYDVR0TAQH/BAgwBgEB/wIB
# ATBTBgNVHSAETDBKMEgGCSsGAQQBsT4BADA7MDkGCCsGAQUFBwIBFi1odHRwOi8v
# Y3liZXJ0cnVzdC5vbW5pcm9vdC5jb20vcmVwb3NpdG9yeS5jZm0wDgYDVR0PAQH/
# BAQDAgEGMIGJBgNVHSMEgYEwf6F5pHcwdTELMAkGA1UEBhMCVVMxGDAWBgNVBAoT
# D0dURSBDb3Jwb3JhdGlvbjEnMCUGA1UECxMeR1RFIEN5YmVyVHJ1c3QgU29sdXRp
# b25zLCBJbmMuMSMwIQYDVQQDExpHVEUgQ3liZXJUcnVzdCBHbG9iYWwgUm9vdIIC
# AaUwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL3d3dy5wdWJsaWMtdHJ1c3QuY29t
# L2NnaS1iaW4vQ1JMLzIwMTgvY2RwLmNybDAdBgNVHQ4EFgQUsT7DaQP4v0cB1Jgm
# GggC72NkK8MwDQYJKoZIhvcNAQEFBQADgYEALnaF2TeWba+J8wZ4gjHERgcfZcmO
# s8lUeObRQt91Lh5V6vf6mwTAdXvReTwF7HnEUt2mA9enUJk/BVnaxlX0hpwNZ6NJ
# BJUyHceH7IWvZG7VxV8Jp0B9FrpJDaL99t9VMGzXeMa5z1gpZBZMoyCBR7FEkoQW
# G29KvCHGCj3tM8owggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqG
# SIb3DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jw
# b3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNl
# cyBDQSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkG
# A1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQD
# EytTeW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIB
# IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEK
# U5OwmNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf
# 2Gi0jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQ
# DhfultthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6
# Anqhd5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrF
# xeozC9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQID
# AQABo4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcD
# CDAOBgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5o
# dHRwOi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6
# Ly90cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUw
# MzAxoC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcy
# LmNybDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAd
# BgNVHQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzM
# zHSa1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ij
# hCcHbxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebD
# Zw73BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmR
# DoDREfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2b
# W+IWyhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5
# Mysue7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzY
# BHUwggafMIIFh6ADAgECAhAOaQaYwhTIerW2BLkWPNGQMA0GCSqGSIb3DQEBBQUA
# MHMxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsT
# EHd3dy5kaWdpY2VydC5jb20xMjAwBgNVBAMTKURpZ2lDZXJ0IEhpZ2ggQXNzdXJh
# bmNlIENvZGUgU2lnbmluZyBDQS0xMB4XDTEyMDMyMDAwMDAwMFoXDTEzMDMyMjEy
# MDAwMFowbTELMAkGA1UEBhMCVVMxETAPBgNVBAgTCE5ldyBZb3JrMRcwFQYDVQQH
# Ew5XZXN0IEhlbnJpZXR0YTEYMBYGA1UEChMPSm9lbCBILiBCZW5uZXR0MRgwFgYD
# VQQDEw9Kb2VsIEguIEJlbm5ldHQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQDaiAYAbz13WMx9Em/Z3dTWUKxbyiTsaSOctgOfTMLUAurXWtY3k1XBVufX
# feL4pXQ7yQzm93YzvETwKdUCDJuOSu9EPYioy2nhKvBC6IaJUaw1VY7e9IsdxaxL
# 8js3RQilLk+FO4UHg9w7L8wdHgXaDoksysC2SlhbFq4AVl8XC4R+bq+pahsdMO3n
# Ab7Oo5PExKLVS8vl8QwOh6MaqquIjHmYoPOu9Rv8As0pnWsY9aVPs7T9QetXlW45
# +CKPhdUoEB1yD0kvGTIAQgn5W9VDYmfeVU40IIdt+7khWF10yu7zVT+/lauPzRmv
# CHZMfbmqVyVQqvp5dEu0/7EWbbcLAgMBAAGjggMzMIIDLzAfBgNVHSMEGDAWgBSX
# SAPrFQhrubJYI8yULvHGZdJkjjAdBgNVHQ4EFgQUmJxEqr9ewFZG4rNTp5NQIEIJ
# TrkwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMGkGA1UdHwRi
# MGAwLqAsoCqGKGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9oYS1jcy0yMDExYS5j
# cmwwLqAsoCqGKGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9oYS1jcy0yMDExYS5j
# cmwwggHEBgNVHSAEggG7MIIBtzCCAbMGCWCGSAGG/WwDATCCAaQwOgYIKwYBBQUH
# AgEWLmh0dHA6Ly93d3cuZGlnaWNlcnQuY29tL3NzbC1jcHMtcmVwb3NpdG9yeS5o
# dG0wggFkBggrBgEFBQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYAIAB0
# AGgAaQBzACAAQwBlAHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkAdAB1
# AHQAZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAARABp
# AGcAaQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAAUgBl
# AGwAeQBpAG4AZwAgAFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAAdwBo
# AGkAYwBoACAAbABpAG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4AZAAg
# AGEAcgBlACAAaQBuAGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkAbgAg
# AGIAeQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4wgYYGCCsGAQUFBwEBBHoweDAkBggr
# BgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFAGCCsGAQUFBzAChkRo
# dHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRIaWdoQXNzdXJhbmNl
# Q29kZVNpZ25pbmdDQS0xLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBBQUA
# A4IBAQAch95ik7Qm12L9Olwjp5ZAhhTYAs7zjtD3WMsTpaJTq7zA3q2QeqB46WzT
# vRINQr4LWtWhcopnQl5zaTV1i6Qo+TJ/epRE/KH9oLeEnRbBuN7t8rv0u31kfAk5
# Gl6wmvBrxPreXeossuU9ohij9uqIyk1lF85yW6QqDaE7rvIxpCXwMQv8PlQ/VdlK
# EXbNtq4frbvMQLkpcZljbJRuZYbY3SgfGv6rgbJ93Qw+1Tlq9Y4gsHRmw35uv5IJ
# VUrqcrNq5cyTgdeYodpftzKyqmZCIVvv8nu09DTfspAocJj9n5+XRqtEKIeKH9D/
# mjC/nVZIo+JpSuQG90nSYpUr4xwfMIIGvzCCBaegAwIBAgIQCBxX7l1w65ugsVIM
# cpwbCTANBgkqhkiG9w0BAQUFADBsMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSswKQYDVQQDEyJE
# aWdpQ2VydCBIaWdoIEFzc3VyYW5jZSBFViBSb290IENBMB4XDTExMDIxMDEyMDAw
# MFoXDTI2MDIxMDEyMDAwMFowczELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEyMDAGA1UEAxMpRGln
# aUNlcnQgSGlnaCBBc3N1cmFuY2UgQ29kZSBTaWduaW5nIENBLTEwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQDF+SPmlCfEgBSkgDJfQKONb3DA5TZxcTp1
# pKoakpSJXqwjcctOZ31BP6rjS7d7vp3BqDiPaS86JOl3WRLHZgRDwg0mgolAGfIs
# 6udM53wFGrj/iAlPJjfvOqT6ImyIyUobYfKuEF5vvNF5m1kYYOXuKbUDKqTO8YMZ
# T2kFcygJ+yIQkyKgkBkaTDHy0yvYhEOvPGP/mNsg0gkrVMHq/WqD5xCjEnH11tfh
# EnrV4FZazuoBW2hlW8E/WFIzqTVhTiLLgco2oxLLBtbPG00YfrmSuRLPQCbYmjaF
# sxWqR5OEawe7vNWz3iUAEYkAaMEpPOo+Le5Qq9ccMAZ4PKUQI2eRAgMBAAGjggNU
# MIIDUDAOBgNVHQ8BAf8EBAMCAQYwEwYDVR0lBAwwCgYIKwYBBQUHAwMwggHDBgNV
# HSAEggG6MIIBtjCCAbIGCGCGSAGG/WwDMIIBpDA6BggrBgEFBQcCARYuaHR0cDov
# L3d3dy5kaWdpY2VydC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5Lmh0bTCCAWQGCCsG
# AQUFBwICMIIBVh6CAVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMAIABD
# AGUAcgB0AGkAZgBpAGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMAIABh
# AGMAYwBlAHAAdABhAG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMAZQBy
# AHQAIABFAFYAIABDAFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkAbgBn
# ACAAUABhAHIAdAB5ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgAIABs
# AGkAbQBpAHQAIABsAGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUAIABp
# AG4AYwBvAHIAcABvAHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAAcgBl
# AGYAZQByAGUAbgBjAGUALjAPBgNVHRMBAf8EBTADAQH/MH8GCCsGAQUFBwEBBHMw
# cTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEkGCCsGAQUF
# BzAChj1odHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRIaWdoQXNz
# dXJhbmNlRVZSb290Q0EuY3J0MIGPBgNVHR8EgYcwgYQwQKA+oDyGOmh0dHA6Ly9j
# cmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEhpZ2hBc3N1cmFuY2VFVlJvb3RDQS5j
# cmwwQKA+oDyGOmh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEhpZ2hB
# c3N1cmFuY2VFVlJvb3RDQS5jcmwwHQYDVR0OBBYEFJdIA+sVCGu5slgjzJQu8cZl
# 0mSOMB8GA1UdIwQYMBaAFLE+w2kD+L9HAdSYJhoIAu9jZCvDMA0GCSqGSIb3DQEB
# BQUAA4IBAQCCBemFr6dMv6/OPbLqYLFo3mfC0ssm4MMvm7VrDlOQhfab4DUC//pp
# g6q0dDIUPC4QTCibCq0ICfnzhBGTj8tgQFbpdy9psoOZVatHJJbLf0uwELSXv8Sl
# mQb+juwUUB5eV5fLR7k02fw6ov9QKcIKYgTu3pY6b6DChQ9v/AjkMnvThK5pYAlG
# Jpzo8P//htnICTpmw6c2jxhP6LGWki5OvgunM5CuvG5P8X6NtEYOZPlZBiIhZABL
# 4noIA+e8iZCeQk8BwLYWf3XqRrKlVC+Mk80RNjRqKFfMlD/pfMgYAwMEfkPa+Zeh
# WUfaEqrgbTgAXTUrxSKGywbKvHpNPSZGMYIEODCCBDQCAQEwgYcwczELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTEyMDAGA1UEAxMpRGlnaUNlcnQgSGlnaCBBc3N1cmFuY2UgQ29kZSBT
# aWduaW5nIENBLTECEA5pBpjCFMh6tbYEuRY80ZAwCQYFKw4DAhoFAKB4MBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDv8
# tjyGeTlXeUzuInWGFRsehB1HMA0GCSqGSIb3DQEBAQUABIIBADwCIAseI2pZ6xNp
# RL8Wzglt6shQ4sR4zuivDf7r7I469V1Qgh/2VZouX1/cDSSBhhbs83t8wl2zaBK9
# t+p+OrbAAYy4CtEPv/T3rVa73KZ5I8DtJtLHoXYGLKJTfQhR1S1WKrIJEngw58LL
# l7uluY/dYJ5Q7B/Y9PeyAWZfiI91sF6jBZWPVqRR59jbrMIwr5l5/W1qP5ZfddNA
# 8zhHmR6vheN+QR1sbMV7XfKDGlw+y8qGFFkV+nOFSFVXeY92LG2S8+mc+u8TzBTw
# T075wfHHtIPfWMYVv2BfqgcVmS4Tl6goONzzmrez7syRqTV9/weSrF85wYgJ65T1
# g2y99e6hggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEwcjBeMQswCQYDVQQG
# EwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5
# bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVu
# BNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAc
# BgkqhkiG9w0BCQUxDxcNMTMwMjAxMjEzNDM5WjAjBgkqhkiG9w0BCQQxFgQUcNVz
# 4rFmgb088c80vaQqF6pfziUwDQYJKoZIhvcNAQEBBQAEggEASa/Q1iWBIoGakICZ
# zhhjvyXWMBWC4+L6rLMMiy5zGo+szfSodWldW5HRnHGRFARL8F3cm5GqnrAMk3Kh
# /HIV7r2JauM0FLcgYRfmQcYVqj/chsUp6tSSlIkDwnGT6E4IyT7ekS98UJ9BDq5q
# fa2+T/I7i8B0sHTZbG2fbwMiyA66sDNR3g9KPWxeT0qjlP8235XI31xglHi9ArKS
# qSDtiNmfHHK84Y3xlLPDdWTorWWsf4tsUTHvyjVST4aduc2NPuD3IvfgB1SWhdcl
# h/BEJTI2YO5ZzIWkSxbPZnFGwV9bX2zTk+alHlMoJr2Y4ySzMCN9hCZlblsHKJOz
# /gEGdQ==
# SIG # End signature block


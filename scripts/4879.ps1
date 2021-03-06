Function Get-FunctionParameters
{
    <#
        .SYNOPSIS
            Return all parameter elements from a function param() block.
       
           	Zachary Loeber
        	
        	THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE 
        	RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
        	
        	Version 1.1 - 01/27/2014
        .DESCRIPTION
            This function will return all the parameters defined in a param() portion of a
            script as well as any default values, variable type information, HelpMessage 
            text, ValidateSet items, and mandatory settings if present.
        .PARAMETER ScriptBlock
            A scriptblock containing a parameter set
        .EXAMPLE
            Get-FunctionParameter $Script
        .EXAMPLE
            $testscript = Get-Content 'SampleFunction.ps1' -Raw
            $scriptparams = get-functionparameters -ScriptBlock $testscript
        .NOTES
            Author: Zachary Loeber

            Version History:
            1.1 - 01/27/2014
                - Added ability to return mandatory info as well as validateset
                  values.
            1.0 - 05/31/2013
                - First release
        .LINK 
            http://www.the-little-things.net 
        .LINK
            http://nl.linkedin.com/in/zloeber
    #>
    [CmdletBinding()]
    param
    (
        [Parameter( Mandatory=$true,
                    ValueFromPipeline=$false,
                    HelpMessage="A scriptblock containing a parameter set.")]
        [String]$ScriptBlock
    )
    BEGIN
    {
        # Turn our string into a scriptblock
    	$ScriptBlock = [Scriptblock]::Create($ScriptBlock)
        $paramset = @()
        
        # Tokenize the script
        $tokens = [Management.Automation.PSParser]::Tokenize($ScriptBlock, [ref]$null) | 
                  Where {$_.Type -ne 'NewLine'}
    }
    PROCESS{}
    END
    {
        # First Pass - Grab all tokens between the first param block.
        $paramsearch = $false
        $groupstart = 0
        $groupend = 0
        for ($i = 0; $i -lt $tokens.Count; $i++) {
            if (!$paramsearch)
            {
                if ($tokens[$i].Content -eq "param" )
                {
                    $paramsearch = $true
                }
            }
            if ($paramsearch)
            {
                if (($tokens[$i].Type -eq "GroupStart") -and ($tokens[$i].Content -eq '(') )
                {
                    $groupstart++
                }
                if (($tokens[$i].Type -eq "GroupEnd") -and ($tokens[$i].Content -eq ')') )
                {
                    $groupend++
                }
                if (($groupstart -ge 1) -and ($groupstart -eq $groupend))
                {
                    $paramsearch = $false
                }
                $isparameter = $false
                $paramdatatype = ''
                $defaultvalue = ''
                if (($tokens[$i].Type -eq 'Variable') -and ($tokens[($i-1)].Content -ne '='))
                {
                    if ((($groupstart - $groupend) -eq 1))
                    {
                        $isparameter = $true
                    }
                }
                if ($isparameter)
                {
                    # if assigned, get the parameter default value
                    if (($tokens[($i+1)].Type -eq 'Operator') -and ($tokens[($i+1)].Content -eq '='))
                    {
                        $defaultvalue = $tokens[($i+2)].Content
                    }
                    
                    # Get the parameter data type
                    if (($tokens[($i-1)].Type -eq 'Type'))
                    {
                        $paramdatatype = $tokens[($i-1)].Content
                    }
                }
                $objprop = @{ 'Type' = $tokens[$i].Type;
                              'Content' = $tokens[$i].Content;
                              'IsParameter' = $isparameter;
                              'ParameterVariableType' = ($paramdatatype -replace '[^A-Za-z]','');
                              'ParamDefaultValue' = $defaultvalue;
                              'HelpMessage' = '';
                              'Mandatory' = $false;
                              'ValidateSet' = @();
                            }
                $newobj = New-Object PSObject -Property $objprop
                $paramset = $paramset + $newobj
            }
        }

        # Second Pass - Find all helpmessage and other parameter attributes
        #               associated with each parameter in the block
        $i=0
        Foreach ($param_item in $paramset)
        {
            if ($param_item.IsParameter)
            {
                # Once we find a parameter we essentially do a backward search
                # until we either hit another parameter or the beginning of the
                # entire param block.
                $lookforhelptext = $true
                $helpsearch = $i
                While ($lookforhelptext)
                {
                    $helpsearch--
                    if(($paramset[$helpsearch].IsParameter) -or 
                       (($paramset[$helpsearch].Type -eq 'Keyword') -and 
                        ($paramset[$helpsearch].Content -eq 'param')) -or 
                       ($helpsearch -eq 0))
                    {
                        $lookforhelptext = $false
                    }
                    # Get help message
                    elseif (($paramset[$helpsearch].Content -eq 'HelpMessage') -and 
                            ($paramset[$helpsearch].Type -eq 'Member'))
                    {
                        $param_item.HelpMessage = $paramset[($helpsearch+2)].Content
                    }
                    # Get mandatory state
                    elseif (($paramset[$helpsearch].Content -eq 'Mandatory') -and 
                            ($paramset[$helpsearch].Type -eq 'Member'))
                    {
                        $param_item.Mandatory = ($paramset[($helpsearch+2)].Content -eq 'true')
                    }
                    # Get our validateset items
                    elseif (($paramset[$helpsearch].Content -eq 'ValidateSet') -and 
                            ($paramset[$helpsearch].Type -eq 'Attribute'))
                    {
                        $foundallinset = $false
                        $vssetsearch = $helpsearch+2
                        do
                        {
                            if ($paramset[$vssetsearch].Type -ne 'Operator')
                            {
                                $param_item.ValidateSet += $paramset[$vssetsearch].Content
                            }
                            $vssetsearch++
                        } Until ($paramset[$vssetsearch].Type -eq 'GroupEnd')
                    }
                }
            }
            $i++
        }
        $paramset | where {($_.IsParameter)}
    }
}

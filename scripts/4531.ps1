Function Shuffle-String ([string]$String, [switch]$IgnoreSpaces, [switch]$IgnoreCRLF, [switch]$IgnoreWhitespace) {
##
## Simple enough, input a string or here-string, return it randomly shuffled, whitespace, carriage returns and all
## -IgnoreSpaces removes spaces from output
## -IgnoreCRLF removes Carriage Returns and LineFeeds from the output
## -IgnoreWhitespace removes spaces and tabs from the output


    If ($string.length -eq 0) 
    {
        Return
    }
    
    #Tab = [char]9
    
    If ($IgnoreWhiteSpace)
    {
        $String = $String.Replace([string][char]9,"")
        $IgnoreSpaces = $True
    }

    If ($IgnoreSpaces)
    {
        $String = $String.Replace(" ","")
    }

    #CR = [char]13
    #LF = [char]10

    If ($IgnoreCRLF)
    {
        $String = $String.Replace([string][char]10,"").Replace([string][char]13,"")
    }

    $Random = New-Object Random
    
    Return [string]::join("",($String.ToCharArray()|sort {$Random.Next()}))

}

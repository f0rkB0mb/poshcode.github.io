Function Compare-Even($num){ # Dependency for New-PassPhrase function
	[bool]!($num%2)
}

Function New-PIN{ 
#	.SYNOPSIS
#		Generate PIN numbers randomly.
#
#	.DESCRIPTION
#		This function can be used to generate PIN numbers of varying lengths.
#
#	.PARAMETER -Digits [<int>]
#			Specifies the number of words the passphrase should contain. Minimum value is 1.
#			
#			Required?					false
#			Position?					0
#			Default value				4
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#			
#	.PARAMETER -Generate [<int>]
#			Specifies the number of passphrases to generate. All passphrases generated will comply with the parameters set.
#			
#			Required?					false
#			Position?					null
#			Default value				1
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#		
#	.EXAMPLE
#		New-PIN
#	
#		Description
#		-----------
#		Generates a random PIN that is 4-digits long.
#
#	.EXAMPLE
#		New-PIN -Digits 6 -Generate 10
#
#		Description
#		-----------
#		Generates 10 PINs that are each 6-digits long.
#
#	.EXAMPLE
#		New-PIN -Generate 20
#
#		Description
#		-----------
#		Generates 20 PINs that are each 4-digits long.
#
#
#
	[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')] 
	param( 
		[parameter(Mandatory = $false, Position = 0)] 
		[ValidateRange(1,([int]::MaxValue))][int]$Digits = 4,
		[parameter(Mandatory = $false, Position = 1)]
		[ValidateRange(1,([int]::MaxValue))][int]$Generate = 1
	) 
	For($i=0;$i -lt $Generate;$i++){
		$NC = 0
		[string]$PIN = ""
		While($NC -lt $Digits){
			$PIN += Get-Random -Minimum 0 -Maximum 10
			$NC += 1
		} 
		Write-Host $PIN.Length "digits:  " -NoNewLine
		Write-Host $PIN
		Remove-Variable PIN
	}
}

Function New-Password{ 
#	.SYNOPSIS
#		Generate passphrases randomly.
#
#	.DESCRIPTION
#		This function can be used to generate passwords of varying lengths and complexities.
#
#		The user can specify the desired total password length as well as the character set to use. By default, the
#		'All' character set is used and includes upper case letters, lower case letters, numbers, and all
#		keyboard-printable symbols. A custom number of passwords to generate can also be specified.
#
#	.PARAMETER -Total [<int>]
#			Specifies the number of words the passphrase should contain. Minimum value is 1.
#			
#			Required?					false
#			Position?					0
#			Default value				16
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#			
#	.PARAMETER -CharacterSet [<string>]
#			Specifies the character set to use. Valid selections are: All, AlphaNumericMixed, AlphaNumericUpper,
#			AlphaNumericLower, AlphaSymbolMixed, AlphaSymbolUpper, AlphaSymbolLower, AlphaMixed, AlphaLower, AlphaUpper,
#			SymbolNumeric, and SymbolOnly. If not specified, the default is used.
#			
#			Required?					false
#			Position?					null
#			Default value				All
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#			
#	.PARAMETER -Generate [<int>]
#			Specifies the number of passphrases to generate. All passphrases generated will comply with the parameters set.
#			
#			Required?					false
#			Position?					null
#			Default value				1
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#		
#	.EXAMPLE
#		New-Password
#	
#		Description
#		-----------
#		Generates a random password using the default parameters
#
#	.EXAMPLE
#		New-Password -Total 8 -CharacterSet AlphaNumericUpper -Generate 6
#
#		Description
#		-----------
#		Generates 6 passwords that are each 8-characters long using only uppercase letters and numbers.
#
#	.EXAMPLE
#		New-Password -Generate 20
#
#		Description
#		-----------
#		Generates 20 passwords that are each 16-characters long using characters from all character sets.
#
#
#

	[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')] 
	param( 
		[parameter(Mandatory = $false, Position = 0)] 
		[ValidateRange(1,([int]::MaxValue))][int]$Total = 16,
		[ValidateSet("All","AlphaNumericMixed","AlphaNumericUpper","AlphaNumericLower","AlphaSymbolMixed","AlphaSymbolUpper","AlphaSymbolLower","AlphaMixed","AlphaLower","AlphaUpper","SymbolNumeric","SymbolOnly")][string]$CharacterSet = "All",
		[parameter(Mandatory = $false, Position = 1)]
		[ValidateRange(1,([int]::MaxValue))][int]$Generate = 1
	) 
	Process{ 
		For($i=0;$i -lt $Generate;$i++){
			[string]$Passwd = ''
			$UC = $NULL;For($a=65;$a -le 90;$a++){$UC+=,[char][byte]$a}
			$LC = $NULL;For($a=97;$a -le 122;$a++){$LC+=,[char][byte]$a}
			$NU = $NULL;For($a=48;$a -le 57;$a++){$NU+=,[char][byte]$a}
			$SY = ("!","@","#","$","%","^","&","*","(",")","{","}","[","]","\","|","/","?","<",">",",",".","-","+","_","=",";",":")
			If($CharacterSet -eq "All"){
				$BaseSet = $UC + $LC + $NU + $SY}
			elseIf($CharacterSet -eq "AlphaNumericMixed"){
				$BaseSet = $UC + $LC + $NU}
			elseIf($CharacterSet -eq "AlphaNumericUpper"){
				$BaseSet = $UC + $NU}
			elseIf($CharacterSet -eq "AlphaNumericLower"){
				$BaseSet = $LC + $NU}
			elseIf($CharacterSet -eq "AlphaSymbolMixed"){
				$BaseSet = $UC + $LC + $SY}
			elseIf($CharacterSet -eq "AlphaSymbolUpper"){
				$BaseSet = $UC + $SY}
			elseIf($CharacterSet -eq "AlphaSymbolLower"){
				$BaseSet = $LC + $SY}
			elseIf($CharacterSet -eq "AlphaMixed"){
				$BaseSet = $LC + $UC}
			elseIf($CharacterSet -eq "AlphaLower"){
				$BaseSet = $LC}
			elseIf($CharacterSet -eq "AlphaUpper"){
				$BaseSet = $UC}
			elseIf($CharacterSet -eq "SymbolNumeric"){
				$BaseSet = $SY + $NU}
			elseIf($CharacterSet -eq "SymbolOnly"){
				$BaseSet = $SY}
			For ($Loop=1;$Loop -le $Total;$Loop++) {
				$Passwd += Get-Random -Input $($BaseSet)
			} 
			Write-Host $Passwd.Length "char:  " -NoNewLine
			Write-Host $Passwd
			Remove-Variable Passwd
		}
	}
}

Function New-PassPhrase{ 
#	.SYNOPSIS
#		Generate passphrases randomly.
#
#	.DESCRIPTION
#		This function can be used to generate passphrases of varying lengths and complexities. The function was created
#		based on the passphrase generator at http://xkpasswd.net/s and attempts to emulate all of its functionality.
#	
#		The function is set with default parameters but is highly configurable. The function utilizes a user-provided
#		word file in CSV format with the header 'Word'. Any word list can be used.
#
#	.PARAMETER -Words [<int>]
#			Specifies the number of words the passphrase should contain. Minimum value is 1.
#			
#			Required?					false
#			Position?					0
#			Default value				4
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#			
#	.PARAMETER -WordLength [<int>]
#			Specifies the length of the words used in the passphrase. If not set, random word lengths are used for each word
#			in the passphrase. Minimum and maximum word length is dependent upon the word list used. Recommendation is that
#			the word list used does not contain words with fewer than 4 letters.
#			
#			Required?					false
#			Position?					1
#			Default value				null
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#			
#	.PARAMETER -NumbersBefore [<int>]
#			Specifies the number of random digits to place at the beginning of the passphrase.
#			
#			Required?					false
#			Position?					2
#			Default value				0
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#			
#	.PARAMETER -NumbersAfter [<int>]
#			Specifies the number of random digits to place at the end of the passphrase.
#			
#			Required?					false
#			Position?					3
#			Default value				4
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#			
#	.PARAMETER -SymbolsBefore [<int>]
#			Specifies the number of symbols to place at the beginning of the passphrase.
#			
#			Required?					false
#			Position?					4
#			Default value				0
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#			
#	.PARAMETER -SymbolsAfter [<int>]
#			Specifies the number of symbols to place at the end of the passphrase.
#			
#			Required?					false
#			Position?					5
#			Default value				0
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#			
#	.PARAMETER -PadTo [<int>]
#			Specifies the number of padding symbols to place at the end of the passphrase. If no padding symbol is specified with the
#			-PadSymbol parameter, a random symbol from keyboard-printable characters will be chosen.
#			
#			Required?					false
#			Position?					6
#			Default value				0
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#			
#	.PARAMETER -Case [<string>]
#			Specifies the case of the words in the passphrase. Valid selections are:  Alternating, InvertTitleCase, LowerCase, Random,
#			TitleCase, and UpperCase
#			
#			Required?					false
#			Position?					7
#			Default value				Alternating
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#			
#	.PARAMETER -Separator [<string>]
#			Specifies the separator symbol to use in the passphrase. All keyboard-printable characters, space, and null are valid.
#			If not set, a random symbol from non-null keyboard-printable characters (including space) will be chosen as the separator.
#			
#			Required?					false
#			Position?					8
#			Default value				<Random Symbol>
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#			
#	.PARAMETER -PadSymbol [<string>]
#			Specifies the padding symbol to place at the end of the passphrase. Parameter is only used if the -PadTo parameter has
#			been specified. If the -PadTo parameter is specified but the -PadSymbol parameter is not specified, a random symbol
#			from non-null, non-space, keyboard-printable characters will be chosen as the padding symbol.
#			
#			Required?					false
#			Position?					9
#			Default value				<Random Symbol>
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#			
#	.PARAMETER -Generate [<int>]
#			Specifies the number of passphrases to generate. All passphrases generated will comply with the parameters set.
#			
#			Required?					false
#			Position?					10
#			Default value				1
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#		
#	.PARAMETER -RandomLen [<switch>]
#			Specifies random word length. If this switch is set, the WordLength parameter is ignored.
#			
#			Required?					false
#			Position?					11
#			Default value				false
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#		
#	.PARAMETER -MinLen [<int>]
#			Used with the RandomLen switch. Specifies the minimum length of the words used in the passphrase. If the RandomLen
#			switch is not set, this parameter does nothing.
#			
#			Required?					false
#			Position?					12
#			Default value				4
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#		
#	.PARAMETER -MaxLen [<int>]
#			Used with the RandomLen switch. Specifies the maximum length of the words used in the passphrase. If the RandomLen
#			switch is not set, this parameter does nothing.
#			
#			Required?					false
#			Position?					13
#			Default value				12
#			Accept pipeline input?		true
#			Accept wildcard characters?	false
#		
#	.EXAMPLE
#		New-PassPhrase
#	
#		Description
#		-----------
#		Generates a random passphrase using the default parameters
#
#	.EXAMPLE
#		New-PassPrase -Words 2 -WordLength 8 -SymbolsBefore 3 -Case Alternating -Generate 6
#
#		Description
#		-----------
#		Generates 6 passphrases with 2 random words that are each 8-characters long in alternating case. The passphrase will
#		also have 3 identical but randomly-selected symbols prepended to it.
#
#	.EXAMPLE
#		New-PassPhrase -Words 3 -WordLength 4 -PadTo 50 -PadSymbol "|"
#
#		Description
#		-----------
#		Generates a passphrase with 3 words that are each 4-characters long. The passphrase will be padded up to 50 characters
#		with the | (pipe) symbol appended at the end.
#
#	.EXAMPLE
#		New-PassPhrase -Words 4 -NumbersAfter 6 -Case Random -Separator "#" -Generate 20
#
#		Description
#		-----------
#		Generates 20 passphrases each with 4 words of random lengths and capitalization separated by the # (hash) symbol.
#		The passphrase will end with 6 random digits.
#
#	.EXAMPLE
#		New-PassPhrase -Words 2 -Case LowerCase -NumbersBefore 2 -NumbersAfter 2 -SymbolsBefore 2 -SymbolsAfter 2 -PadTo 100 -Generate 10
#
#		Description
#		-----------
#		Generates 10 passphrases with 2 random words of random length in all lowercase. The passphrases will be prepended
#		by 2 random digits and 2 random symbols. The passphrases will also be appended with 2 random digits and 2 random
#		symbols. The passphrases will be padded to 100 characters with a random symbol.
#
#	.EXAMPLE
#		New-PassPhrase 3 8 0 4 0 2 50 Alternating "+" "%" 5
#
#		Description
#		-----------
#		Generates 5 passphrases with 3 words that are each 8-characters long and are in alternating case separated by the
#		plus symbol. The passphrases will be appended with 4 random digits, 2 random symbols, and will also be padded to 50
#		characters with the % (percent) symbol.
#
#	.EXAMPLE
#		New-PassPhrase -Words 4 -RandomLen -MinLen 6 -MaxLen 10 -Generate 5
#
#		Description
#		-----------
#		Generates 5 passphrases with 4 words that are each between 6 and 10 characters long. A random separator character
#		will be selected and the pass phrase will be appended with 4 random digits--based on default settings.
#
#

[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')] 
param( 
	[parameter(Mandatory = $false, Position = 0)] 
	[ValidateRange(1,([int]::MaxValue))][int]$Words = 4,
	[parameter(Mandatory = $false, Position = 1)]
	[ValidateRange(1,([int]::MaxValue))][int]$WordLength = 0,
	[parameter(Mandatory = $false, Position = 2)] 
	[ValidateRange(0,([int]::MaxValue))][int]$NumbersBefore = 0,
	[parameter(Mandatory = $false, Position = 3)] 
	[ValidateRange(0,([int]::MaxValue))][int]$NumbersAfter = 4,
	[parameter(Mandatory = $false, Position = 4)] 
	[ValidateRange(0,([int]::MaxValue))][int]$SymbolsBefore = 0,
	[parameter(Mandatory = $false, Position = 5)] 
	[ValidateRange(0,([int]::MaxValue))][int]$SymbolsAfter = 0,
	[parameter(Mandatory = $false, Position = 6)] 
	[ValidateRange(0,([int]::MaxValue))][int]$PadTo = 0,
	[parameter(Mandatory = $false, Position = 7)]
	[ValidateSet("Alternating","InvertTitleCase","LowerCase","Random","TitleCase","UpperCase")][string]$Case = "Alternating",
	[parameter(Mandatory = $false, Position = 8)]
	[ValidateSet("~","!","@","#","$","%","^","&","*","-","_","=","+",";",":",",",".","\","|","/"," ","(",")","[","]","{","}","<",">","?",$null)]
	[string]$Separator = (Get-Random -Input ("~","!","@","#","$","%","^","&","*","-","_","=","+",";",":",",",".","|"," ")),
	[parameter(Mandatory = $false, Position = 9)]
	[ValidateSet("~","!","@","#","$","%","^","&","*","-","_","=","+",";",":",",",".","\","|","/"," ","(",")","[","]","{","}","<",">","?")]
	[string]$PadSymbol = (Get-Random -Input ("~","!","@","#","$","%","^","&","*","-","_","=","+",";",":",",",".","|")),
	[parameter(Mandatory = $false, Position = 10)]
	[ValidateRange(1,([int]::MaxValue))][int]$Generate = 1,
	[parameter(Mandatory = $false, Position = 11)]
	[switch]$RandomLen = $false,
	[parameter(Mandatory = $false, Position = 12)]
	[ValidateRange(4,([int]::MaxValue))][int]$MinLen = 4,
	[parameter(Mandatory = $false, Position = 13)]
	[ValidateScript({
		if($_ -lt $MinLen){
			throw 'MaxLen value cannot be less than MinLen value.'
		} $true
	})][int]$MaxLen = 8
) 

	If ($WordLength -ne 0){
		$PList = (Import-CSV $PasswdList.Location | Where { $_.Word.Length -eq $WordLength})
	}else{
		$PList = (Import-CSV $PasswdList.Location)
	}
	
	If ($RandomLen -eq $true){
		$PList = (Import-CSV $PasswdList.Location | Where { $_.Word.Length -ge $MinLen -AND $_.Word.Length -le $MaxLen})
	}


	For($i=0;$i -lt $Generate;$i++){

		$bSY = 0
		While($bSY -lt $SymbolsBefore){
			[string]$Word += $PadSymbol
			$bSY += 1
		}

		$bNC = 0
		While($bNC -lt $NumbersBefore){
			[string]$Word += Get-Random -Minimum 0 -Maximum 10
			If($bNC -eq ($NumbersBefore - 1) -AND $bNC -gt 0){
				[string]$Word += $Separator
			}
			$bNC += 1
		} 

		$WC = 0
		While($WC -lt $Words){

		$WordLength =  Get-Random -Minimum $MinLen -Maximum ($MaxLen+1)
		
			If($Case -eq "Random"){
				$Rand = (Get-Random -Minimum 0 -Maximum 100)
		
				If((Compare-Even $Rand) -eq $True){ 
					[string]$Word += ($(Get-Random -Input $PList).Word).ToUpper()
					$WC += 1
				}elseIf((Compare-Even $Rand) -eq $False){
					[string]$Word += ($(Get-Random -Input $PList).Word).ToLower()
					$WC += 1
				}
				If($WC -ne $Words){
					[string]$Word += $Separator}

			}elseIf($Case -eq "Alternating"){

				If((Compare-Even $WC) -eq $True){ 
					[string]$Word += ($(Get-Random -Input $PList).Word).ToUpper()
					$WC += 1
				}elseIf((Compare-Even $WC) -eq $False){
					[string]$Word += ($(Get-Random -Input $PList).Word).ToLower()
					$WC += 1
				}
				If($WC -ne $Words){
					[string]$Word += $Separator}
				
			}elseIf($Case -eq "LowerCase"){
					[string]$Word += ($(Get-Random -Input $PList).Word).ToLower()
					$WC += 1
				If($WC -ne $Words){
					[string]$Word += $Separator}
				
			}elseIf($Case -eq "UpperCase"){
					[string]$Word += ($(Get-Random -Input $PList).Word).ToUpper()
					$WC += 1
				If($WC -ne $Words){
					[string]$Word += $Separator}
			}elseIf($Case -eq "TitleCase"){
					[string]$Word += (Get-Culture).TextInfo.ToTitleCase($(Get-Random -Input $PList).Word)
					$WC += 1
				If($WC -ne $Words){
					[string]$word += $Separator}
			}elseIf($Case -eq "InvertTitleCase"){
					[string]$Word += -join (((Get-Culture).TextInfo.ToTitleCase(($(Get-Random -Input $PList).Word))).ToCharArray() | %{[char]([int][char]$_ -bxor 0x20)})
					$WC += 1
				If($WC -ne $Words){
					[string]$word += $Separator}
			}
		}

		$eNC = 0
		If($Words -eq 0){[string]$Word += ""}
		While($eNC -lt $NumbersAfter){
			If($eNC -eq 0){
				[string]$Word += $Separator}
			[string]$Word += Get-Random -Minimum 0 -Maximum 10
			$eNC += 1
		}

		$eSY = 0
		While($eSY -lt $SymbolsAfter){
			[string]$Word += $PadSymbol
			$eSY += 1
		}
		
		$Pad = 0
		$WL = 0
		[int]$WL = $Word.length
		If($WL -lt $PadTo){
			$Pad = ($PadTo - $WL)
		}
		While($WL -lt $PadTo){
			[string]$Word += $PadSymbol
			[int]$WL = $Word.length
		}

		Write-Host $Word.Length "char:  " -NoNewLine
		Write-Host $Word
		Remove-Variable Word
		
		If($Generate -gt 1){
			If(!$PSBoundParameters.ContainsKey('Separator')){
				[string]$Separator = (Get-Random -Input ("~","!","@","#","$","%","^","&","*","-","_","=","+",";",":",",",".","|"," "))
			}
			If(!$PSBoundParameters.ContainsKey('PadSymbol')){
				[string]$PadSymbol = (Get-Random -Input ("~","!","@","#","$","%","^","&","*","-","_","=","+",";",":",",",".","|"))
			}
		}
	}
}



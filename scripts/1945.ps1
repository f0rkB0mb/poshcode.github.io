function global:GET-NewPassword($PasswordLength, $Complexity) {

<#

.SYNOPSIS 
Generates a New password with varying length and Complexity, 

.DESCRIPTION 
Generate a New Password for a User.  Defaults to 8 Characters
with Moderate Complexity.  Usage

GET-NEWPASSWORD or

GET-NEWPASSWORD $Length $Complexity

Where $Length is an integer from 1 to as high as you want
and $Complexity is an Integer from 1 to 4

.EXAMPLE 
Create New Password

GET-NEWPASSWORD

.EXAMPLE 
Generate a Password of strictly Uppercase letters that is 9 letters long

GET-NEWPASSWORD 9 1

.EXAMPLE 
Generate a Highly Complex password 5 letters long 

GET-NEWPASSWORD 5

.EXAMPLE 
Create a new 8 Character Password of Uppercase/Lowercase and store
as a Secure.String in Variable called $MYPASSWORD

$MYPASSWORD=CONVERTTO-SECURESTRING (GET-NEWPASSWORD 8 2) -asplaintext -force

.NOTES 
The Complexity falls into the following setup for the Complexity level
1 - Pure lowercase Ascii
2 - Mix Uppercase and Lowercase Ascii
3 - Ascii Upper/Lower with Numbers
4 - Ascii Upper/Lower with Numbers and Punctuation

#>

# Delare an array holding what I need.  Here is the format
# The first number is a the number of characters (Ie 26 for the alphabet)
# The Second Number is WHERE it resides in the Ascii Character set
# So 26,97 will pick a random number representing a letter in Asciii
# and add it to 97 to produce the ASCII Character
#
[int32[]]$ArrayofAscii=26,97,26,65,10,48,15,33

# Complexity can be from 1 - 4 with the results being
# 1 - Pure lowercase Ascii
# 2 - Mix Uppercase and Lowercase Ascii
# 3 - Ascii Upper/Lower with Numbers
# 4 - Ascii Upper/Lower with Numbers and Punctuation
If ($Complexity -eq $NULL) { $Complexity=3 }

# Password Length can be from 1 to as Crazy as you want
# 
If ($PasswordLength -eq $NULL) {$PasswordLength=10}

# Nullify the Variable holding the password
$NewPassword=$NULL


# Here is our loop
Foreach ($counter in 1..$PasswordLength) {

# What we do here is pick a random pair (4 possible)
# in the array to generate out random letters / numbers

$pickSet=(GET-Random $complexity)*2

# Pick an Ascii Character and add it to the Password
# Here is the original line I was testing with 
# [char] (GET-RANDOM 26) +97 Which generates
# Random Lowercase ASCII Characters
# [char] (GET-RANDOM 26) +65 Which generates
# Random Uppercase ASCII Characters
# [char] (GET-RANDOM 10) +48 Which generates
# Random Numeric ASCII Characters
# [char] (GET-RANDOM 15) +33 Which generates
# Random Punctuation ASCII Characters

$NewPassword=$NewPassword+[char]((get-random $ArrayOfAscii[$pickset])+$ArrayOfAscii[$pickset+1])
}

# When we're done we Return the $NewPassword 
# BACK to the calling Party
Return $NewPassword

}


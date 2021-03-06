Function Get-WindowsProduct
{
	function DecodeDigitalPID($digitalProductId)
	{
		New-Variable -Name base24 -Value 'BCDFGHJKMPQRTVWXY2346789' -Option Constant
		New-Variable -Name cryptedStringLength -Value 24 -Option Constant
		New-Variable -Name decryptionLength -Value 14 -Option Constant
		New-Variable -Name decryptedKey -Value ([System.String]::Empty)

		$containsN = ($digitalProductId[$decryptionLength] -shr 3) -bAnd 1
		$digitalProductId[$decryptionLength] = [System.Byte]($digitalProductId[$decryptionLength] -bAnd 0xF7) ## 247

		for ($i = $cryptedStringLength; $i -ge 0; $i--)
		{
			$digitMapIndex = 0
			for ($j = $decryptionLength; $j -ge 0; $j--)
			{
				$digitMapIndex = [System.UInt16]($digitMapIndex -shl 8 -bXor $digitalProductId[$j])
				$digitalProductId[$j] = [System.Byte][System.Math]::Floor($digitMapIndex / $base24.Length)
				$digitMapIndex = [System.UInt16]($digitMapIndex % $base24.Length)
			}
			$decryptedKey = $decryptedKey.Insert(0, $base24[$digitMapIndex])
		}

		if ([System.Boolean]$containsN)
		{
			$firstCharIndex = 0
			for ($index = 0; $index -lt $cryptedStringLength; $index++)
			{
				if ($decryptedKey[0] -ne $base24[$index]) {continue}
				$firstCharIndex = $index
				break
			}
			$keyWithN = $decryptedKey
			$keyWithN = $keyWithN.Remove(0, 1)
			$keyWithN = $keyWithN.Substring(0, $firstCharIndex) + 'N' + $keyWithN.Remove(0, $firstCharIndex)
			$decryptedKey = $keyWithN;
		}

		$returnValue = $decryptedKey
		for ($t = 20; $t -ge 5; $t -= 5)
		{
			$returnValue = $returnValue.Insert($t, '-')
		}

		return $returnValue
	} ## end DecodeDigitalPID

	$regPath = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion'
	$binArray = $(Get-ItemProperty -Path $regPath).DigitalProductId[52..66]
	$preObject = @{
		ProductKey = DecodeDigitalPID($binArray)
		ProductID  = $(Get-ItemProperty -Path $regPath).ProductId;
		Edition    = $(Get-ItemProperty -Path $regPath).EditionID;
		Type       = 'x86';
		Version    = [System.Environment]::OSVersion.VersionString;
	}
	if ([System.Environment]::Is64BitOperatingSystem) {$preObject.Type += '-64'}
	$object = New-Object -TypeName System.Management.Automation.PSObject -Property $preObject
	Write-Output $object | Select-Object Version, Edition, Type, ProductID, ProductKey
} ## End Get-WindowsProduct


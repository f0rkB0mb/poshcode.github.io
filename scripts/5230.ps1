<#

Use this like this:

"abc",([char]'x'),0xBF | Get-CharInfo

#>

Set-StrictMode -Version latest

if (Test-Path -LiteralPath "$([System.Environment]::SystemDirectory -replace '\\','\\')\\getuname.dll") {
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace Microsofts.CharMap {
	public class UName {
		[DllImport("$([System.Environment]::SystemDirectory -replace '\\','\\')\\getuname.dll", ExactSpelling=true, SetLastError=true)]
		private static extern int GetUName(ushort wCharCode, [MarshalAs(UnmanagedType.LPWStr)] System.Text.StringBuilder buf);

		public static string Get(char ch) {
			var sb = new System.Text.StringBuilder(300);
			UName.GetUName(ch, sb);
			return sb.ToString();
		}
	}
}
"@
} else {
Add-Type -TypeDefinition @"
using System;
namespace Microsofts.CharMap {
	public class UName {
		public static string Get(char ch) { return "???"; }
	}
}
"@
}

function Get-CharInfo {
	[CmdletBinding()]
	param(
		[Parameter(Position = 0, Mandatory, ValueFromPipeline)]
		$InputObject
	)
	begin {
		function out {
			param($ch)
			if (0 -gt $ch) { return }
			if (0xFFFF -ge $ch) {
				[pscustomobject]@{
					Char = [char]$ch
					CodePoint = 'U+{0:X4}' -f $ch
					Category = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
					Description = [Microsofts.CharMap.UName]::Get($ch)
				}
			} elseif (0x10FFFF -ge $ch) {
				$s = [char]::ConvertFromUtf32($ch)
				[pscustomobject]@{
					Char = $s
					CodePoint = 'U+{0:X}' -f $ch
					Category = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($s, 0)
					Description = '???'
				}
			}
		}
	}
	process {
		if ($InputObject -as [char]) {
			out ([int][char]$InputObject)
		} elseif ($InputObject -isnot [string] -and $InputObject -as [int]) {
			out ([int]$InputObject)
		} else {
			$InputObject = [string]$InputObject
			for ($i = 0; $i -lt $InputObject.Length; ++$i) {
				if ([char]::IsHighSurrogate($InputObject[$i]) -and (1+$i) -lt $InputObject.Length -and [char]::IsLowSurrogate($InputObject[$i+1])) {
					out ([char]::ConvertToUtf32($InputObject, $i))
					++$i
				} else {
					out ([int][char]$InputObject[$i])
				}
			}
		}
	}
}


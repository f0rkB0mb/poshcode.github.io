function Draw-Circle
{
param
(
		[int]$radius = 20,
		[string]$ForegroundColor = "Green",
		[string]$BackgroundColor = "Black"
)
	for ($RowNum = $radius; $RowNum -gt 0; $RowNum--)
	{
		#[int]$spaces=$radius+12/8*[System.Math]::Sqrt($radius*$radius-$rownum*$rownum)+$radius
		[int]$spaces = 12/8 * ($radius - [System.Math]::Sqrt($radius * $radius - $rownum * $rownum))
		[int]$spaces2 = 2 * 12/8 * [System.Math]::Sqrt($radius * $radius - $rownum * $rownum)
		for ($i = 0; $i -lt $spaces; $i++)
		{
			write-host " " -backgroundcolor $BackgroundColor -nonewline
		}
		Write-Host " " -BackgroundColor $ForegroundColor -nonewline
		for ($i = 0; $i -lt $spaces2; $i++)
		{
			write-host " " -backgroundcolor $BackgroundColor -nonewline
		}
		
		Write-Host " " -BackgroundColor $ForegroundColor -nonewline
		#Write-Host (2 *(12/8) *$radius - ($spaces + $spaces2)),$spaces,$spaces2 -NoNewline
		for ($i = 0; $i -lt (2 * (12/8) * $radius - ($spaces + $spaces2)); $i++)
		{
			write-host " " -backgroundcolor $BackgroundColor -nonewline
		}
		write-host " " -backgroundcolor $BackgroundColor
	}
	for ($RowNum=0;$RowNum -lt ($radius+1);$RowNum++)
{
		#[int]$spaces=$radius+12/8*[System.Math]::Sqrt($radius*$radius-$rownum*$rownum)+$radius
[int]$spaces = 12/8 * ($radius - [System.Math]::Sqrt($radius * $radius - $rownum * $rownum))
[int]$spaces2=2*12/8*[System.Math]::Sqrt($radius*$radius-$rownum*$rownum)
for ($i=0;$i -lt $spaces;$i++)
{
			write-host " " -backgroundcolor $BackgroundColor -nonewline
}
		Write-Host " " -BackgroundColor $ForegroundColor -nonewline
for ($i=0;$i -lt $spaces2;$i++)
{
			write-host " " -backgroundcolor $BackgroundColor -nonewline
}
		
		Write-Host " " -BackgroundColor $ForegroundColor -nonewline
		#Write-Host (2 *(12/8) *$radius - ($spaces + $spaces2)),$spaces,$spaces2 -NoNewline
for ($i = 0; $i -lt (2 *(12/8) *$radius - ($spaces + $spaces2)); $i++)
{
			write-host " " -backgroundcolor $BackgroundColor -nonewline
}
		write-host " " -backgroundcolor $BackgroundColor
}
}

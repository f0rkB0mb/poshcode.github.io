@@Import-Module "$PSScriptRoot\PSBGInfo.psm1" -Force #Script is useless to others without availability of this MODULE...


$BG = Write-PSBGILine -Text "This is a test"

Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Canvas
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Margin="10">
  <Grid> 
  <Grid.RowDefinitions>
    <RowDefinition Height="Auto" />
    <RowDefinition Height="Auto" />
  </Grid.RowDefinitions>
  <Grid.ColumnDefinitions>
    <ColumnDefinition Width="100"/>
    <ColumnDefinition Width="*" />
  </Grid.ColumnDefinitions>
    <!-- Boot Time -->
    <Label Grid.Row="0" Grid.Column="0" FontFamily="Arial" FontWeight="Bold" FontSize="12pt">Boot Time:</Label>
    <Label Name="BootTime" Grid.Row="0" Grid.Column="1" FontFamily="Arial" FontWeight="Bold" FontSize="12pt">[Boot Time]</Label>
    
    <!-- CPU -->
    <Label Grid.Row="1" Grid.Column="0" FontFamily="Arial" FontWeight="Bold" FontSize="12pt">CPU:</Label>
    <Label Name="CPU" Grid.Row="1" Grid.Column="1" FontFamily="Arial" FontWeight="Bold" FontSize="12pt">[CPU]</Label>
  </Grid>
</Canvas>
"@

$reader=New-Object System.Xml.XmlNodeReader ($xaml)
$Window=[Windows.Markup.XamlReader]::Load( $reader )


#$Window.Measure( (new-object System.Windows.Size($Window.Width, $Window.Height)) )
$
$Window.Arrange( (New-Object System.Windows.Rect(New-Object System.Windows.Size($Window.Width, $Window.Height))) )

#Connect to Control
$button = $Window.FindName("BootTime")

$rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap(`
    $Window.Width, $Window.Height, 96d, 96d, [System.Windows.Media.PixelFormats]::Default)

$rtb.Render($Window)


#endcode as PNG
$pngEncoder = New-object System.Windows.Media.Imaging.PngBitmapEncoder
$pngEncoder.Frames.Add( [System.Windows.Media.Imaging.BitmapFrame]::Create($rtb) )


#save to memory stream
$ms = New-Object System.IO.MemoryStream
$pngEncoder.Save($ms)
$ms.Close()
[System.IO.File]::WriteAllBytes("$PSScriptRoot\Image.png", $ms.ToArray())

#   pngEncoder.Save(ms);
#   ms.Close();
#   System.IO.File.WriteAllBytes("logo.png", ms.ToArray());
#   Console.WriteLine("Done");

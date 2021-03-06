#requires -version 2.0
$mnuOpen_Click= {
  (New-Object Windows.Forms.OpenFileDialog) | % {
    $_.Filter = "JPEG (*.jpg;*.jpeg)|*.jpg;*jpeg"
    $_.InitialDirectory = $pwd
    
    if ($_.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
      $img = [Drawing.Image]::FromFile($_.FileName)
      $pbImage.Image = $img
      $pbImage.SizeMode = [Windows.Forms.PictureBoxSizeMode]$tsCbo_1.SelectedItem
      $tsCbo_2.Enabled = $true
      $bmp = New-Object Drawing.Bitmap $img
      set def -val ($bmp.Clone()) -opt Constant
    }
  }
  $sbLabel.Text = ('Width: {0}{1}Height: {2}' -f $img.Width, (' ' * 3), $img.Height)
}

$tsCbo_2_SelectedIndexChanged= {
  switch ($tsCbo_2.SelectedIndex) {
    "0" {$pbImage.Image = $def}
    "1" {
      if ($ret -eq $null) {
        $ia = New-Object Drawing.Imaging.ImageAttributes
        $cm = New-Object Drawing.Imaging.ColorMatrix
        
        $cm.Matrix00 = $cm.Matrix01 = $cm.Matrix02 = $cm.Matrix10 = $cm.Matrix11 = `
        $cm.Matrix12 = $cm.Matrix20 = $cm.Matrix21 = $cm.Matrix22 = 1/3
        $ia.SetColorMatrix($cm)
        
        $gfx = [Drawing.Graphics]::FromImage($bmp)
        $gfx.DrawImage($bmp, (New-Object Drawing.Rectangle 0, 0, $bmp.Width, $bmp.Height), `
                          0, 0, $bmp.Width, $bmp.Height, [Drawing.GraphicsUnit]::Pixel, $ia)
        $gfx.Flush()
        
        $ret = $bmp.Clone()
        $pbImage.Image = $ret
      }
      else {$pbImage.Image = $ret}
    }
    "2" {
      $bmp = $def.Clone()
      if ($neg -eq $null) {
        for ($x = 0; $x -lt $bmp.Width; $x++) {
          for ($y = 0; $y -lt $bmp.Height; $y++) {
            [Drawing.Color]$col = $bmp.GetPixel($x, $y)
            $bmp.SetPixel($x, $y, [Drawing.Color]::FromArgb(
              (255 - $col.R), (255 - $col.G), (255 - $col.B)
            ))
          }
        }
        $neg = $bmp.Clone()
        $pbImage.Image = $neg
      }
      else {$pbImage.Image = $neg}
    }
  }
}

$tsBtn_1_Click= {
  if ($pbImage.Image -ne $null) {
    $pbImage.Image.RotateFlip([Drawing.RotateFlipType]::Rotate90FlipXY)
    $pbImage.Refresh()
  }
}

$tsBtn_2_Click= {
  if ($pbImage.Image -ne $null) {
    $pbImage.Image.RotateFlip([Drawing.RotateFlipType]::Rotate270FlipXY)
    $pbImage.Refresh()
  }
}

function frmMain_Show {
  Add-Type -Assembly System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()
  
  $ico = [Drawing.Icon]::ExtractAssociatedIcon(($PSHome + '\powershell.exe'))
  
  $frmMain = New-Object Windows.Forms.Form
  $mnuMain = New-Object Windows.Forms.MenuStrip
  $mnuFile = New-Object Windows.Forms.ToolStripMenuItem
  $mnuOpen = New-Object Windows.Forms.ToolStripMenuItem
  $mnuExit = New-Object Windows.Forms.ToolStripMenuItem
  $mnuHelp = New-Object Windows.Forms.ToolStripMenuItem
  $mnuInfo = New-Object Windows.Forms.ToolStripMenuItem
  $tsStrip = New-Object Windows.Forms.ToolStrip
  $tsLbl_1 = New-Object Windows.Forms.ToolStripLabel
  $tsLbl_2 = New-Object Windows.Forms.ToolStripLabel
  $tsLbl_3 = New-Object Windows.Forms.ToolStripLabel
  $tsCbo_1 = New-Object Windows.Forms.ToolStripComboBox
  $tsCbo_2 = New-Object Windows.Forms.ToolStripComboBox
  $tsBtn_1 = New-Object Windows.Forms.ToolStripButton
  $tsBtn_2 = New-Object Windows.Forms.ToolStripButton
  $pbImage = New-Object Windows.Forms.PictureBox
  $sbStrip = New-Object Windows.Forms.StatusStrip
  $sbLabel = New-Object Windows.Forms.ToolStripStatusLabel
  #
  #common
  #
  $mnuMain.Items.AddRange(@($mnuFile, $mnuHelp))
  $tsStrip.Items.AddRange(@($tsLbl_1, $tsCbo_1, $tsLbl_2, $tsCbo_2, $tsLbl_3, $tsBtn_1, $tsBtn_2))
  $tsLbl_1.Text = "Mode:"
  $tsLbl_2.Text = "Style:"
  $tsLbl_3.Text = "Rotation:"
  $pbImage.Dock = "Fill"
  $sbLabel.AutoSize = $true
  #
  #mnuFile
  #
  $mnuFile.DropDownItems.AddRange(@($mnuOpen, $mnuExit))
  $mnuFile.Text = "&File"
  #
  #mnuOpen
  #
  $mnuOpen.ShortcutKeys = "Control", "O"
  $mnuOpen.Text = "&Open..."
  $mnuOpen.Add_Click($mnuOpen_Click)
  #
  #mnuExit
  #
  $mnuExit.ShortcutKeys = "Control", "X"
  $mnuExit.Text = "E&xit"
  $mnuExit.Add_Click({$frmMain.Close()})
  #
  #mnuHelp
  #
  $mnuHelp.DropDownItems.AddRange(@($mnuInfo))
  $mnuHelp.Text = "&Help"
  #
  #mnuInfo
  #
  $mnuInfo.Text = "About..."
  $mnuInfo.Add_Click({frmInfo_Show})
  #
  #tsCbo_1
  #
  [Enum]::GetValues([Windows.Forms.PictureBoxSizeMode]) | % {
    [void]$tsCbo_1.Items.Add($_)
  }
  $tsCbo_1.SelectedIndex = 4
  $tsCbo_1.Add_SelectedIndexChanged({$pbImage.SizeMode = [Windows.Forms.PictureBoxSizeMode]$tsCbo_1.SelectedItem})
  #
  #tsCbo_2
  #
  $tsCbo_2.Enabled = $false
  $tsCbo_2.Items.AddRange(@('Normal', 'Retro', 'Negative'))
  $tsCbo_2.SelectedIndex = 0
  $tsCbo_2.Add_SelectedIndexChanged($tsCbo_2_SelectedIndexChanged)
  #
  #tsBtn_1
  #
  $tsBtn_1.Text = "Left"
  $tsBtn_1.Add_Click($tsBtn_1_Click)
  #
  #tsBtn_2
  #
  $tsBtn_2.Text = "Right"
  $tsBtn_2.Add_Click($tsBtn_2_Click)
  #
  #sbStrip
  #
  $sbStrip.Items.AddRange(@($sbLabel))
  $sbStrip.SizingGrip = $false
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(800, 547)
  $frmMain.Controls.AddRange(@($pbImage, $sbStrip, $tsStrip, $mnuMain))
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.Icon = $ico
  $frmMain.MainMenuStrip = $mnuMain
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "ImageView"
  $frmMain.Add_Load({$sbLabel.Text = "Ready"})
  
  [void]$frmMain.ShowDialog()
}

function frmInfo_Show {
  #Please donate if you like my scripts
  #Yandex.Money - 410012070594869
  $frmInfo = New-Object Windows.Forms.Form
  $pbImage = New-Object Windows.Forms.PictureBox
  $lblName = New-Object Windows.Forms.Label
  $lblCopy = New-Object Windows.Forms.Label
  $btnExit = New-Object Windows.Forms.Button
  #
  #pbImage
  #
  $pbImage.Image = $ico.ToBitmap()
  $pbImage.Location = New-Object Drawing.Point(16, 16)
  $pbImage.Size = New-Object Drawing.Size(32, 32)
  $pbImage.SizeMode = "StretchImage"
  #
  #lblName
  #
  $lblName.Font = New-Object Drawing.Font("Microsoft Sans Serif", 9, [Drawing.FontStyle]::Bold)
  $lblName.Location = New-Object Drawing.Point(53, 19)
  $lblName.Size = New-Object Drawing.Size(360, 18)
  $lblName.Text = "Image View Demo"
  #
  #lblCopy
  #
  $lblCopy.Location = New-Object Drawing.Point(67, 37)
  $lblCopy.Size = New-Object Drawing.Size(360, 23)
  $lblCopy.Text = "(C) 2013 greg zakharov forum.script-coding.com"
  #
  #btnExit
  #
  $btnExit.Location = New-Object Drawing.Point(135, 67)
  $btnExit.Text = "OK"
  #
  #frmInfo
  #
  $frmInfo.AcceptButton = $btnExit
  $frmInfo.CancelButton = $btnExit
  $frmInfo.ClientSize = New-Object Drawing.Size(350, 110)
  $frmInfo.ControlBox = $false
  $frmInfo.Controls.AddRange(@($pbImage, $lblName, $lblCopy, $btnExit))
  $frmInfo.FormBorderStyle = "FixedSingle"
  $frmInfo.ShowInTaskBar = $false
  $frmInfo.StartPosition = "CenterParent"
  $frmInfo.Text = "About..."
  $frmInfo.Add_Load($frmInfo_Load)

  [void]$frmInfo.ShowDialog()
}

frmMain_Show

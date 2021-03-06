$def = (gci $MyInvocation.MyCommand.Name).Directory

##################################################################################################

$mnuScan_Click= {
  $lstView.Items.Clear()

  try {
   Get-AllData ("SOFTWARE\Microsoft\Windows NT\CurrentVersion")
   Get-AllData (Expand-OfficeKey)
  }
  catch {}

  Measure-Items
}

$mnuSave_Click= {
  if ($lstView.Items.Count -ne 0) {
    (New-Object Windows.Forms.SaveFileDialog) | % {
      $_.FileName = "ProductKey"
      $_.Filter = "CSV (*.csv)|*.csv"
      $_.InitialDirectory = $def

      if ($_.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
        $sw = New-Object IO.StreamWriter($_.FileName, [Text.Encoding]::Default)
        $sw.WriteLine("ProductName, ProductID, ProductKey")
        $lstView.Items | % {
          $sw.WriteLine($($_.Text + ', ' + $_.SubItems[1].Text + ', ' + $_.SubItems[2].Text))
        }
        $sw.Flush()
        $sw.Close()
      }
    }
  }#if
}

$mnuFont_Click= {
  (New-Object Windows.Forms.FontDialog) | % {
    $_.Font = "Lucida Console"
    $_.MinSize = 8
    $_.MaxSize = 12
    $_.ShowEffects = $false

    if ($_.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
      $lstView.Font = $_.Font
    }
  }
}

$mnuSBar_Click= {
  $toggle =! $mnuSBar.Checked
  $mnuSBar.Checked = $toggle
  $sbPanel.Visible = $toggle
}

$frmMain_Load= {
  Measure-Items
}

##################################################################################################

function frmMain_Show {
  Add-Type -AssemblyName System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()

  $ico = [Drawing.Icon]::ExtractAssociatedIcon(($PSHome + '\powershell.exe'))

  $frmMain = New-Object Windows.Forms.Form
  $mnuMain = New-Object Windows.Forms.MenuStrip
  $mnuFile = New-Object Windows.Forms.ToolStripMenuItem
  $mnuScan = New-Object Windows.Forms.ToolStripMenuItem
  $mnuSave = New-Object Windows.Forms.ToolStripMenuItem
  $mnuEmp1 = New-Object Windows.Forms.ToolStripSeparator
  $mnuExit = New-Object Windows.Forms.ToolStripMenuItem
  $mnuView = New-Object Windows.Forms.ToolStripMenuItem
  $mnuFont = New-Object Windows.Forms.ToolStripMenuItem
  $mnuSBar = New-Object Windows.Forms.ToolStripMenuItem
  $mnuHelp = New-Object Windows.Forms.ToolStripMenuItem
  $mnuInfo = New-Object Windows.Forms.ToolStripMenuItem
  $lstView = New-Object Windows.Forms.ListView
  $imgList = New-Object Windows.Forms.ImageList
  $chPName = New-Object Windows.Forms.ColumnHeader
  $chProID = New-Object Windows.Forms.ColumnHeader
  $chPrKey = New-Object Windows.Forms.ColumnHeader
  $sbPanel = New-Object Windows.Forms.StatusBar
  $sbPnl_1 = New-Object Windows.Forms.StatusBarPanel
  $sbPnl_2 = New-Object Windows.Forms.StatusBarPanel
  #
  #mnuMain
  #
  $mnuMain.Dock = "Top"
  $mnuMain.Items.AddRange(@($mnuFile, $mnuView, $mnuHelp))
  #
  #mnuFile
  #
  $mnuFile.DropDownItems.AddRange(@($mnuScan, $mnuSave, $mnuEmp1, $mnuExit))
  $mnuFile.Text = "&File"
  #
  #mnuScan
  #
  $mnuScan.ShortcutKeys = "F5"
  $mnuScan.Text = "S&can..."
  $mnuScan.Add_Click($mnuScan_Click)
  #
  #mnuSave
  #
  $mnuSave.ShortcutKeys = "Control", "S"
  $mnuSave.Text = "&Save log"
  $mnuSave.Add_Click($mnuSave_Click)
  #
  #mnuExit
  #
  $mnuExit.ShortcutKeys = "Control", "X"
  $mnuExit.Text = "E&xit"
  $mnuExit.Add_Click({$frmMain.Close()})
  #
  #mnuView
  #
  $mnuView.DropDownItems.AddRange(@($mnuFont, $mnuSBar))
  $mnuView.Text = "&View"
  #
  #mnuFont
  #
  $mnuFont.Text = "Font..."
  $mnuFont.Add_Click($mnuFont_Click)
  #
  #mnuSBar
  #
  $mnuSBar.Checked = $true
  $mnuSBar.Enabled = $false
  $mnuSBar.ShortcutKeys = "Control", "B"
  $mnuSbar.Text = "Status &Bar"
  $mnuSbar.Add_Click($mnuSBar_Click)
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
  #lstView
  #
  $lstView.AllowColumnReorder = $true
  $lstView.Columns.AddRange(@($chPName, $chProID, $chPrKey))
  $lstView.Dock = "Bottom"
  $lstView.FullRowSelect = $true
  $lstView.GridLines = $true
  $lstView.Height = 191
  $lstView.MultiSelect = $false
  $lstView.SmallImageList = $imgList
  $lstView.Sorting = "Ascending"
  $lstView.View = "Details"
  #
  #imgList
  #
  $imgList.Images.Add((Get-Image $img))
  #
  #chPName
  #
  $chPName.Text = "Product Name"
  $chPName.Width = 183
  #
  #chProID
  #
  $chProID.Text = "Product ID"
  $chProID.Width = 143
  #
  #chPrKey
  #
  $chPrKey.Text = "Product Key"
  $chPrKey.Width = 220
  #
  #sbPanel
  #
  $sbPanel.Panels.AddRange(@($sbPnl_1, $sbPnl_2))
  $sbPanel.SizingGrip = $false
  $sbPanel.ShowPanels = $true
  #
  #sbPnl_1
  #
  $sbPnl_1.AutoSize = "Contents"
  #
  #sbPnl_2
  #
  $sbPnl_2.AutoSize = "Contents"
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(573, 237)
  $frmMain.Controls.AddRange(@($mnuMain, $lstView, $sbPanel))
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.Icon = $ico
  $frmMain.MaximizeBox = $false
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "ProductKey"
  $frmMain.Add_Load({Measure-Items})

  [void]$frmMain.ShowDialog()
}

##################################################################################################

function frmInfo_Show {
  $frmInfo = New-Object Windows.Forms.Form
  $pbImage = New-Object Windows.Forms.PictureBox
  $lblName = New-Object Windows.Forms.Label
  $lblCopy = New-Object Windows.Forms.Label
  $btnExit = New-Object Windows.Forms.Button
  #
  #pbImage
  #
  $pbImage.Location = New-Object Drawing.Point(16, 16)
  $pbImage.Size = New-Object Drawing.Size(32, 32)
  $pbImage.SizeMode = "StretchImage"
  #
  #lblName
  #
  $lblName.Font = New-Object Drawing.Font("Microsoft Sans Serif", 8, [Drawing.FontStyle]::Bold)
  $lblName.Location = New-Object Drawing.Point(53, 19)
  $lblName.Size = New-Object Drawing.Size(360, 18)
  $lblName.Text = "ProductKey v1.15"
  #
  #lblCopy
  #
  $lblCopy.Location = New-Object Drawing.Point(67, 37)
  $lblCopy.Size = New-Object Drawing.Size(360, 23)
  $lblCopy.Text = "(C) 2010-2013 greg zakharov gregzakh@gmail.com"
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
  $frmInfo.ShowInTaskBar = $false
  $frmInfo.StartPosition = "CenterScreen"
  $frmInfo.Text = "About..."
  $frmInfo.Add_Load({$pbImage.Image = $ico.ToBitmap()})

  [void]$frmInfo.ShowDialog()
}

##################################################################################################

function Get-ProductKey($reg) {
  $map = "BCDFGHJKMPQRTVWXY2346789"
  $val = (gp $reg).DigitalProductId[52..66]
  $key = ''

  for ($i = 24; $i -ge 0; $i--) {
    $k = 0
    for ($j = 14; $j -ge 0; $j--) {
      $k = ($k * 256) -bxor $val[$j]
      $val[$j] = [Math]::Floor([double]($k / 24))
      $k = $k % 24
    }
    $key = $map[$k] + $key

    if (($i % 5) -eq 0 -and $i -ne 0) {$key = '-' + $key}
  }
  $key
}

function Expand-OfficeKey {
  $src = 'SOFTWARE\Microsoft\Office'
  $rk = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($src)
  $src += '\' + $($rk.GetSubKeyNames() -match '(\d)+.0') + '\Registration'
  $rk.Close()

  $rk = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($src)
  $src += '\' + $($rk.GetSubKeyNames())
  $rk.Close()

  return $src
}

function Get-AllData($reg) {
  $rk = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($reg)
  $itm = $lstView.Items.Add(($rk.GetValue("ProductName")), 0)
  $itm.SubItems.Add(($rk.GetValue("ProductID")))
  $rk.Close()
  $itm.SubItems.Add((Get-ProductKey ('HKLM:\' + $reg)))
}

function Measure-Items {
  $sbPnl_1.Text = $lstView.Items.Count.ToString() + ' item(s)'

  if ($lstView.Items.Count -eq 0) {
    $sbPnl_2.Text = 'Not scaned'
  }
  else {
    $sbPnl_2.Text = 'Scan complete'
  }
}

function Get-Image($s) {
  [Drawing.Image]::FromStream((New-Object IO.MemoryStream(($$ = `
                [Convert]::FromBase64String($s)), 0, $$.Length)))
}

##################################################################################################

$img = "Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAA/////////////" + `
       "///////////6urqhoaG////////////////////////////////////////////4+PjhoaGwMDATU1NhoaGIi" + `
       "Ii////////////////////////////////////////srKypKCggICAsrKyhoaGIiIi///////////////////" + `
       "/kKmt8fHx////////////gICAmZmZQkJCVVVVhoaGIiIi////////////wMDAQkJCAMzMTU1N////////zMzM" + `
       "wMDAmZmZhoaGwMDAhoaGIiIi////////8fHxM2ZmAP//M2ZmADMz////////////lpaWmZmZTU1N3d3dhoaGH" + `
       "Bwc////zMzMAICAAMzMM2ZmADMz8Pv/////////wMDA19fXmZmZmZmZzMzM4+PjKSkp////M5mZAP//M2ZmAD" + `
       "Mz8Pv/////////////////wMDApKCg19fXwMDAFhYWFhYWHBwcAP//M2ZmADMz////////////////////srK" + `
       "ysrKy3d3dQkJCZpmZAP//AP//AP//M5mZAGZm////////////////////srKy19fXpKCgwMDAAMzMAP//ZszM" + `
       "ZszMZszMZszMd3d3////////////////////4+Pj19fXsrKypKCgAP//AP//AICAAGZmZszMZszMd3d3/////" + `
       "///////////////4+Pj19fXVVVVd3d3AP//kKmtZmZmAICAAICAZpmZsrKy////////////////////zMzMzM" + `
       "zMQkJCZmZmAP//AAAAsrKyAMzMM8zMM2Zm////////////////////////6urqzMzMsrKyKSkplpaWX19fZmZ" + `
       "mAMzMOTk5////////////////////////////////4+PjzMzMTU1NzMzMhoaGwMDA3d3d////////////////" + `
       "////////////////////////////////////////////////////////////////////////////"

##################################################################################################

frmMain_Show

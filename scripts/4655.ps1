$frmMain_Load= {
  [Text.Encoding]::GetEncodings() | % {
    $e = $_.GetEncoding()
    $dgvGrid.Rows.Add($e.CodePage, $e.BodyName, $e.EncodingName, $e.WindowsCodePage, `
    $e.IsBrowserDisplay, $e.IsBrowserSave, $e.IsMailNewsDisplay, $e.IsMailNewsSave, $e.IsSingleByte)
  }
}

function frmMain_Show {
  Add-Type -Assembly System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()
  
  $ico = [Drawing.Icon]::ExtractAssociatedIcon(($PSHome + '\powershell.exe'))
  
  $frmMain = New-Object Windows.Forms.Form
  $dgvGrid = New-Object Windows.Forms.DataGridView
  #
  #dgvGrid
  #
  $dgvGrid.AutoSizeColumnsMode = "AllCells"
  $dgvGrid.Dock = "Fill"
  $dgvGrid.ColumnCount = 9
  $dgvGrid.Columns[0].Name = "Identifier"
  $dgvGrid.Columns[1].Name = "CodePage"
  $dgvGrid.Columns[2].Name = "EncodingName"
  $dgvGrid.Columns[3].Name = "WCP"
  $dgvGrid.Columns[4].Name = "BrowserDisplay"
  $dgvGrid.Columns[5].Name = "BrowserSave"
  $dgvGrid.Columns[6].Name = "MailNewsDisplay"
  $dgvGrid.Columns[7].Name = "MailNewsSave"
  $dgvGrid.Columns[8].Name = "1Byte"
  $dgvGrid.SelectionMode = "FullRowSelect"
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(670, 370)
  $frmMain.Controls.AddRange(@($dgvGrid))
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.Icon = $ico
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "Encodings Snap"
  $frmMain.Add_Load($frmMain_Load)
  
  [void]$frmMain.ShowDialog()
}

frmMain_Show

$btnMove_MouseDown= {
  if ($_.Button -eq [Windows.Forms.MouseButtons]::Left) {
    $bool = $true
    $coor = [Drawing.Point]$_.Location
  }
}

$btnMove_MouseMove= {
  if ($bool) {
    $btnMove.Location = New-Object Drawing.Point(
      ($btnMove.Left - $btnMove.X + $_.X), ($btnMove.Top - $btnMove.Y + $_.Y)
    )
  }
}

$btnMove_MouseUp= {
  if ($_.Button -eq [Windows.Forms.MouseButtons]::Left) { $bool = $false }
}

function frmMain_Show {
  Add-Type -AssemblyName System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()

  $frmMain = New-Object Windows.Forms.Form
  $btnMove = New-Object Windows.Forms.Button
  #
  #btnMove
  #
  $btnMove.Location = New-Object Drawing.Point(($frmMain.Width / 2 + 70), ($frmMain.Height / 2))
  $btnMove.Size = New-Object Drawing.Size(110, 27)
  $btnMove.Text = "Click and move"
  $btnMove.Add_MouseDown($btnMove_MouseDown)
  $btnMove.Add_MouseMove($btnMove_MouseMove)
  $btnMove.Add_MouseUp($btnMove_MouseUp)
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(570, 370)
  $frmMain.Controls.Add($btnMove)
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.MaximizeBox = $false
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "Form1"

  [void]$frmMain.ShowDialog()
}

frmMain_Show

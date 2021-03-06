function AssembliesTree {
  $tvAssem.Nodes.Clear()
  
  [AppDomain]::CurrentDomain.GetAssemblies() | % {
    $nod = New-Object Windows.Forms.TreeNode
    $nod.Text = $_.GetName().Name
    $nod.Tag = $_
    
    $tvAssem.Nodes.Add($nod)
    $nod.Nodes.Add("<NULL>")
  }
}

$tvAssem_BeforeExpand= {
  $_.Node.Nodes.Clear()
  
  foreach ($t in $_.Node.Tag.GetTypes()) {
    if ($t.IsPublic) {
      $new = $_.Node.Nodes.Add($t.FullName)
      $new.Tag = $t
    }
  }
}

$tvAssem_BeforeSelect= {
  $lstLst1.Items.Clear()
  $lstlst2.Items.Clear()
  $sbLabel.Text = [String]::Empty

  foreach ($p in $_.Node.Tag.PSObject.Properties) {
    $itm = $lstLst1.Items.Add($p.Name)
    
    switch (($p.Value -ne $null)) {
      $true {
        $itm.SubItems.Add($p.Value.ToString())
        
        switch ($p.Value) {
          $true {$itm.ForeColor = "Blue"}
          $false {$itm.ForeColor = "Crimson"}
        }
      }
      default {
        $itm.ForeColor = "Gray"
        $itm.SubItems.Add("<NULL>")
      }
    }
  }

  try {
    $_.Node.Tag -as [Type] | gm -ea 0 -s -fo | % {
      $itm = $lstLst2.Items.Add($_.Name)
      $itm.SubItems.Add($_.MemberType.ToString())
      $itm.SubItems.Add($_.Definition)
    }
  }
  catch {}

  $sbLabel.Text = $_.Node.Tag
}

$mnuLoad_Click= {
  (New-Object Windows.Forms.OpenFileDialog) | % {
    $_.InitialDirectory = [Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
    $_.Filter = "PE Files (*.dll)|*.dll"
    
    if ($_.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
      [void][Reflection.Assembly]::Load(([IO.File]::ReadAllBytes($_.FileName)))
    }
  }
  AssembliesTree
}

$mnuStrp_Click= {
  $toggle =! $mnuStrp.Checked
  $mnuStrp.Checked = $toggle
  $sbStrip.Visible = $toggle
}

$mnuMems_Click= {
  $toggle =! $mnuMems.Checked
  $mnuMems.Checked = $toggle
  $scSplt2.Panel2Collapsed =! $toggle
}

function frmMain_Show {
  Add-Type -Assembly System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()
  
  $ico = [Drawing.Icon]::ExtractAssociatedIcon(($PSHome + '\powershell.exe'))
  switch ((Get-Culture).TwoLetterISOLanguageName) {
    "ru" {$iso = "ru"}
    default {$iso = "en"}
  }
  
  $frmMain = New-Object Windows.Forms.Form
  $mnuMain = New-Object Windows.Forms.MenuStrip
  $mnuFile = New-Object Windows.Forms.ToolStripMenuItem
  $mnuLoad = New-Object Windows.Forms.ToolStripMenuItem
  $mnuNull = New-Object Windows.Forms.ToolStripSeparator
  $mnuExit = New-Object Windows.Forms.ToolStripMenuItem
  $mnuView = New-Object Windows.Forms.ToolStripMenuItem
  $mnuStrp = New-Object Windows.Forms.ToolStripMenuItem
  $mnuMems = New-Object Windows.Forms.ToolStripMenuItem
  $mnuHelp = New-Object Windows.Forms.ToolStripMenuItem
  $mnuInfo = New-Object Windows.Forms.ToolStripMenuItem
  $scSplt1 = New-Object Windows.Forms.SplitContainer
  $tvAssem = New-Object Windows.Forms.TreeView
  $scSplt2 = New-Object Windows.Forms.SplitContainer
  $lstLst1 = New-Object Windows.Forms.ListView
  $chCol_1 = New-Object Windows.Forms.ColumnHeader
  $chCol_2 = New-Object Windows.Forms.ColumnHeader
  $lstLst2 = New-Object Windows.Forms.ListView
  $chCol_3 = New-Object Windows.Forms.ColumnHeader
  $chCol_4 = New-Object Windows.Forms.ColumnHeader
  $chCol_5 = New-Object Windows.Forms.ColumnHeader
  $sbStrip = New-Object Windows.Forms.StatusStrip
  $sbLabel = New-Object Windows.Forms.ToolStripStatusLabel
  #
  #mnuMain
  #
  $mnuMain.Items.AddRange(@($mnuFile, $mnuView, $mnuHelp))
  #
  #mnuFile
  #
  $mnuFile.DropDownItems.AddRange(@($mnuLoad, $mnuNull, $mnuExit))
  $mnuFile.Text = "&File"
  #
  #mnuLoad
  #
  $mnuLoad.ShortcutKeys = "Control", "O"
  $mnuLoad.Text = "&Load Assembly"
  $mnuLoad.Add_Click($mnuLoad_Click)
  #
  #mnuExit
  #
  $mnuExit.ShortcutKeys = "Control", "X"
  $mnuExit.Text = "E&xit"
  $mnuExit.Add_Click({$frmMain.Close()})
  #
  #mnuView
  #
  $mnuView.DropDownItems.AddRange(@($mnuStrp, $mnuMems))
  $mnuView.Text = "&View"
  #
  #mnuStrp
  #
  $mnuStrp.Checked = $true
  $mnuStrp.Text = "&Status Bar Toggle"
  $mnuStrp.Add_Click($mnuStrp_Click)
  #
  #mnuMems
  #
  $mnuMems.ShortcutKeys = "Control", "M"
  $mnuMems.Text = "&Members Pane"
  $mnuMems.Add_Click($mnuMems_Click)
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
  #scSplt1
  #
  $scSplt1.Dock = "Fill"
  $scSplt1.Panel1.Controls.Add($tvAssem)
  $scSplt1.Panel2.Controls.Add($scSplt2)
  $scSplt1.SplitterWidth = 1
  #
  #tvAssem
  #
  $tvAssem.Dock = "Fill"
  $tvAssem.Sorted = $true
  $tvAssem.Add_BeforeExpand($tvAssem_BeforeExpand)
  $tvAssem.Add_BeforeSelect($tvAssem_BeforeSelect)
  #
  #scSplt2
  #
  $scSplt2.Dock = "Fill"
  $scSplt2.Panel1.Controls.Add($lstLst1)
  $scSplt2.Panel2.Controls.Add($lstLst2)
  $scSplt2.Panel2Collapsed = $true
  $scSplt2.Orientation = "Horizontal"
  $scSplt2.SplitterDistance = 45
  $scSplt2.SplitterWidth = 1
  #
  #lstLst1
  #
  $lstLst1.Columns.AddRange(@($chCol_1, $chCol_2))
  $lstLst1.Dock = "Fill"
  $lstLst1.FullRowSelect = $true
  $lstLst1.MultiSelect = $false
  $lstLst1.ShowItemToolTips = $true
  $lstLst1.Sorting = "Ascending"
  $lstLst1.View = "Details"
  #
  #chCol_1
  #
  $chCol_1.Text = "Name"
  $chCol_1.Width = 205
  #
  #chCol_2
  #
  $chCol_2.Text = "Property"
  $chCol_2.Width = 307
  #
  #lstLst2
  #
  $lstLst2.Columns.AddRange(@($chCol_3, $chCol_4, $chCol_5))
  $lstLst2.Dock = "Fill"
  $lstLst2.FullRowSelect = $true
  $lstLst2.MultiSelect = $false
  $lstLst2.ShowItemToolTips = $true
  $lstLst2.View = "Details"
  #
  #chCol_3
  #
  $chCol_3.Text = "Name"
  $chCol_3.Width = 130
  #
  #chCol_4
  #
  $chCol_4.Text = "Member Type"
  $chCol_4.Width = 90
  #
  #chCol_5
  #
  $chCol_5.Text = "Definition"
  $chCol_5.Width = 292
  #
  #sbStrip
  #
  $sbStrip.Items.AddRange(@($sbLabel))
  $sbStrip.SizingGrip = $false
  #
  #sbLabel
  #
  $sbLabel.AutoSize = $true
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(800, 600)
  $frmMain.Controls.AddRange(@($scSplt1, $sbStrip, $mnuMain))
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.Icon = $ico
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "Assembly Explorer"
  $frmMain.Add_Load({AssembliesTree})
  
  [void]$frmMain.ShowDialog()
}

function frmInfo_Show {
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
  $lblName.Text = "Assembly Explorer v2.03"
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
  $frmInfo.StartPosition = "CenterParent"
  $frmInfo.Text = "About..."
  $frmInfo.Add_Load($frmInfo_Load)

  [void]$frmInfo.ShowDialog()
}

frmMain_Show

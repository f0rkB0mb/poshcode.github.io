#requires -version 2.0
function Get-UserStatus {
  $usr = [Security.Principal.WindowsIdentity]::GetCurrent()
  return (New-Object Security.Principal.WindowsPrincipal $usr).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
  )
}

function Get-ClassesList([String]$NameSpace, [String]$Filter) {
  gwmi -List -NameSpace $NameSpace $Filter | % {
    $lstLst1.Items.Add($_.Name)
  }
}

$tsCbo_1_SelectedIndexChanged= {
  $lstLst1.Items.Clear()
  $lstLst2.Items.Clear()
  $lstLst3.Items.Clear()
  
  switch ($tsCbo_1.SelectedIndex) {
    "0" {$tsCbo_2.Enabled = $false; $tsCbo_2.SelectedIndex = 0}
    "1" {$tsCbo_2.Enabled = $true}
  }
  
  Get-ClassesList $tsCbo_1.SelectedItem $tsCbo_2.SelectedItem
}

$tsCbo_2_SelectedIndexChanged= {
  $lstLst1.Items.Clear()
  $lstLst2.Items.Clear()
  $lstLst3.Items.Clear()
  Get-ClassesList $tsCbo_1.SelectedItem $tsCbo_2.SelectedItem
}

$lstLst1_Click= {
  $lstLst2.Items.Clear()
  $lstLst3.Items.Clear()
  $sbLabel.Text = [String]::Empty
  
  for ($i = 0; $i -lt $lstLst1.Items.Count; $i++) {
    if ($lstLst1.Items[$i].Selected) {
      $sbLabel.Text = $lstLst1.Items[$i].Text
      $wmi = [wmiclass]($tsCbo_1.SelectedItem + ':' + $lstLst1.Items[$i].Text)
      ($wmi | select Methods).Methods | % {
        $itm = $lstLst2.Items.Add($_.Name)
        $itm.SubItems.Add(($_.Qualifiers | % {$str = ""}{$str += $_.Name + '; '}{$str}))
        $itm.SubItems.Add($_.Origin)
      }
      ($wmi | select Properties).Properties | % {
        $itm = $lstLst3.Items.Add($_.Name)
        $itm.SubItems.Add($_.Type.ToString())
        $itm.SubItems.Add($_.IsLocal.ToString())
        $itm.SubItems.Add($_.IsArray.ToString())
        $itm.SubItems.Add(($_.Qualifiers | % {$str = ""}{$str += $_.Name + '; '}{$str}))
        $itm.SubItems.Add($_.Origin)
      }
    }
  }
}

function Get-AssembliesTree {
  $tvAssem.Nodes.Clear()
  $lstLst4.Items.Clear()
  $lstLst5.Items.Clear()
  
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
  $lstLst4.Items.Clear()
  $lstLst5.Items.Clear()
  $sbLabel.Text = [String]::Empty
  
  foreach ($p in $_.Node.Tag.PSObject.Properties) {
    $itm = $lstLst4.Items.Add($p.Name)
    
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
      $itm = $lstLst5.Items.Add($_.Name)
      $itm.SubItems.Add($_.MemberType.ToString())
      $itm.SubItems.Add($_.Definition)
    }
  }
  catch {}
  
  $sbLabel.Text = $_.Node.Tag
}

$mnuStrp_Click= {
  $toggle =! $mnuStrp.Checked
  $mnuStrp.Checked = $toggle
  $sbStrip.Visible = $toggle
}

$frmMain_Load= {
  if (Get-UserStatus) {
    Get-ClassesList $tsCbo_1.SelectedItem $tsCbo_2.SelectedItem
  }
  else {
    [Windows.Forms.MessageBox]::Show("WMI page has been covered because you haven't enough`
        `trights to access its objects.", "Note", [Windows.Forms.MessageBoxButtons]::OK, `
    [Windows.Forms.MessageBoxIcon]::Information)
  }
  Get-AssembliesTree
}

function frmMain_Show {
  Add-Type -Assembly System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()
  
  $ico = [Drawing.Icon]::ExtractAssociatedIcon(($PSHome + '\powershell.exe'))
  
  $frmMain = New-Object Windows.Forms.Form
  $mnuMain = New-Object Windows.Forms.MenuStrip
  $mnuFile = New-Object Windows.Forms.ToolStripMenuItem
  $mnuExit = New-Object Windows.Forms.ToolStripMenuItem
  $mnuView = New-Object Windows.Forms.ToolStripMenuItem
  $mnuStrp = New-Object Windows.Forms.ToolStripMenuItem
  $mnuHelp = New-Object Windows.Forms.ToolStripMenuItem
  $mnuInfo = New-Object Windows.Forms.ToolStripMenuItem
  $tsTools = New-Object Windows.Forms.ToolStrip
  $tsLab_1 = New-Object Windows.Forms.ToolStripLabel
  $tsLab_2 = New-Object Windows.Forms.ToolStripLabel
  $tsCbo_1 = New-Object Windows.Forms.ToolStripComboBox
  $tsCbo_2 = New-Object Windows.Forms.ToolStripComboBox
  $tabCtrl = New-Object Windows.Forms.TabControl
  $tpPage1 = New-Object Windows.Forms.TabPage
  $tpPage2 = New-Object Windows.Forms.TabPage
  $scSplt1 = New-Object Windows.Forms.SplitContainer
  $scSplt2 = New-Object Windows.Forms.SplitContainer
  $scSplt3 = New-Object Windows.Forms.SplitContainer
  $scSplt4 = New-Object Windows.Forms.SplitContainer
  $lstLst1 = New-Object Windows.Forms.ListView
  $lstLst2 = New-Object Windows.Forms.ListView
  $lstLst3 = New-Object Windows.Forms.ListView
  $lstLst4 = New-Object Windows.Forms.ListView
  $lstLst5 = New-Object Windows.Forms.ListView
  $chCol_1 = New-Object Windows.Forms.ColumnHeader
  $chCol_2 = New-Object Windows.Forms.ColumnHeader
  $chCol_3 = New-Object Windows.Forms.ColumnHeader
  $chCol_4 = New-Object Windows.Forms.ColumnHeader
  $chCol_5 = New-Object Windows.Forms.ColumnHeader
  $chCol_6 = New-Object Windows.Forms.ColumnHeader
  $chCol_7 = New-Object Windows.Forms.ColumnHeader
  $chCol_8 = New-Object Windows.Forms.ColumnHeader
  $chCol_9 = New-Object Windows.Forms.ColumnHeader
  $chCol10 = New-Object Windows.Forms.ColumnHeader
  $chCol11 = New-Object Windows.Forms.ColumnHeader
  $chCol12 = New-Object Windows.Forms.ColumnHeader
  $chCol13 = New-Object Windows.Forms.ColumnHeader
  $chCol14 = New-Object Windows.Forms.ColumnHeader
  $chCol15 = New-Object Windows.Forms.ColumnHeader
  $gboGbo1 = New-Object Windows.Forms.GroupBox
  $gboGbo2 = New-Object Windows.Forms.GroupBox
  $tvAssem = New-Object Windows.Forms.TreeView
  $sbStrip = New-Object Windows.Forms.StatusStrip
  $sbLabel = New-Object Windows.Forms.ToolStripStatusLabel
  #
  #mnuMain
  #
  $mnuMain.Items.AddRange(@($mnuFile, $mnuView, $mnuHelp))
  #
  #mnuFile
  #
  $mnuFile.DropDownItems.AddRange(@($mnuExit))
  $mnuFile.Text = "&File"
  #
  #mnuExit
  #
  $mnuExit.ShortcutKeys = "Control", "X"
  $mnuExit.Text = "E&xit"
  $mnuExit.Add_Click({$frmMain.Close()})
  #
  #mnuView
  #
  $mnuView.DropDownItems.AddRange(@($mnuStrp))
  $mnuView.Text = "&View"
  #
  #mnuStrp
  #
  $mnuStrp.Checked = $true
  $mnuStrp.Text = "&Status Bar Toogle"
  $mnuStrp.Add_Click($mnuStrp_Click)
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
  #tsTools
  #
  $tsTools.Items.AddRange(@($tsLab_1, $tsCbo_1, $tsLab_2, $tsCbo_2))
  #
  #tsLab_1
  #
  $tsLab_1.Text = "NameSpace:"
  #
  #tsCbo_1
  #
  $tsCbo_1.Items.AddRange(@('root\default', 'root\cimv2'))
  $tsCbo_1.SelectedIndex = 0
  $tsCbo_1.Add_SelectedIndexChanged($tsCbo_1_SelectedIndexChanged)
  #
  #tsLab_2
  #
  $tsLab_2.Text = "Filter:"
  #
  #tsCbo_2
  #
  $tsCbo_2.Enabled = $false
  $tsCbo_2.Items.AddRange(@('*', 'Win32_*'))
  $tsCbo_2.SelectedIndex = 0
  $tsCbo_2.Add_SelectedIndexChanged($tsCbo_2_SelectedIndexChanged)
  #
  #tabCtrl
  #
  if (Get-UserStatus) {$tabCtrl.Controls.AddRange(@($tpPage1))}
  $tabCtrl.Controls.AddRange(@($tpPage2))
  $tabCtrl.Dock = "Fill"
  #
  #tpPage1
  #
  $tpPage1.Controls.AddRange(@($scSplt1))
  $tpPage1.Text = "WMI"
  $tpPage1.UseVisualStyleBackColor = $true
  #
  #scSplt1
  #
  $scSplt1.Dock = "Fill"
  $scSplt1.Panel1.Controls.Add($lstLst1)
  $scSplt1.Panel2.Controls.Add($scSplt2)
  $scSplt1.SplitterWidth = 1
  #
  #lstLst1
  #
  $lstLst1.Columns.AddRange(@($chCol_1))
  $lstLst1.Dock = "Fill"
  $lstLst1.FullRowSelect = $true
  $lstLst1.MultiSelect = $false
  $lstLst1.ShowItemToolTips = $true
  $lstLst1.Sorting = "Ascending"
  $lstLst1.View = "Details"
  $lstLst1.Add_Click($lstLst1_Click)
  #
  #scCol_1
  #
  $chCol_1.Text = "Classes"
  $chCol_1.Width = 240
  #
  #scSplt2
  #
  $scSplt2.Dock = "Fill"
  $scSplt2.Panel1.Controls.Add($gboGbo1)
  $scSplt2.Panel2.Controls.Add($gboGbo2)
  $scSplt2.Orientation = "Horizontal"
  $scSplt2.SplitterDistance = 45
  $scSplt2.SplitterWidth = 1
  #
  #gboGbo1
  #
  $gboGbo1.Controls.AddRange(@($lstLst2))
  $gboGbo1.Dock = "Fill"
  $gboGbo1.Text = "Methods"
  #
  #lstLst2
  #
  $lstLst2.AllowColumnReorder = $true
  $lstLst2.Columns.AddRange(@($chCol_2, $chCol_3, $chCol_4))
  $lstLst2.Dock = "Fill"
  $lstLst2.FullRowSelect = $true
  $lstLst2.MultiSelect = $false
  $lstLst2.ShowItemToolTips = $true
  $lstLst2.View = "Details"
  #
  #chCol_2
  #
  $chCol_2.Text = "Name"
  $chCol_2.Width = 200
  #
  #chCol_3
  #
  $chCol_3.Text = "Qualifiers"
  $chCol_3.Width = 90
  #
  #chCol_4
  #
  $chCol_4.Text = "Origin"
  $chCol_4.Width = 213
  #
  #gboGbo2
  #
  $gboGbo2.Controls.AddRange(@($lstLst3))
  $gboGbo2.Dock = "Fill"
  $gboGbo2.Text = "Properties"
  #
  #lstLst3
  #
  $lstLst3.AllowColumnReorder = $true
  $lstLst3.Columns.AddRange(@($chCol_5, $chCol_6, $chCol_7, $chCol_8, $chCol_9, $chCol10))
  $lstLst3.Dock = "Fill"
  $lstLst3.FullRowSelect = $true
  $lstLst3.MultiSelect = $false
  $lstLst3.ShowItemToolTips = $true
  $lstLst3.View = "Details"
  #
  #chCol_5
  #
  $chCol_5.Text = "Name"
  $chCol_5.Width = 140
  #
  #chCol_6
  #
  $chCol_6.Text = "Type"
  $chCol_6.Width = 55
  #
  #chCol_7
  #
  $chCol_7.Text = "IsLocal"
  $chCol_7.Width = 57
  #
  #chCol_8
  #
  $chCol_8.Text = "IsArray"
  $chCol_8.Width = 55
  #
  #chCol_9
  #
  $chCol_9.Text = "Qualifiers"
  $chCol_9.Width = 99
  #
  #chCol10
  #
  $chCol10.Text = "Origin"
  $chCol10.Width = 97
  #
  #tpPage2
  #
  $tpPage2.Controls.AddRange(@($scSplt3))
  $tpPage2.Text = "AppDomain"
  $tpPage2.UseVisualStyleBackColor = $true
  #
  #scSplt3
  #
  $scSplt3.Dock = "Fill"
  $scSplt3.Panel1.Controls.Add($tvAssem)
  $scSplt3.Panel2.Controls.Add($scSplt4)
  $scSplt3.SplitterWidth = 1
  #
  #tvAssem
  #
  $tvAssem.Dock = "Fill"
  $tvAssem.Sorted = $true
  $tvAssem.Add_BeforeExpand($tvAssem_BeforeExpand)
  $tvAssem.Add_BeforeSelect($tvAssem_BeforeSelect)
  #
  #scSplt4
  #
  $scSplt4.Dock = "Fill"
  $scSplt4.Panel1.Controls.Add($lstLst4)
  $scSplt4.Panel2.Controls.Add($lstLst5)
  $scSplt4.Orientation = "Horizontal"
  $scSplt4.SplitterDistance = 45
  $scSplt4.SplitterWidth = 1
  #
  #lstLst4
  #
  $lstLst4.Columns.AddRange(@($chCol11, $chCol12))
  $lstLst4.Dock = "Fill"
  $lstLst4.FullRowSelect = $true
  $lstLst4.MultiSelect = $false
  $lstLst4.ShowItemToolTips = $true
  $lstLst4.Sorting = "Ascending"
  $lstLst4.View = "Details"
  #
  #chCol11
  #
  $chCol11.Text = "Name"
  $chCol11.Width = 205
  #
  #chCol12
  #
  $chCol12.Text = "Property"
  $chCol12.Width = 304
  #
  #lstLst5
  #
  $lstLst5.AllowColumnReorder = $true
  $lstLst5.Columns.AddRange(@($chCol13, $chCol14, $chCol15))
  $lstLst5.Dock = "Fill"
  $lstLst5.FullRowSelect = $true
  $lstLst5.MultiSelect = $false
  $lstLst5.ShowItemToolTips = $true
  $lstLst5.View = "Details"
  #
  #chCol13
  #
  $chCol13.Text = "Name"
  $chCol13.Width = 130
  #
  #chCol14
  #
  $chCol14.Text = "Member Type"
  $chCol14.Width = 90
  #
  #chCol15
  #
  $chCol15.Text = "Definition"
  $chCol15.Width = 289
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
  $frmMain.Controls.AddRange(@($tabCtrl, $sbStrip))
  if (Get-UserStatus) {$frmMain.Controls.AddRange(@($tsTools))}
  $frmMain.Controls.AddRange(@($mnuMain))
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.Icon = $ico
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "PS Tools"
  $frmMain.Add_Load($frmMain_Load)
  
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
  $lblName.Text = "PS Tools v1.00"
  #
  #lblCopy
  #
  $lblCopy.Location = New-Object Drawing.Point(67, 37)
  $lblCopy.Size = New-Object Drawing.Size(360, 23)
  $lblCopy.Text = "(C) 2010-2013 greg zakharov forum.script-coding.com"
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

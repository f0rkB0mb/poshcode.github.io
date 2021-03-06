function Get-ProcessList {
  #snapshot time
  $now = Get-Date -f 'HH:mm:ss'

  #building list
  [int]$hndl = 0
  $script:ret = @()
  ps | % -b {$arr = @()} -p {
    $str = "" | select Name, StartTime, PID, PM, WS, Desc, Publ
    $str.Name = $_.ProcessName
    $str.StartTime = $(try { $_.StartTime} catch { return [DateTime]::MinValue })
    $str.PID = $_.Id
    $str.PM = $_.PrivateMemorySize64
    $str.WS = $_.WorkingSet64
    $str.Desc = $_.Description
    $str.Publ = $_.Company
    $arr += $str; $hndl += $_.Handles
  } -end {
    $arr | sort StartTime | % {
      try {
        $dgvView.Rows.Add($_.Name, $_.PID, ($_.PM / 1Kb), ($_.WS / 1Kb), $_.Desc, $_.Publ)
        $script:ret += $_.PID
      }
      catch {}
    }
  }

  #counting processes
  $sbPnl_1.Text = "Processes: " + $script:ret.Count

  #counting NET processes
  $net = @($clr.GetInstanceNames() | ? {$_ -ne "_Global_"} | % {ps -ea 0 $_}).Count
  $sbPnl_2.Text = ".NET Processes: " + $net

  #total handles
  $sbPnl_3.Text = "Handles: " + $hndl

  #current snapshot
  $sbPnl_4.Text = "Snap at: " + $now
}

$mnuSUpd_Click= {
  $dgvView.Rows.Clear()
  Get-ProcessList
}

$mnuFont_Click= {
  (New-Object Windows.Forms.FontDialog) | % {
    $_.MaxSize = 11
    $_.ShowEffects = $false

    if ($_.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
      $dgvView.Font = $_.Font
      $lstView.Font = $_.Font
    }
  }
}

$mnuPane_Click= {
  switch ([bool]$mnuPane.Checked) {
    $true  { $mnuPane.Checked = $false; $scSplit.Panel2Collapsed = $true; break; }
    $false { $mnuPane.Checked = $true; $scSplit.Panel2Collapsed = $false; break; }
  }
}

$mnuSBar_Click= {
  [bool]$toggle =! $mnuSBar.Checked
  $mnuSBar.Checked = $toggle
  $sbStats.Visible = $toggle
}

$dgvView_Click= {
  $lstView.Items.Clear()
  $row = $dgvView.CurrentCell.RowIndex

  try {
    (ps | ? {$_.Id -eq $script:ret[$row]}).Modules | % {
      $itm = $lstView.Items.Add($_.ModuleName)
      $itm.SubItems.Add($_.Size)
      $itm.SubItems.Add($_.Description)
      $itm.SubItems.Add($_.Company)
      $itm.SubItems.Add($_.FileName)
      $itm.SubItems.Add($('0x{0:X}' -f [int]$_.BaseAddress))
      $itm.SubItems.Add($_.ProductVersion)
    }
  }
  catch {}

  #last selected update
  $sbPnl_5.Text = "Last selected (PID): " + $script:ret[$row]
}

$frmMain_Load= {
  Get-ProcessList
  $sbPnl_5.Text = "Last selected (PID): <none>"
}

function frmMain_Show {
  Add-Type -AssemblyName System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()

  $clr = New-Object Diagnostics.PerformanceCounterCategory(".NET CLR Memory")
  $usr = [Security.Principal.WindowsIdentity]::GetCurrent()

  $frmMain = New-Object Windows.Forms.Form
  $mnuMain = New-Object Windows.Forms.MainMenu
  $mnuFile = New-Object Windows.Forms.MenuItem
  $mnuSUpd = New-Object Windows.Forms.MenuItem
  $mnuEmp1 = New-Object Windows.Forms.MenuItem
  $mnuExit = New-Object Windows.Forms.MenuItem
  $mnuView = New-Object Windows.Forms.MenuItem
  $mnuFont = New-Object Windows.Forms.MenuItem
  $mnuEmp2 = New-Object Windows.Forms.MenuItem
  $mnuPane = New-Object Windows.Forms.MenuItem
  $mnuSBar = New-Object Windows.Forms.MenuItem
  $mnuTool = New-Object Windows.Forms.MenuItem
  $mnuFind = New-Object Windows.Forms.MenuItem
  $mnuAsms = New-Object Windows.Forms.MenuItem
  $mnuHelp = New-Object Windows.Forms.MenuItem
  $mnuInfo = New-Object Windows.Forms.MenuItem
  $scSplit = New-Object Windows.Forms.SplitContainer
  $dgvView = New-Object Windows.Forms.DataGridView
  $lstView = New-Object Windows.Forms.ListView
  $chView1 = New-Object Windows.Forms.ColumnHeader
  $chView2 = New-Object Windows.Forms.ColumnHeader
  $chView3 = New-Object Windows.Forms.ColumnHeader
  $chView4 = New-Object Windows.Forms.ColumnHeader
  $chView5 = New-Object Windows.Forms.ColumnHeader
  $chView6 = New-Object Windows.Forms.ColumnHeader
  $chView7 = New-Object Windows.Forms.ColumnHeader
  $sbStats = New-Object Windows.Forms.StatusBar
  $sbPnl_1 = New-Object Windows.Forms.StatusBarPanel
  $sbPnl_2 = New-Object Windows.Forms.StatusBarPanel
  $sbPnl_3 = New-Object Windows.Forms.StatusBarPanel
  $sbPnl_4 = New-Object Windows.Forms.StatusBarPanel
  $sbPnl_5 = New-Object Windows.Forms.StatusBarPanel
  #
  #mnuMain
  #
  $mnuMain.MenuItems.AddRange(@($mnuFile, $mnuView, $mnuTool, $mnuHelp))
  #
  #mnuFile
  #
  $mnuFile.MenuItems.AddRange(@($mnuSUpd, $mnuEmp1, $mnuExit))
  $mnuFile.Text = "&File"
  #
  #mnuSUpd
  #
  $mnuSUpd.Shortcut = "F5"
  $mnuSUpd.Text = "&Refresh Now"
  $mnuSUpd.Add_Click($mnuSUpd_Click)
  #
  #mnuEmp1
  #
  $mnuEmp1.Text = "-"
  #
  #mnuExit
  #
  $mnuExit.Shortcut = "CtrlX"
  $mnuExit.Text = "E&xit"
  $mnuExit.Add_Click({$frmMain.Close()})
  #
  #mnuView
  #
  $mnuView.MenuItems.AddRange(@($mnuFont, $mnuEmp2, $mnuPane, $mnuSBar))
  $mnuView.Text = "&View"
  #
  #mnuFont
  #
  $mnuFont.Text = "&Font..."
  $mnuFont.Add_Click($mnuFont_Click)
  #
  #mnuEmp2
  #
  $mnuEmp2.Text = "-"
  #
  #mnuPane
  #
  $mnuPane.Shortcut = "CtrlD"
  $mnuPane.Text = "&DLLs Lower Pane"
  $mnuPane.Add_Click($mnuPane_Click)
  #
  #mnuSBar
  #
  $mnuSbar.Checked = $true
  $mnuSBar.Shortcut = "CtrlB"
  $mnuSBar.Text = "Toggle Status &Bar"
  $mnuSBar.Add_Click($mnuSBar_Click)
  #
  #mnuTool
  #
  $mnuTool.MenuItems.AddRange(@($mnuFind, $mnuAsms))
  $mnuTool.Text = "&Tools"
  #
  #mnuFind
  #
  $mnuFind.Shortcut = "CtrlF"
  $mnuFind.Text = "&Find DLL..."
  $mnuFind.Add_Click({frmFind_Show})
  #
  #mnuAsms
  #
  $mnuAsms.Text = "&Loaded Assemblies"
  $mnuAsms.Add_Click({frmAsms_Show})
  #
  #mnuHelp
  #
  $mnuHelp.MenuItems.AddRange(@($mnuInfo))
  $mnuHelp.Text = "&Help"
  #
  #mnuInfo
  #
  $mnuInfo.Text = "About..."
  $mnuInfo.Add_Click({frmInfo_Show})
  #
  #scSplit
  #
  $scSplit.Dock = "Fill"
  $scSplit.Orientation = "Horizontal"
  $scSplit.Panel1.Controls.Add($dgvView)
  $scSplit.Panel2.Controls.Add($lstView)
  $scSplit.Panel2Collapsed = $true
  #
  #dgvView
  #
  $dgvView.AutoSizeColumnsMode = "AllCells"
  $dgvView.ColumnCount = 6
  $dgvView.Columns[0].Name = "Process"
  $dgvView.Columns[1].Name = "PID"
  $dgvView.Columns[2].Name = "Private Bytes (K)"
  $dgvView.Columns[3].Name = "Working Set (K)"
  $dgvView.Columns[4].Name = "Description"
  $dgvView.Columns[5].Name = "Company Name"
  #$dgvView.ColumnHeadersHeightSizeMode = "AutoSize"
  $dgvView.Dock = "Fill"
  $dgvView.MultiSelect = $false
  $dgvView.Add_Click($dgvView_Click)
  #
  #lstView
  #
  $lstView.AllowColumnReorder = $true
  $lstView.Columns.AddRange(@($chView1, $chView2, $chView3, `
                     $chView4, $chView5, $chView6, $chView7))
  $lstView.Dock = "Fill"
  $lstView.FullRowSelect = $true
  $lstView.ShowItemToolTips = $true
  $lstView.Sorting = "Ascending"
  $lstView.View = "Details"
  #
  #chView1
  #
  $chView1.Text = "Name"
  $chView1.Width = 90
  #
  #chView2
  #
  $chView2.Text = "Size"
  $chView2.TextAlign = "Right"
  $chView2.Width = 50
  #
  #chView3
  #
  $chView3.Text = "Description"
  $chView3.Width = 190
  #
  #chView4
  #
  $chView4.Text = "Company Name"
  $chView4.Width = 150
  #
  #chView5
  #
  $chView5.Text = "Path"
  $chView5.Width = 289
  #
  #chView6
  #
  $chView6.Text = "Base"
  $chView6.TextAlign = "Right"
  $chView6.Width = 90
  #
  #chView7
  #
  $chView7.Text = "Version"
  $chView7.Width = 100
  #
  #sbStats
  #
  $sbStats.Panels.AddRange(@($sbPnl_1, $sbPnl_2, $sbPnl_3, $sbPnl_4, $sbPnl_5))
  $sbStats.ShowPanels = $true
  $sbStats.SizingGrip = $false
  #
  #sbPnl_1
  #
  $sbPnl_1.AutoSize = "Contents"
  #
  #sbPnl_2
  #
  $sbPnl_2.AutoSize = "Contents"
  #
  #sbPnl_3
  #
  $sbPnl_3.AutoSize = "Contents"
  #
  #sbPnl_4
  #
  $sbPnl_4.AutoSize = "Contents"
  #
  #sbPnl_5
  #
  $sbPnl_5.AutoSize = "Contents"
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(790, 550)
  $frmMain.Controls.AddRange(@($scSplit, $sbStats))
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.MaximizeBox = $false
  $frmMain.Menu = $mnuMain
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "Process Snapshot [" + $usr.Name + "]"
  $frmMain.Add_Load($frmMain_Load)

  [void]$frmMain.ShowDialog()
}

#################################################################################################

$btnFind_Click= {
  $lstFind.Items.Clear()
  if ($txtFind.Text -ne "") {
    #checking items in current snapshot only
    $script:ret | % {
      foreach ($p in (ps -id $_)) {
        foreach ($m in $p.Modules) {
          if ($m.ModuleName -match $txtFind.Text) {
            $itm = $lstFind.Items.Add($p.Name)
            $itm.SubItems.Add($p.Id)
            $itm.SubItems.Add($m.FileName)
          }
        }
      }
    }
  }
}

function frmFind_Show {
  $frmFind = New-Object Windows.Forms.Form
  $txtFind = New-Object Windows.Forms.TextBox
  $btnFind = New-Object Windows.Forms.Button
  $lstFind = New-Object Windows.Forms.ListView
  $chFind1 = New-Object Windows.Forms.ColumnHeader
  $chFind2 = New-Object Windows.Forms.ColumnHeader
  $chFind3 = New-Object Windows.Forms.ColumnHeader
  #
  #txtFind
  #
  $txtFind.Location = New-Object Drawing.Point(13, 13)
  $txtFind.Width = 341
  #
  #btnFind
  #
  $btnFind.Location = New-Object Drawing.Point(361, 12)
  $btnFind.Text = "Search"
  $btnFind.Add_Click($btnFind_Click)
  #
  #lstFind
  #
  $lstFind.Columns.AddRange(@($chFind1, $chFind2, $chFind3))
  $lstFind.FullRowSelect = $false
  $lstFind.Location = New-Object Drawing.Point(13, 43)
  $lstFind.MultiSelect = $false
  $lstFind.Size = New-Object Drawing.Size(421, 190)
  $lstFind.ShowItemToolTips = $true
  $lstFind.View = "Details"
  #
  #chFind1
  #
  $chFind1.Text = "Process"
  $chFind1.Width = 107
  #
  #chFind2
  #
  $chFind2.Text = "PID"
  $chFind2.Width = 45
  #
  #chFind3
  #
  $chFind3.Text = "Name"
  $chFind3.Width = 230
  #
  #frmFind
  #
  $frmFind.ClientSize = New-Object Drawing.Size(447, 255)
  $frmFind.Controls.AddRange(@($txtFind, $btnFind, $lstFind))
  $frmFind.FormBorderStyle = "FixedSingle"
  $frmFind.MaximizeBox = $false
  $frmFind.MinimizeBox = $false
  $frmFind.Text = "Process Snapshot Search"
  $frmFind.ShowInTaskbar = $false
  $frmFind.StartPosition = "CenterParent"

  [void]$frmFind.ShowDialog()
}

#################################################################################################

$empty = "<none>"

function Get-AssembliesTree {
  $dom = [AppDomain]::CurrentDomain
  $tvAssem.Nodes.Clear()

  $dom.GetAssemblies() | % {
    $nod = New-Object Windows.Forms.TreeNode
    $nod.Text = $_.GetName().Name
    $nod.Tag = $_

    $tvAssem.Nodes.Add($nod)
    $nod.Nodes.Add($empty)
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
  $lstView.Items.Clear()
  $sbStats.Text = $_.Node.Tag

  foreach ($p in $_.Node.Tag.PSObject.Properties) {
    $itm = $lstView.Items.Add($p.Name)

    if ($p.Value -ne $null) {
      $itm.Subitems.Add($p.Value.ToString())

      switch ($p.Value) {
        $true  {$itm.ForeColor = "Blue"; break;}
        $false {$itm.ForeColor = "Crimson"; break;}
      }
    }
    else {
      $itm.ForeColor = "Gray"
      $itm.SubItems.Add("<NULL>")
    }
  }
}

function frmAsms_Show {
  $frmAsms = New-Object Windows.Forms.Form
  $mnuMain = New-Object Windows.Forms.MainMenu
  $mnuFile = New-Object Windows.Forms.MenuItem
  $mnuExit = New-Object Windows.Forms.MenuItem
  $scSplit = New-Object Windows.Forms.SplitContainer
  $tvAssem = New-Object Windows.Forms.TreeView
  $lstView = New-Object Windows.Forms.ListView
  $chView1 = New-Object Windows.Forms.ColumnHeader
  $chView2 = New-Object Windows.Forms.ColumnHeader
  $sbStats = New-Object Windows.Forms.StatusBar
  #
  #mnuMain
  #
  $mnuMain.MenuItems.AddRange(@($mnuFile))
  #
  #mnuFile
  #
  $mnuFile.MenuItems.AddRange(@($mnuExit))
  $mnuFile.Text = "&File"
  #
  #mnuExit
  #
  $mnuExit.Shortcut = "CtrlX"
  $mnuExit.Text = "E&xit"
  $mnuExit.Add_Click({$frmAsms.Close()})
  #
  #scSplit
  #
  $scSplit.Dock = "Fill"
  $scSplit.Panel1.Controls.Add($tvAssem)
  $scSplit.Panel2.Controls.Add($lstView)
  $scSplit.SplitterWidth = 1
  #
  #tvAssem
  #
  $tvAssem.Dock = "Fill"
  $tvAssem.Sorted = $true
  $tvAssem.Add_BeforeExpand($tvAssem_BeforeExpand)
  $tvAssem.Add_BeforeSelect($tvAssem_BeforeSelect)
  #
  #lstView
  #
  $lstView.Columns.AddRange(@($chView1, $chView2))
  $lstView.Dock = "Fill"
  $lstView.FullRowSelect = $true
  $lstView.MultiSelect = $false
  $lstView.ShowItemToolTips = $true
  $lstView.Sorting = "Ascending"
  $lstView.View = "Details"
  #
  #chView1
  #
  $chView1.Text = "Name"
  $chView1.Width = 205
  #
  #chView2
  #
  $chView2.Text = "Property Value"
  $chView2.Width = 300
  #
  #sbStats
  #
  $sbStats.SizingGrip = $false
  #
  #frmAsms
  #
  $frmAsms.ClientSize = New-Object Drawing.Size(790, 550)
  $frmAsms.Controls.AddRange(@($scSplit, $sbStats))
  $frmAsms.FormBorderStyle = "FixedSingle"
  $frmAsms.Menu = $mnuMain
  $frmAsms.ShowInTaskbar = $false
  $frmAsms.StartPosition = "CenterParent"
  $frmAsms.Text = "Process Snapshot Loaded Assemblies"
  $frmAsms.Add_Load({Get-AssembliesTree})

  [void]$frmAsms.ShowDialog()
}

#################################################################################################

$frmInfo_Load= {
  $ico = [Drawing.Icon]::ExtractAssociatedIcon($($PSHome + "\powershell.exe"))
  $pbImage.Image = $ico.ToBitmap()
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
  $pbImage.Location = New-Object Drawing.Point(16, 16)
  $pbImage.Size = New-Object Drawing.Size(32, 32)
  $pbImage.SizeMode = "StretchImage"
  #
  #lblName
  #
  $lblName.Font = New-Object Drawing.Font("Microsoft Sans Serif", 9, [Drawing.FontStyle]::Bold)
  $lblName.Location = New-Object Drawing.Point(53, 19)
  $lblName.Size = New-Object Drawing.Size(360, 18)
  $lblName.Text = "Process Snapshot v1.00"
  #
  #lblCopy
  #
  $lblCopy.Location = New-Object Drawing.Point(67, 37)
  $lblCopy.Size = New-Object Drawing.Size(360, 23)
  $lblCopy.Text = "(C) 2013 greg zakharov gregzakh@gmail.com"
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

#################################################################################################

frmMain_Show

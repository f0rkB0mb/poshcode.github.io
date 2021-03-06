#add your translation here
[xml]$res = @'
<?xml version="1.0" encoding="utf-8"?>
<Resources>
  <Menu>
    <File en="&amp;File"
          ru="&amp;&#1060;&#1072;&#1081;&#1083;" />
    <Find en="Find..."
          ru="&#1055;&#1086;&#1080;&#1089;&#1082;..." />
    <Save en="&amp;Save"
          ru="&amp;&#1057;&#1086;&#1093;&#1088;&#1072;&#1085;&#1080;&#1090;&#1100;" />
    <Exit en="E&amp;xit"
          ru="&#1042;&amp;&#1099;&#1093;&#1086;&#1076;" />
    <View en="&amp;View"
          ru="&amp;&#1042;&#1080;&#1076;" />
    <Font en="&amp;Font..."
          ru="&amp;&#1064;&#1088;&#1080;&#1092;&#1090;..." />
    <Wrap en="&amp;Wrap Mode"
          ru="&amp;&#1055;&#1077;&#1088;&#1077;&#1085;&#1086;&#1089; &#1089;&#1090;&#1088;&#1086;&#1082;" />
    <SBar en="&amp;Status Bar"
          ru="&amp;&#1057;&#1090;&#1088;&#1086;&#1082;&#1072; &#1089;&#1086;&#1089;&#1090;&#1086;&#1103;&#1085;&#1080;&#1103;" />
  </Menu>
  <Tools>
    <Label en="Mode:"
           ru="&#1056;&#1077;&#1078;&#1080;&#1084;:"/>
  </Tools>
  <Panel1>
    <Label1 en="Search:"
            ru="&#1055;&#1086;&#1080;&#1089;&#1082;:" />
    <Label2 en="Appearance:"
            ru="&#1057;&#1086;&#1074;&#1087;&#1072;&#1076;&#1077;&#1085;&#1080;&#1103;:" />
    <Button en="Check"
            ru="&#1055;&#1088;&#1086;&#1074;&#1077;&#1088;&#1080;&#1090;&#1100;" />
  </Panel1>
  <Status>
    <Label en="Follow me on twitter "
           ru="&#1063;&#1080;&#1090;&#1072;&#1081;&#1090;&#1077; &#1084;&#1077;&#1085;&#1103; &#1074; &#1090;&#1074;&#1080;&#1090;&#1090;&#1077;&#1088;&#1077; " />
  </Status>
</Resources>
'@

$mnuFind_Click= {
  $toggle =! $mnuFind.Checked
  $mnuFind.Checked = $toggle
  $scSplit.Panel1Collapsed =! $toggle
}

$mnuSave_Click= {
  if ($txtDump.Text -ne "") {
    (New-Object Windows.Forms.SaveFileDialog) | % {
      $_.FileName = (Get-Date -u %d%m%Y_%H%M%S)
      $_.Filter = "Text file (*.txt)|*.txt"
      $_.InitialDirectory = $pwd
      
      if ($_.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
        $txtDump.Text | Out-File $_.FileName -enc UTF8
      }
    }
  }
}

$mnuFont_Click= {
  (New-Object Windows.Forms.FontDialog) | % {
    $_.Font = "Lucida Console"
    $_.MaxSize = 12
    $_.ShowEffects = $false
    
    if ($_.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
      $txtDump.Font = $_.Font
    }
  }
}

$mnuWrap_Click= {
  $toggle =! $mnuWrap.Checked
  $mnuWrap.Checked = $toggle
  $txtDump.WordWrap = $toggle
}

$mnuSBar_Click= {
  $toggle =! $mnuSBar.Checked
  $mnuSBar.Checked = $toggle
  $stStrip.Visible = $toggle
}

$txtFind_TextChanged= {
  $txtDump.Clear()
  $lbMatch.Items.Clear()
  $lbMatch.Items.AddRange(@(gcm -c Application "$($txtFind.Text)*"))
}

$lbMatch_SelectedValueChanged= {
  if (-not [String]::IsNullOrEmpty($lbMatch.SelectedItem)) {
    $str = (gcm -c Application $lbMatch.SelectedItem).Definition
  }
}

$btnDump_Click= {
  $txtDump.Clear()
  $sb = New-Object Text.StringBuilder
  
  switch ($tsCombo.SelectedIndex) {
    "0" {
      sigcheck -q -a -h -i $str | % {$sb.AppendLine($_)}
      $txtDump.Text = $sb.ToString()
    }
    "1" {
      strings -q $str | % {$sb.AppendLine($_)}
      $txtDump.Text = $sb.ToString()
    }
  }
}

function frmMain_Show {
  Add-Type -AssemblyName System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()
  
  $ico = [Drawing.Icon]::ExtractAssociatedIcon(($PSHome + '\powershell.exe'))
  $iso = (Get-Culture).TwoLetterISOLanguageName
  
  $frmMain = New-Object Windows.Forms.Form
  $mnuMain = New-Object Windows.Forms.MenuStrip
  $mnuFile = New-Object Windows.Forms.ToolStripMenuItem
  $mnuFind = New-Object Windows.Forms.ToolStripMenuItem
  $mnuSave = New-Object Windows.Forms.ToolStripMenuItem
  $mnuNull = New-Object Windows.Forms.ToolStripSeparator
  $mnuExit = New-Object Windows.Forms.ToolStripMenuItem
  $mnuView = New-Object Windows.Forms.ToolStripMenuItem
  $mnuFont = New-Object Windows.Forms.ToolStripMenuItem
  $mnuWrap = New-Object Windows.Forms.ToolStripMenuItem
  $mnuSBar = New-Object Windows.Forms.ToolStripMenuItem
  $tsTools = New-Object Windows.Forms.ToolStrip
  $tsLabel = New-Object Windows.Forms.ToolStripLabel
  $tsCombo = New-Object Windows.Forms.ToolStripComboBox
  $scSplit = New-Object Windows.Forms.SplitContainer
  $lblLab1 = New-Object Windows.Forms.Label
  $lblLab2 = New-Object Windows.Forms.Label
  $txtFind = New-Object Windows.Forms.TextBox
  $lbMatch = New-Object Windows.Forms.ListBox
  $btnDump = New-Object Windows.Forms.Button
  $txtDump = New-Object Windows.Forms.TextBox
  $stStrip = New-Object Windows.Forms.StatusStrip
  $stLabel = New-Object Windows.Forms.ToolStripStatusLabel
  #
  #mnuMain
  #
  $mnuMain.Items.AddRange(@($mnuFile, $mnuView))
  #
  #mnuFile
  #
  $mnuFile.DropDownItems.AddRange(@($mnuFind, $mnuSave, $mnuNull, $mnuExit))
  $mnuFile.Text = $res.Resources.Menu.File.$iso
  #
  #mnuFind
  #
  $mnuFind.Checked = $true
  $mnuFind.ShortcutKeys = "Control", "F"
  $mnuFind.Text = $res.Resources.Menu.Find.$iso
  $mnuFind.Add_Click($mnuFind_Click)
  #
  #mnuSave
  #
  $mnuSave.ShortcutKeys = "Control", "S"
  $mnuSave.Text = $res.Resources.Menu.Save.$iso
  $mnuSave.Add_Click($mnuSave_Click)
  #
  #mnuExit
  #
  $mnuExit.ShortcutKeys = "Control", "X"
  $mnuExit.Text = $res.Resources.Menu.Exit.$iso
  $mnuExit.Add_Click({$frmMain.Close()})
  #
  #mnuView
  #
  $mnuView.DropDownItems.AddRange(@($mnuFont, $mnuWrap, $mnuSBar))
  $mnuView.Text = $res.Resources.Menu.View.$iso
  #
  #mnuFont
  #
  $mnuFont.Text = $res.Resources.Menu.Font.$iso
  $mnuFont.Add_Click($mnuFont_Click)
  #
  #mnuWrap
  #
  $mnuWrap.Checked = $true
  $mnuWrap.ShortcutKeys = "Control", "W"
  $mnuWrap.Text = $res.Resources.Menu.Wrap.$iso
  $mnuWrap.Add_Click($mnuWrap_Click)
  #
  #mnuSBar
  #
  $mnuSBar.Checked = $true
  $mnuSBar.ShortcutKeys = "Control", "B"
  $mnuSBar.Text = $res.Resources.Menu.SBar.$iso
  $mnuSBar.Add_Click($mnuSBar_Click)
  #
  #tsTools
  #
  $tsTools.Items.AddRange(@($tsLabel, $tsCombo))
  #
  #tsLabel
  #
  $tsLabel.Text = $res.Resources.Tools.Label.$iso
  #
  #tsCombo
  #
  $tsCombo.Items.AddRange(@('sigcheck', 'strings'))
  $tsCombo.SelectedIndex = 0
  #
  #scSplit
  #
  $scSplit.Dock = "Fill"
  $scSplit.Panel1.Controls.AddRange(@($lblLab1, $txtFind, $lblLab2, $lbMatch, $btnDump))
  $scSplit.Panel2.Controls.Add($txtDump)
  $scSplit.SplitterWidth = 1
  #
  #lblLab1
  #
  $lblLab1.Location = New-Object Drawing.Point(7, 7)
  $lblLab1.Size = New-Object Drawing.Size(110, 15)
  $lblLab1.Text = $res.Resources.Panel1.Label1.$iso
  #
  #txtFind
  #
  $txtFind.Location = New-Object Drawing.Point(7, 23)
  $txtFind.Size = New-Object Drawing.Size(211, 23)
  $txtFind.Add_TextChanged($txtFind_TextChanged)
  #
  #lblLab2
  #
  $lblLab2.Location = New-Object Drawing.Point(7, 47)
  $lblLab2.Size = New-Object Drawing.Size(110, 15)
  $lblLab2.Text = $res.Resources.Panel1.Label2.$iso
  #
  #lbMatch
  #
  $lbMatch.Location = New-Object Drawing.Point(7, 63)
  $lbMatch.Size = New-Object Drawing.Size(211, 310)
  $lbMatch.Add_SelectedValueChanged($lbMatch_SelectedValueChanged)
  #
  #btnDump
  #
  $btnDump.Location = New-Object Drawing.Point(73, 370)
  $btnDump.Text = $res.Resources.Panel1.Button.$iso
  $btnDump.Add_Click($btnDump_Click)
  #
  #txtDump
  #
  $txtDump.Dock = "Fill"
  $txtDump.Multiline = $true
  $txtDump.ScrollBars = "Both"
  #
  #stStrip
  #
  $stStrip.Items.AddRange(@($stLabel))
  $stStrip.SizingGrip = $false
  #
  #stLabel
  #
  $stLabel.Font = New-Object Drawing.Font("Microsoft Sans Serif", 8, [Drawing.FontStyle]::Italic)
  $stLabel.ForeColor = [Drawing.Color]::Crimson
  $stLabel.Text = $res.Resources.Status.Label.$iso + "@gregzakharov"
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(670, 470)
  $frmMain.Controls.AddRange(@($scSplit, $stStrip, $tsTools, $mnuMain))
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.Icon = $ico
  $frmMain.MaximizeBox = $false
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "SIA"
  $frmMain.Add_Load({$lbMatch.Items.AddRange(@(gcm -c Application))})
  
  [void]$frmMain.ShowDialog()
}

#frmMain show condition
if (@(gcm -c Application | ? {$_.Name -match 'sigcheck' -or $_.Name -match 'strings'}).Length -eq 2) {
  frmMain_Show
}
else {
  Write-Warning 'o_Ops!'
}

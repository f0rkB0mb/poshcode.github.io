#requires -version 2.0
function Get-UserStatus {
  $usr = [Security.Principal.WindowsIdentity]::GetCurrent()
  return (New-Object Security.Principal.WindowsPrincipal $usr).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
  )
}

function Get-ImageFromString($img) {
  [Drawing.Image]::FromStream((New-Object IO.MemoryStream(
    ($$ = [Convert]::FromBase64String($img)), 0, $$.Length))
  )
}

function Get-NameSpaces {
  (New-Object Management.ManagementClass(
    'root', [Management.ManagementPath]'__NAMESPACE', (New-Object Management.ObjectGetOptions)
  )).PSBase.GetInstances() | % {
    $nod = New-Object Windows.Forms.TreeNode
    $nod.Text = $_.Name
    
    $tvRoots.Nodes.Add($nod)
    gwmi -NameSpace ('root\' + $_.Name) -Class __NAMESPACE | % {
      try {$nod.Nodes.Add($_.__RELPATH)} catch {}
    }
  }
}

function Reset-InformData {
  $lvList2.Items.Clear()
  $lvList3.Items.Clear()
  $lvList4.Items.Clear()
  $lvList5.Items.Clear()
  
  $chCol_3, $chCol_4, $chCol_5, $chCol_6, $chCol_7, $chCol_8, $chCol_9, $chCol10, $chCol11 | % {
    $_.Width = 10
  }
}

$tvRoots_AfterSelect= {
  Reset-InformData
  $sbLabel.Text = [String]::Empty
  
  if ($tvRoots.SelectedNode) {
    switch ($tvRoots.SelectedNode.Text.StartsWith('_')) {
      $false {
        $lvList1.Items.Clear()
        $script:cur = 'root\' + $tvRoots.SelectedNode.Text
        
        gwmi -NameSpace $cur -List -Amended | % {
          $itm = $lvList1.Items.Add($_.Name, 1)
          try {$itm.SubItems.Add($_.PSBase.Qualifiers.Item("Description").Value)}
          catch {$itm.SubItems.Add("<Not described>")}
        }
        $lvList1.AutoResizeColumns([Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
      }
      default {}
    }
  }
  
  $sbLabel.Text = $cur
}

$lvList1_Click= {
  Reset-InformData
  $sbLabel.Text = $cur
  
  for ($i = 0; $i -lt $lvList1.Items.Count; $i++) {
    if ($lvList1.Items[$i].Selected) {
      $sbLabel.Text += ':' + $lvList1.Items[$i].Text
      $wmi = (gwmi -NameSpace $cur -List $lvList1.Items[$i].Text -Amended).PSBase

      $wmi.Methods | % {
        $itm = $lvList2.Items.Add($_.Name, 2)
        $itm.SubItems.Add($_.Origin)
        try {
          $itm.SubItems.Add($_.PSBase.Qualifiers["Description"].Value)
        }
        catch {
          $itm.SubItems.Add("<Not described>")
        }
      }
      
      $wmi.Properties | % {
        $itm = $lvList3.Items.Add($_.Name, 3)
        $itm.SubItems.Add($_.Type.ToString())
        $itm.SubItems.Add($_.IsLocal.ToString())
        $itm.SubItems.Add($_.IsArray.ToString())
        try {
          $itm.SubItems.Add($_.PSBase.Qualifiers["Description"].Value)
        }
        catch {
          $itm.SubItems.Add("<Not described>")
        }
      }
      
      $wmi.Derivation | % {$lvList4.Items.Add($_, 1)}
      
      $wmi.Qualifiers | % {
        $itm = $lvList5.Items.Add($_.Name, 4)
        $itm.SubItems.Add($_.Value.ToString())
        $itm.SubItems.Add($_.IsAmended.ToString())
        $itm.SubItems.Add($_.IsLocal.ToString())
        $itm.SubItems.Add($_.IsOverridable.ToString())
        $itm.SubItems.Add($_.PropagatesToInstance.ToString())
        $itm.SubItems.Add($_.PropagatesToSubclass.ToString())
      }
    }
  }
  
  $lvList2, $lvList3, $lvList4 | % {
    $_.AutoResizeColumns([Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
  }
}

$mnuSBar_Click= {
  $toggle =! $mnuSBar.Checked
  $mnuSBar.Checked = $toggle
  $sbStrip.Visible = $toggle
}

$frmMain_Load= {
  if (Get-UserStatus) {
    Get-NameSpaces
  }
  else {
    $sbLabel.ForeColor = "Crimson"
    $sbLabel.Text = "Sorry, but you must be an admin."
  }
}

function frmMain_Show {
  Add-Type -Assembly System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()
  #
  #resources
  #
  $ico = [Drawing.Icon]::ExtractAssociatedIcon(($PSHome + '\powershell.exe'))
  #
  #namespace picture
  #
  $img1 = "Qk1mAgAAAAAAADYAAAAoAAAADQAAAA4AAAABABgAAAAAADACAAAAAAAAAAAAAAAAAAAAAAAA//////" + `
          "//////////////////////////////////////////////AP///////////wAAAAAAAAAAAP///wAA" + `
          "AAAAAAAAAP///////////wD///////8AAAAAAAD///////////////////8AAAAAAAD///////8A//" + `
          "//////AAAAAAAA////////////////////AAAAAAAA////////AP///////wAAAAAAAP//////////" + `
          "/////////wAAAAAAAP///////wD///////8AAAAAAAD///////////////////8AAAAAAAD///////" + `
          "8A////////AAAAAAAA////////////////////AAAAAAAA////////AAAAAAAAAAAAAP//////////" + `
          "/////////////////wAAAAAAAAAAAAD///////8AAAAAAAD///////////////////8AAAAAAAD///" + `
          "////8A////////AAAAAAAA////////////////////AAAAAAAA////////AP///////wAAAAAAAP//" + `
          "/////////////////wAAAAAAAP///////wD///////8AAAAAAAD///////////////////8AAAAAAA" + `
          "D///////8A////////////AAAAAAAAAAAA////AAAAAAAAAAAA////////////AP//////////////" + `
          "/////////////////////////////////////wA="
  #
  #class picture
  #
  $img2 = "Qk02BQAAAAAAADYEAAAoAAAAEAAAABAAAAABAAgAAAAAAAABAAAAAAAAAAAAAAABAAAAAQAA////AN" + `
          "ju9gDYm1sA+O7jAMS3rQAUquEA/ez9ANrv9gDTZdIA2+/3AJeAbwCZMwAADGKBAI0tjAAOeJ4A/fD9" + `
          "AP/NmQD97f0A+q36ANxw2wAXmMgAbNbzAPuY+gCF4fUAUMvxAFDL8gA0wO8A997iAOm0fAC1YzUA+v" + `
          "TtABy17QDZbNgAa9f0AB217gA1wPAAHbXtALM8sgCF4PUAhuH0APnw5wD68uoAT8vxABy27gBr1vQA" + `
          "yXNDAIbh9QAvvu8ANMDwAPnx6QD///8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADIyMjIyMjIyMjIAAwAyMjIyMjIyMjIyMjIAMQsDADIyMj" + `
          "IyMjIyMjIyHh0CCwMAMjIyMjIyMjIECgIQHAILAwAyMjIyMjIyBDIDAhAcAgsDMjIyADIyMgQyMgMC" + `
          "EC0oADIyAAcAMjIEMjIyGwIpADIyAAcOBwAyBDIyBg0bADIyAAcOKw4HAAQyBiUTDREAMgEOKhovDA" + `
          "oKCiASFhMNEQAFFyEYMCIMATIGCBIWEw0RAQUuFRkjHwwBMgYIEggGAAAJBSYVGRokDAEADwgPADIy" + `
          "AAkFJywYFAEAMgAPADIyMjIACQUXFAEAMjIyADIyMjIyMgAJBQEAMjIyMjIyMjI="
  #
  #method picture
  #
  $img3 = "Qk3mBAAAAAAAADYEAAAoAAAAEAAAAAsAAAABAAgAAAAAALAAAAAAAAAAAAAAAAABAAAAAQAA0GnPAK" + `
          "61rADw1fAAq/D3APuY+gDvpe4ArNXVALxvuwDy2/IAfi5+AKlQqACePJ4Aq+XpAPPg8gD7q/oAfS18" + `
          "APuZ+gDVb9UAl1KWAN6Y3QDUbtMA+5v6AOzS7ACtu7UAjjWNAK6kmADkyuQA4q/iAOyR6wCqUqkAci" + `
          "RxAO3Y7QDuvu4A+5/6AKzOzAD05vQAj0aOAJFOkADr0esArpmKANJt0QCWOJUA8OPwAO+d7gDz4/MA" + `
          "qE+nAPuu+gCr4uUAp1CmAOjR6AB7K3oA55jmAK6nnADmzOYA46zjAKzEwQDqkOkAgDB/AKpQqQB/MH" + `
          "4AfC58AHUndQDPiM8A////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8/Pz8/Pz8/Pz8/Fh41Pz8/Pz8/Pz8/Pz8/Hwo5PSY/Pz" + `
          "8/Pz8/Pz8/MToACSkyAj8/Ay8iFzQ/GgooFDsLGA8/Pz8/Pz8/Px0AEQcTJAsJPwMMBjcBGT8tKAcF" + `
          "ISsSPD8/Pz8/Pz8/MAcFFQQQMyU/Pz8DBgEnPz4bDgQEOD4jPz8/Pz8/Pz8CPiAuHD4NPz8/Pz8/Pz" + `
          "8/Pwg+Nj4sPz8/Pz8/Pz8/Pz8/CD4qPz8/"
  #
  #property picture
  #
  $img4 = "Qk02BQAAAAAAADYEAAAoAAAAEAAAABAAAAABAAgAAAAAAAABAAAAAAAAAAAAAAABAAAAAQAAxK+iAP" + `
          "///wD7/f8AVE5GAN+dfQBu6/8Aj6SsAP//9gBo7f8AVE9NAPzw6ADRyMEA0sjBAEphcABST0sAS2Fw" + `
          "AP///gACIS4AUk9MAHLh+QAVJzMAQaxTAFdNWQD+/v0Aeo+ZAOfr7QB6zeIA//nsADKy3wAVk8QAKZ" + `
          "c/ANnPyABhwd4AMDpPAP/l1gDCyNAA+OLSAKOsuABZeFsA+/TvAHx1cwCnkokAMp5BADG76gBdXGAA" + `
          "adv2AFOElQBXa4AAwsrOAH/j+QDf5OUA/d7LAP328gDRx8AAUmBnANq6qgC/yM0A/8WkAEBmUQCTtp" + `
          "kAhcyFAP/w4QCa06QAEajsAGrd9wD/6tIAGIwyAP77+ACAl6MAXnWEAAsQGwBccYAAHGYpAP/p3ABp" + `
          "nIkALqnWAPvu5gD/7eMAW21/AFjS8wCBprUAU1BMAIPh9gCknZYA/+LQACK6+gCw6/oAEAcKAP36+A" + `
          "BBPVAAT1ZlAEvH7QBYmK4AcMF9APHKtwD/6tUAcuL6AP7+/ABfoqYA//78ABRijgBRTksA+uneALCt" + `
          "rAD/+/kAQVxyANPJwgBWz/IAVL3cANTZ3QBOS0sAgJagAFCQjABAw+0AZ9f0AOXJuQBRcosAlbjEAO" + `
          "PZ0wBzhZMA4unpAIbT5QAdmcgAVlFNAB/Q/wD///8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAH19fX19fX19fX19fX19fX0obgkJCXtRDhIOZQN9fX19Hw" + `
          "ECAgcHBxs9X0EDfX19fQwBAABoAAAAAAAzA319fX0MAQICY1gnTGYkVAN9fX19agEAABAAAAAAACID" + `
          "fX19fTUBAgIBF0M0CgpJA319fX0LAQICAQFhZ2l2TQN9fX19CwF4RTIBMA1LRixTfX07SAReBnkPKQ" + `
          "0gFnwUVxFaJkIEOXMGUg8aNghZHHodZDoeBAQENwYxLgghLU9xKz9wKn19fX0ZLwhcBRNAa1tVYhV9" + `
          "fX19I1ZOBQUFYHJsdEo8fX19fSV1bVBEbxh3Rzg+XX19fX19fX19fX19fX19fX0="
  #
  #qualifier picture
  #
  $img5 = "Qk32AgAAAAAAADYAAAAoAAAADgAAABAAAAABABgAAAAAAMACAAAAAAAAAAAAAAAAAAAAAAAA4evr//" + `
          "//////////////////////////////////////////////////AACZqKyZqKyZqKyZqKyZqKyZqKyZ" + `
          "qKyZqKyZqKyZqKyZqKyZqKyZqKz///8AAJmorP///+Ts7eTs7eTs7eTs7eTs7eTs7eTs7OTs7OTs7O" + `
          "Ps7JmorP///wAAmais////5+7u5+7v5+7v5+7v////////////////5+7u5u7umais////AACZqKz/" + `
          "///n7u7n7u/n7u+ZqKyZqKyZqKyZqKzn7u7n7u7m7u6ZqKz///8AAJmorP///+rw7+rw7////5morP" + `
          "///////////////+rw7+rv75morP///wAAmais////6vDvmaismaismaismaismaismais6vDv6vDv" + `
          "6u/vmais////AACZqKz////s8fCZqKz////////////////////////s8fHs8fGZqKz///8AAJmorP" + `
          "///+zx8JmorJmorJmorJmorJmorJmorOzx8ezx8ezx8ZmorP///wAAmais////7/Lwmais////7/Lx" + `
          "////////////////7vLx7/Lwmais////AACZqKz////v8vCZqKz///+ZqKyZqKyZqKyZqKzu8vHu8v" + `
          "Hv8vCZqKz///8AAJmorP////Dz8ZmorP///5morP////////////////Dz8f///5morP///wAAmais" + `
          "////8PPxmaismaismaismaismaismais8PPxmaismaismais7/PxAACZqKz////09PL19PP19PP19P" + `
          "P09PP09PP09PP09POZqKyZqKz08/P08/MAAJmorP///////////////////////////////////5mo" + `
          "rPTz8/Tz8/Tz8wAAmaismaismaismaismaismaismaismaismaismais9PTy9PTz9PTz9PTzAAA="
  #
  #form objects
  #
  $frmMain = New-Object Windows.Forms.Form
  $mnuMain = New-Object Windows.Forms.MenuStrip
  $mnuFile = New-Object Windows.Forms.ToolStripMenuItem
  $mnuExit = New-Object Windows.Forms.ToolStripmenuItem
  $mnuView = New-Object Windows.Forms.ToolStripMenuItem
  $mnuSBar = New-Object Windows.Forms.ToolStripMenuItem
  $mnuHelp = New-Object Windows.Forms.ToolStripMenuItem
  $mnuInfo = New-Object Windows.Forms.ToolStripMenuItem
  $scSplt1 = New-Object Windows.Forms.SplitContainer
  $scSplt2 = New-Object Windows.Forms.SplitContainer
  $tvRoots = New-Object Windows.Forms.TreeView
  $lvList1 = New-Object Windows.Forms.ListView
  $lvList2 = New-Object Windows.Forms.ListView
  $lvList3 = New-Object Windows.Forms.ListView
  $lvList4 = New-Object Windows.Forms.ListView
  $lvList5 = New-Object Windows.Forms.ListView
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
  $chCol16 = New-Object Windows.Forms.ColumnHeader
  $chCol17 = New-Object Windows.Forms.ColumnHeader
  $chCol18 = New-Object Windows.Forms.ColumnHeader
  $tabCtrl = New-Object Windows.Forms.TabControl
  $tpPage1 = New-Object Windows.Forms.TabPage
  $tpPage2 = New-Object Windows.Forms.TabPage
  $tpPage3 = New-Object Windows.Forms.TabPage
  $tpPage4 = New-Object Windows.Forms.TabPage
  $imgList = New-Object Windows.Forms.ImageList
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
  $mnUFile.Text = "&File"
  #
  #mnuExit
  #
  $mnuExit.ShortcutKeys = "Control", "X"
  $mnuExit.Text = "E&xit"
  $mnuExit.Add_Click({$frmMain.Close()})
  #
  #mnuView
  #
  $mnuView.DropDownItems.AddRange(@($mnuSBar))
  $mnuView.Text = "&View"
  #
  #mnuSBar
  #
  $mnuSbar.Checked = $true
  $mnuSBar.Text = "&Status Bar"
  $mnuSBar.Add_Click($mnuSBar_Click)
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
  $scSplt1.Orientation = "Horizontal"
  $scSplt1.Panel1.Controls.Add($scSplt2)
  $scSplt1.Panel2.Controls.Add($tabCtrl)
  $scSplt1.Panel2MinSize = 17
  $scSplt1.SplitterDistance = 330
  $scSplt1.SplitterWidth = 1
  #
  #scSplt2
  #
  $scSplt2.Dock = "Fill"
  $scSplt2.Panel1.Controls.Add($tvRoots)
  $scSplt2.Panel2.Controls.Add($lvList1)
  $scSplt2.Panel1MinSize = 17
  $scSplt2.SplitterDistance = 30
  $scSplt2.SplitterWidth = 1
  #
  #tabCtrl
  #
  $tabCtrl.Controls.AddRange(@($tpPage1, $tpPage2, $tpPage3, $tpPage4))
  $tabCtrl.Dock = "Fill"
  #
  #tpPage1
  #
  $tpPage1.Controls.AddRange(@($lvList2))
  $tpPage1.Text = "Methods"
  $tpPage1.UseVisualStyleBackColor = $true
  #
  #lvList2
  #
  $lvList2.AllowColumnReorder = $true
  $lvList2.Columns.AddRange(@($chCol_3, $chCol_4, $chCol_5))
  $lvList2.Dock = "Fill"
  $lvList2.FullRowSelect = $true
  $lvList2.MultiSelect = $false
  $lvList2.ShowItemToolTips = $true
  $lvList2.SmallImageList = $imgList
  $lvList2.Sorting = "Ascending"
  $lvList2.View = "Details"
  #
  #chCol_3
  #
  $chCol_3.Text = "Name"
  $chCol_3.Width = 10
  #
  #chCol_4
  #
  $chCol_4.Text = "Origin"
  $chCol_4.Width = 10
  #
  #chCol_5
  #
  $chCol_5.Text = "Description"
  $chCol_5.Width = 10
  #
  #tpPage2
  #
  $tpPage2.Controls.AddRange(@($lvList3))
  $tpPage2.Text = "Properties"
  $tpPage2.UseVisualStyleBackColor = $true
  #
  #lvList3
  #
  $lvList3.AllowColumnReorder = $true
  $lvList3.Columns.AddRange(@($chCol_6, $chCol_7, $chCol_8, $chCol_9, $chCol10))
  $lvList3.Dock = "Fill"
  $lvList3.FullRowSelect = $true
  $lvList3.MultiSelect = $false
  $lvList3.ShowItemToolTips = $true
  $lvList3.SmallImageList = $imgList
  $lvList3.Sorting = "Ascending"
  $lvList3.View = "Details"
  #
  #chCol_6
  #
  $chCol_6.Text = "Name"
  $chCol_6.Width = 10
  #
  #chCol_7
  #
  $chCol_7.Text = "Type"
  $chCol_7.Width = 10
  #
  #chCol_8
  #
  $chCol_8.Text = "IsLocal"
  $chCol_8.Width = 10
  #
  #chCol_9
  #
  $chCol_9.Text = "IsArray"
  $chCol_9.Width = 10
  #
  #chCol10
  #
  $chCol10.Text = "Description"
  $chCol10.Width = 10
  #
  #tpPage3
  #
  $tpPage3.Controls.AddRange(@($lvList4))
  $tpPage3.Text = "Derivation"
  $tpPage3.UseVisualStyleBackColor = $true
  #
  #lvList4
  #
  $lvList4.Columns.AddRange(@($chCol11))
  $lvList4.Dock = "Fill"
  $lvList4.FullRowSelect = $true
  $lvList4.MultiSelect = $false
  $lvList4.SmallImageList = $imgList
  $lvList4.View = "Details"
  #
  #chCol11
  #
  $chCol11.Text = "Class"
  $chCol11.Width = 10
  #
  #tpPage4
  #
  $tpPage4.Controls.AddRange(@($lvList5))
  $tpPage4.Text = "Qualifiers"
  $tpPage4.UseVisualStyleBackColor = $true
  #
  #lvList5
  #
  $lvList5.AllowColumnReorder = $true
  $lvList5.Columns.AddRange(@($chCol12, $chCol13, $chCol14, $chCol15, $chCol16, $chCol17, $chCol18))
  $lvList5.Dock = "Fill"
  $lvList5.FullRowSelect = $true
  $lvList5.MultiSelect = $false
  $lvList5.ShowItemToolTips = $true
  $lvList5.SmallImageList = $imgList
  $lvList5.Sorting = "Ascending"
  $lvList5.View = "Details"
  #
  #chCol12
  #
  $chCol12.Text = "Name"
  $chCol12.Width = 170
  #
  #chCol13
  #
  $chCol13.Text = "Value"
  $chCol13.Width = 130
  #
  #chCol14
  #
  $chCol14.Text = "IsAmended"
  $chCol14.Width = 70
  #
  #chCol15
  #
  $chCol15.Text = "IsLocal"
  $chCol15.Width = 50
  #
  #chCol16
  #
  $chCol16.Text = "IsOverridable"
  $chCol16.Width = 80
  #
  #chCol17
  #
  $chCol17.Text = "PropagatesToInstance"
  $chCol17.Width = 130
  #
  #chCol18
  #
  $chCol18.Text = "PropagatesToSubclass"
  $chCol18.Width = 130
  #
  #tvRoots
  #
  $tvRoots.Dock = "Fill"
  $tvRoots.ImageList = $imgList
  $tvRoots.Select()
  $tvRoots.SelectedImageIndex = 0
  $tvRoots.Sorted = $true
  $tvRoots.Add_AfterSelect($tvRoots_AfterSelect)
  #
  #lvList1
  #
  $lvList1.AllowColumnReorder = $true
  $lvList1.Columns.AddRange(@($chCol_1, $chCol_2))
  $lvList1.Dock = "Fill"
  $lvList1.FullRowSelect = $true
  $lvList1.MultiSelect = $false
  $lvList1.ShowItemToolTips = $true
  $lvList1.SmallImageList = $imgList
  $lvList1.Sorting = "Ascending"
  $lvList1.View = "Details"
  $lvList1.Add_Click($lvList1_Click)
  #
  #chCol_1
  #
  $chCol_1.Text = "Class"
  $chCol_1.Width = 170
  #
  #chCol_2
  #
  $chCol_2.Text = "Description"
  $chCol_2.Width = 10
  #
  #imgList
  #
  $img1, $img2, $img3, $img4, $img5 | % {$imgList.Images.Add((Get-ImageFromString $_))}
  #
  #sbStrip
  #
  $sbStrip.Items.AddRange(@($sbLabel))
  #
  #sbLabel
  #
  $sbLabel.AutoSize = $true
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(800, 600)
  $frmMain.Controls.AddRange(@($scSplt1, $sbStrip, $mnuMain))
  $frmMain.Icon = $ico
  $frmMain.MainMenuStrip = $mnuMain
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "WMI Explorer"
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
  $lblName.Text = "WMI Explorer v2.00"
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

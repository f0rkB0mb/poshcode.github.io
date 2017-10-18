<#

		.NOTES
		Name     : Get-Checksum GUI
		Author   : Bryan Jaudon <bryan.jaudon@gmail.com>
		Version  : 1.2
		Date	 : 9/14/2012

		.SYNOPSIS
		GUI file checksum calculation script.

#>

#requires -version 2

$ScriptVersion="1.2"

#Check if Powershell is running in MTA or STA mode. STA is required for DragDrop registration.
if ([threading.thread]::CurrentThread.GetApartmentState() -eq "MTA") {
   Write-Warning "Powershell running as Multi Thread Apartment (MTA). Calling new instance in Single Thread Apartment (STA)."
   & $env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe -sta -noprofile -nologo -file $MyInvocation.MyCommand.Path
   return
}

$code = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;

namespace System
{
	public class IconExtractor
	{

	 public static Icon Extract(string file, int number, bool largeIcon)
	 {
	  IntPtr large;
	  IntPtr small;
	  ExtractIconEx(file, number, out large, out small, 1);
	  try
	  {
	   return Icon.FromHandle(largeIcon ? large : small);
	  }
	  catch
	  {
	   return null;
	  }

	 }
	 [DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
	 private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);

	}
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing

$os=Get-WmiObject win32_OperatingSystem
if ($os.version[0] -ge 6) { $icon=[System.IconExtractor]::Extract("shell32.dll",144,$true) } #Checkmark icon in Windows Vista/7/8
else { $icon=[System.IconExtractor]::Extract("shell32.dll",253,$true) } #File checkmark icon in Windows XP


#Generated Form Function

#region Import the Assemblies
    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
    [reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
    [System.Windows.Forms.Application]::EnableVisualStyles()
#endregion

function GenerateForm {
    ########################################################################
    # Code Generated By: SAPIEN Technologies PrimalForms (Community Edition) v1.0.10.0
    # Generated On: 9/10/2012 1:51 PM
    # Generated By: bjaudon
    ########################################################################

    #region Generated Form Objects
    $frmGetChecksum = New-Object System.Windows.Forms.Form
    $lblComputing = New-Object System.Windows.Forms.Label
    $btnCompute = New-Object System.Windows.Forms.Button
    $btnExit = New-Object System.Windows.Forms.Button
    $gbCommandOutput = New-Object System.Windows.Forms.GroupBox
    $rtbCommandOutput = New-Object System.Windows.Forms.RichTextBox
    $lblMatchHash = New-Object System.Windows.Forms.Label
    $tbMatchHash = New-Object System.Windows.Forms.TextBox
    $gbAlgorithms = New-Object System.Windows.Forms.GroupBox
    $rbRIPEMD160 = New-Object System.Windows.Forms.RadioButton
    $rbSHA512 = New-Object System.Windows.Forms.RadioButton
    $rbSHA384 = New-Object System.Windows.Forms.RadioButton
    $rbSHA256 = New-Object System.Windows.Forms.RadioButton
    $rbSHA1 = New-Object System.Windows.Forms.RadioButton
    $rbMD5 = New-Object System.Windows.Forms.RadioButton
    $btnBrowse = New-Object System.Windows.Forms.Button
    $tbSourceFile = New-Object System.Windows.Forms.TextBox
    $lblSourceFile = New-Object System.Windows.Forms.Label
    $lblVersion = New-Object System.Windows.Forms.Label
    $openFileDialog1 = New-Object System.Windows.Forms.OpenFileDialog
    $pbIcon = New-Object System.Windows.Forms.PictureBox
    $InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
    #endregion Generated Form Objects

    #----------------------------------------------
    #Generated Event Script Blocks
    #----------------------------------------------
    #Provide Custom Code for events specified in PrimalForms.

    $btnCompute_OnClick= 
    {
        
    
        if ($rbMD5.Checked) { $HashAlgorithm="MD5" }
        elseif ($rbSHA1.Checked) { $HashAlgorithm="SHA1" }
        elseif ($rbSHA256.Checked) { $HashAlgorithm="SHA256" }
        elseif ($rbSHA384.Checked) { $HashAlgorithm="SHA384" }
        elseif ($rbSHA512.Checked) { $HashAlgorithm="SHA512" }
        elseif ($rbRIPEMD160.Checked) { $HashAlgorithm="RIPEMD160" }
        else { $HashAlgorithm="MD5" }

        $SplatParameter=@{
            "FileName"=$tbSourceFile.Text
            "HashAlgorithm"=$HashAlgorithm
            "MatchHash"=$tbMatchHash.Text 
        }

        DisableButtons

        Start-Sleep -Milliseconds .25
        
        try { $Output=Get-Checksum @SplatParameter }
        catch { [System.Windows.Forms.MessageBox]::Show($Error[1],"Get-Checksum GUI","OK","Error");EnableButtons;Return }
        
        $FontBold = new-object System.Drawing.Font("Microsoft Sans Serif",8,[Drawing.FontStyle]'Bold' )
        $fontNormal = new-object System.Drawing.Font("Microsoft Sans Serif",8,[Drawing.FontStyle]'Regular')

        $rtbCommandOutput.Font = $fontNormal
        $rtbCommandOutput.DetectUrls = $False

        $outputmembers = $output | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"} | Select Name

        $outputmembers | foreach {
            $rtbCommandOutput.SelectionFont = $FontBold
            $rtbCommandOutput.AppendText("$($_.Name)`t")
            if ($_.Name -eq "Length") { $rtbCommandOutput.AppendText("`t") }
            $rtbCommandOutput.SelectionFont = $fontNormal
            $rtbCommandOutput.AppendText(" : $($output.($_.Name))")
            if ($_.Name -eq "Length") { $rtbCommandOutput.AppendText(" bytes") }
            $rtbCommandOutput.AppendText("`n")
        }

        
        for ($i=231;$i -le 393; $i++) {
    
            $System_Drawing_Size.Height = $i
            $System_Drawing_Size.Width = 585
            $frmGetChecksum.ClientSize = $System_Drawing_Size
            Start-Sleep -Milliseconds .1
        }
        
        EnableButtons
        
        $btnBrowse.Focus()

    }

    $btnBrowse_OnClick= 
    {
        #TODO: Place custom script here
        $tbSourceFile.Text=OpenFile-Dialog
        if ($tbSourceFile.Text -eq "") { $btnCompute.Enabled = $false }
        else { $btnCompute.Enabled = $True }
    }


    $OnLoadForm_StateCorrection=
    {
        #Correct the initial state of the form to prevent the .Net maximized form issue
	    $frmGetChecksum.WindowState = $InitialFormWindowState
        $btnBrowse.Focus()
    }

    #----------------------------------------------
    #region Generated Form Code
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 231
    $System_Drawing_Size.Width = 585
    $frmGetChecksum.ClientSize = $System_Drawing_Size
    $frmGetChecksum.DataBindings.DefaultDataSourceUpdateMode = 0
    $frmGetChecksum.FormBorderStyle = 1
    $frmGetChecksum.MaximizeBox = $False
    $frmGetChecksum.Name = "frmGetChecksum"
    $frmGetChecksum.Text = "Get-Checksum GUI"
    $frmGetChecksum.Icon = $icon
    $frmGetChecksum.AllowDrop = $true #Parameter requires STA mode
    $frmGetChecksum.Add_DragEnter({ProcessDragDrop($_)})
    
    $pbIcon.DataBindings.DefaultDataSourceUpdateMode = 0
    
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 13
    $System_Drawing_Point.Y = 13
    $pbIcon.Location = $System_Drawing_Point
    $pbIcon.Name = "pictureBox1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 32
    $System_Drawing_Size.Width = 32
    $pbIcon.Size = $System_Drawing_Size
    $pbIcon.TabIndex = 0
    $pbIcon.TabStop = $False
    $pbIcon.Image = $icon

    $frmGetChecksum.Controls.Add($pbIcon)


    $lblComputing.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 19
    $System_Drawing_Point.Y = 197
    $lblComputing.Location = $System_Drawing_Point
    $lblComputing.Name = "lblComputing"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 157
    $lblComputing.Size = $System_Drawing_Size
    $lblComputing.TabIndex = 10
    $lblComputing.Text = "Computing, Please Wait..."
    $lblComputing.Visible = $false
    $lblComputing.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",8.25,1,3,0)
    $lblComputing.ForeColor = [System.Drawing.Color]::FromArgb(255,255,0,0)

    $frmGetChecksum.Controls.Add($lblComputing)


    $btnCompute.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 415
    $System_Drawing_Point.Y = 197
    $btnCompute.Location = $System_Drawing_Point
    $btnCompute.Name = "btnCompute"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 75
    $btnCompute.Size = $System_Drawing_Size
    $btnCompute.TabIndex = 10
    $btnCompute.Text = "&Compute"
    $btnCompute.UseVisualStyleBackColor = $True
    $btnCompute.Enabled = $false
    $btnCompute.add_Click($btnCompute_OnClick)
    $btnCompute.FlatStyle = 0

    $frmGetChecksum.Controls.Add($btnCompute)


    $btnExit.DataBindings.DefaultDataSourceUpdateMode = 0
    $btnExit.DialogResult = 2

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 496
    $System_Drawing_Point.Y = 197
    $btnExit.Location = $System_Drawing_Point
    $btnExit.Name = "btnExit"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 75
    $btnExit.Size = $System_Drawing_Size
    $btnExit.TabIndex = 11
    $btnExit.Text = "E&xit"
    $btnExit.UseVisualStyleBackColor = $True
    $btnExit.FlatStyle = 0

    $frmGetChecksum.Controls.Add($btnExit)


    $gbCommandOutput.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 13
    $System_Drawing_Point.Y = 226
    $gbCommandOutput.Location = $System_Drawing_Point
    $gbCommandOutput.Name = "gbCommandOutput"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 156
    $System_Drawing_Size.Width = 558
    $gbCommandOutput.Size = $System_Drawing_Size
    $gbCommandOutput.TabIndex = 99
    $gbCommandOutput.TabStop = $False
    $gbCommandOutput.Text = "Command Output"
    $gbCommandOutput.Visible = $False

    $frmGetChecksum.Controls.Add($gbCommandOutput)
    $rtbCommandOutput.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 9
    $System_Drawing_Point.Y = 20
    $rtbCommandOutput.Location = $System_Drawing_Point
    $rtbCommandOutput.Name = "rtbCommandOutput"
    $rtbCommandOutput.ReadOnly = $True
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 125
    $System_Drawing_Size.Width = 539
    $rtbCommandOutput.Size = $System_Drawing_Size
    $rtbCommandOutput.TabIndex = 100
    $rtbCommandOutput.Text = ""
    $rtbCommandOutput.TabStop = $False
    $rtbCommandOutput.BorderStyle = 0
    
    $gbCommandOutput.Controls.Add($rtbCommandOutput)


    $lblMatchHash.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 13
    $System_Drawing_Point.Y = 165
    $lblMatchHash.Location = $System_Drawing_Point
    $lblMatchHash.Name = "lblMatchHash"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 20
    $System_Drawing_Size.Width = 80
    $lblMatchHash.Size = $System_Drawing_Size
    $lblMatchHash.TabIndex = 99
    $lblMatchHash.Text = "Match Hash:"
    $lblMatchHash.add_Click($handler_label3_Click)

    $frmGetChecksum.Controls.Add($lblMatchHash)

    $tbMatchHash.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 96
    $System_Drawing_Point.Y = 163
    $tbMatchHash.Location = $System_Drawing_Point
    $tbMatchHash.Name = "tbMatchHash"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 20
    $System_Drawing_Size.Width = 475
    $tbMatchHash.Size = $System_Drawing_Size
    $tbMatchHash.TabIndex = 8
    $tbMatchHash.BorderStyle = 1

    $frmGetChecksum.Controls.Add($tbMatchHash)


    $gbAlgorithms.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 13
    $System_Drawing_Point.Y = 96
    $gbAlgorithms.Location = $System_Drawing_Point
    $gbAlgorithms.Name = "gbAlgorithms"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 56
    $System_Drawing_Size.Width = 558
    $gbAlgorithms.Size = $System_Drawing_Size
    $gbAlgorithms.TabIndex = 2
    $gbAlgorithms.TabStop = $False
    $gbAlgorithms.Text = "Hash Algorithms"

    $frmGetChecksum.Controls.Add($gbAlgorithms)

    $rbRIPEMD160.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 412
    $System_Drawing_Point.Y = 20
    $rbRIPEMD160.Location = $System_Drawing_Point
    $rbRIPEMD160.Name = "rbRIPEMD160"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 24
    $System_Drawing_Size.Width = 104
    $rbRIPEMD160.Size = $System_Drawing_Size
    $rbRIPEMD160.TabIndex = 7
    $rbRIPEMD160.TabStop = $True
    $rbRIPEMD160.Text = "&RIPEMD160"
    $rbRIPEMD160.UseVisualStyleBackColor = $True
    $rbRIPEMD160.FlatStyle = 1

    $gbAlgorithms.Controls.Add($rbRIPEMD160)


    $rbSHA512.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 329
    $System_Drawing_Point.Y = 20
    $rbSHA512.Location = $System_Drawing_Point
    $rbSHA512.Name = "rbSHA512"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 24
    $System_Drawing_Size.Width = 72
    $rbSHA512.Size = $System_Drawing_Size
    $rbSHA512.TabIndex = 6
    $rbSHA512.TabStop = $True
    $rbSHA512.Text = "SHA&512"
    $rbSHA512.UseVisualStyleBackColor = $True
    $rbSHA512.FlatStyle = 1

    $gbAlgorithms.Controls.Add($rbSHA512)


    $rbSHA384.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 247
    $System_Drawing_Point.Y = 20
    $rbSHA384.Location = $System_Drawing_Point
    $rbSHA384.Name = "rbSHA384"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 24
    $System_Drawing_Size.Width = 76
    $rbSHA384.Size = $System_Drawing_Size
    $rbSHA384.TabIndex = 5
    $rbSHA384.TabStop = $True
    $rbSHA384.Text = "SHA&384"
    $rbSHA384.UseVisualStyleBackColor = $True
    $rbSHA384.FlatStyle = 1

    $gbAlgorithms.Controls.Add($rbSHA384)


    $rbSHA256.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 169
    $System_Drawing_Point.Y = 20
    $rbSHA256.Location = $System_Drawing_Point
    $rbSHA256.Name = "rbSHA256"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 24
    $System_Drawing_Size.Width = 72
    $rbSHA256.Size = $System_Drawing_Size
    $rbSHA256.TabIndex = 4
    $rbSHA256.TabStop = $True
    $rbSHA256.Text = "SHA&256"
    $rbSHA256.UseVisualStyleBackColor = $True
    $rbSHA256.FlatStyle = 1

    $gbAlgorithms.Controls.Add($rbSHA256)


    $rbSHA1.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 99
    $System_Drawing_Point.Y = 20
    $rbSHA1.Location = $System_Drawing_Point
    $rbSHA1.Name = "rbSHA1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 24
    $System_Drawing_Size.Width = 64
    $rbSHA1.Size = $System_Drawing_Size
    $rbSHA1.TabIndex = 3
    $rbSHA1.TabStop = $True
    $rbSHA1.Text = "SHA&1"
    $rbSHA1.UseVisualStyleBackColor = $True
    $rbSHA1.FlatStyle = 1

    $gbAlgorithms.Controls.Add($rbSHA1)


    $rbMD5.Checked = $True
    $rbMD5.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 36
    $System_Drawing_Point.Y = 20
    $rbMD5.Location = $System_Drawing_Point
    $rbMD5.Name = "rbMD5"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 24
    $System_Drawing_Size.Width = 57
    $rbMD5.Size = $System_Drawing_Size
    $rbMD5.TabIndex = 2
    $rbMD5.TabStop = $True
    $rbMD5.Text = "M&D5"
    $rbMD5.UseVisualStyleBackColor = $True
    $rbMD5.FlatStyle = 1

    $gbAlgorithms.Controls.Add($rbMD5)



    $btnBrowse.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 496
    $System_Drawing_Point.Y = 65
    $btnBrowse.Location = $System_Drawing_Point
    $btnBrowse.Name = "btnBrowse"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 75
    $btnBrowse.Size = $System_Drawing_Size
    $btnBrowse.TabIndex = 1
    $btnBrowse.Text = "&Browse..."
    $btnBrowse.UseVisualStyleBackColor = $True
    $btnBrowse.add_Click($btnBrowse_OnClick)
    $btnBrowse.FlatStyle = 0

    $frmGetChecksum.Controls.Add($btnBrowse)

    $tbSourceFile.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 96
    $System_Drawing_Point.Y = 67
    $tbSourceFile.Location = $System_Drawing_Point
    $tbSourceFile.Name = "tbSourceFile"
    $tbSourceFile.ReadOnly = $True
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 20
    $System_Drawing_Size.Width = 394
    $tbSourceFile.Size = $System_Drawing_Size
    $tbSourceFile.TabIndex = 99
    $tbSourceFile.TabStop = $False
    $tbSourceFile.BorderStyle = 1
    $tbSourceFile.AccessibleDescription

    $frmGetChecksum.Controls.Add($tbSourceFile)

    $lblSourceFile.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 13
    $System_Drawing_Point.Y = 67
    $lblSourceFile.Location = $System_Drawing_Point
    $lblSourceFile.Name = "lblSourceFile"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 20
    $System_Drawing_Size.Width = 77
    $lblSourceFile.Size = $System_Drawing_Size
    $lblSourceFile.TabIndex = 1
    $lblSourceFile.Text = "Source File:"
    $lblSourceFile.add_Click($handler_label2_Click)

    $frmGetChecksum.Controls.Add($lblSourceFile)

    $lblVersion.DataBindings.DefaultDataSourceUpdateMode = 0

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 50
    $System_Drawing_Point.Y = 20
    $lblVersion.Location = $System_Drawing_Point
    $lblVersion.Name = "lblVersion"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Height = 23
    $System_Drawing_Size.Width = 500
    $lblVersion.Size = $System_Drawing_Size
    $lblVersion.TabIndex = 0
    $lblVersion.Text = "PowerShell Get-Checksum GUI v.$scriptversion"
    $lblVersion.Font = New-Object System.Drawing.Font("Trebuchet MS",9,1,3,0)

    $frmGetChecksum.Controls.Add($lblVersion)

    $openFileDialog1.DefaultExt = "*.*"
    $openFileDialog1.Filter = "All Files (*.*)|*.*"
    $openFileDialog1.Title = "Get-Checksum: Select File"
    $openFileDialog1.ShowHelp = $True

    #endregion Generated Form Code

    #Save the initial state of the form
    $InitialFormWindowState = $frmGetChecksum.WindowState
    #Init the OnLoad event to correct the initial state of the form
    $frmGetChecksum.add_Load($OnLoadForm_StateCorrection)
    #Show the Form
    $frmGetChecksum.ShowDialog()| Out-Null

} #End Function

function DisableButtons {
    $System_Drawing_Size.Height = 231
    $System_Drawing_Size.Width = 585
    $frmGetChecksum.ClientSize = $System_Drawing_Size
    $rtbCommandOutput.Text=$null
  
    $rtbCommandOutput.Visible = $false
    $gbCommandOutput.Visible = $false

    $lblComputing.Visible = $True
    $lblComputing.Update()

    $lblMatchHash.Enabled = $False
    $lblMatchHash.Update()
    $tbMatchHash.Enabled = $False
    $tbMatchHash.Update()
    $btnBrowse.Enabled = $False
    $btnBrowse.Update()
    $lblSourceFile.Enabled = $False
    $lblSourceFile.Update()
    $tbSourceFile.Enabled = $False
    $tbSourceFile.Update()
    $btnExit.Enabled = $False
    $btnExit.Update()
    $btnCompute.Enabled = $False
    $btnCompute.Update()
    $gbAlgorithms.Enabled = $False
    $gbAlgorithms.Update()
    $rbMD5.Enabled = $False
    $rbMD5.Update()
    $rbSHA1.Enabled = $False
    $rbSHA1.Update()
    $rbSHA256.Enabled = $False
    $rbSHA256.Update()
    $rbSHA384.Enabled = $False
    $rbSHA384.Update()
    $rbSHA512.Enabled = $False
    $rbSHA512.Update()
    $rbRIPEMD160.Enabled = $False
    $rbRIPEMD160.Update()
    
}

Function EnableButtons {
    
    $lblComputing.Visible = $False
    $lblComputing.Update()
    $lblMatchHash.Enabled = $True
    $lblMatchHash.Update()
    $tbMatchHash.Enabled = $True
    $tbMatchHash.Update()
    $btnBrowse.Enabled = $True
    $btnBrowse.Update()
    $lblSourceFile.Enabled = $True
    $lblSourceFile.Update()
    $tbSourceFile.Enabled = $True
    $tbSourceFile.Update()
    $btnExit.Enabled = $True
    $btnExit.Update()
    $btnCompute.Enabled = $True
    $btnCompute.Update()
    $gbAlgorithms.Enabled = $True
    $gbAlgorithms.Update()
    $rbMD5.Enabled = $True
    $rbMD5.Update()
    $rbSHA1.Enabled = $True
    $rbSHA1.Update()
    $rbSHA256.Enabled = $True
    $rbSHA256.Update()
    $rbSHA384.Enabled = $True
    $rbSHA384.Update()
    $rbSHA512.Enabled = $True
    $rbSHA512.Update()
    $rbRIPEMD160.Enabled = $True
    $rbRIPEMD160.Update()
    $rtbCommandOutput.Visible = $true
    $gbCommandOutput.Visible = $true
    
}

Function OpenFile-Dialog {
    $open=$OpenFileDialog1.ShowDialog()
    #If the Open button is pressed
    if ($open -eq "OK") { 
       
        #Set our source to the chosen file
        return $OpenFileDialog1.FileName
        
    }
    #If cancel is pressed
    else { return }
}

Function Get-Checksum {
	
		
	[CmdletBinding()]
	Param(
		[parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
		[alias("FullName","Name")]
		[string]$FileName,
		
		[parameter(Mandatory=$false,ValueFromPipeline=$true,Position=1,ValueFromPipelineByPropertyName=$true)]
		[ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
		[string]$HashAlgorithm="MD5",
		
		[parameter(Mandatory=$false,ValueFromPipeline=$false,Position=2,ValueFromPipelineByPropertyName=$false)]			
		[string]$MatchHash
		)
	
	if (!(Test-Path -Path $FileName)) { throw "Cannot find path '$FileName' because it does not exist." }
	if (Test-Path -Path $FileName -PathType Container) { throw "The object specified in the FileName parameter is a directory. Please specify a path to a file.";break }

	function Process-CryptoChecksum {

		Param(
			[string]$file,
			[string]$Crypto
			)
		
		switch ($Crypto) {
		
		 	MD5 { $crypto_provider = new-object 'System.Security.Cryptography.MD5CryptoServiceProvider' }
			SHA1 { $crypto_provider = new-object 'System.Security.Cryptography.SHA1Managed' }
			SHA256 { $crypto_provider = new-object 'System.Security.Cryptography.SHA256Managed' }
			SHA384 { $crypto_provider = new-object 'System.Security.Cryptography.SHA384Managed' }
			SHA512 { $crypto_provider = new-object 'System.Security.Cryptography.SHA512Managed' }
			RIPEMD160 { $crypto_provider = new-object 'System.Security.Cryptography.RIPEMD160Managed' }
			
		}
		
		$file_info=get-item $file -Force
		trap { break }
		$stream=$file_info.OpenRead()
		if ($? -eq $false) { return $null }
		$fileleaf=Split-Path -Path $file -Leaf
		$bytes= $crypto_provider.ComputeHash($stream)
		$checksum=""
		foreach ($byte in $bytes) {	
			$checksum+=$byte.ToString('x2')	
		}
		$stream.close() | out-null
		return $checksum
	}

	function Compare-Hash {
	
		param(
			[string]$string1,
			[string]$string2
			)
			
		if ($String1 -eq $String2) { return [bool]$True }
		else { return [bool]$False }
	}

	
		$CheckSumvalue=New-Object System.Object
		
		Add-Member -Force -InputObject $CheckSumvalue -MemberType NoteProperty -Name FileName -Value (Resolve-Path $FileName | Select -ExpandProperty ProviderPath)
		Add-Member -Force -InputObject $CheckSumvalue -MemberType NoteProperty -Name HashAlgorithm -Value $HashAlgorithm.ToUpper()
		Add-Member -Force -InputObject $CheckSumvalue -MemberType NoteProperty -Name Checksum -Value (Process-CryptoChecksum -file $FileName -Crypto $HashAlgorithm).ToUpper()
		if ($MatchHash) { Add-Member -Force -InputObject $CheckSumvalue -MemberType NoteProperty -Name MatchHash -Value (Compare-Hash $MatchHash $CheckSumvalue.Checksum) }
		Add-Member -Force -InputObject $CheckSumvalue -MemberType NoteProperty -Name Length -Value (Get-Item $FileName -force | Select -Expand Length)
		Add-Member -Force -InputObject $CheckSumvalue -MemberType NoteProperty -Name CreationTime -Value (get-date -Format G (Get-Item $FileName -force | Select -Expand CreationTime))
		Add-Member -Force -InputObject $CheckSumvalue -MemberType NoteProperty -Name Timestamp -Value (get-date -Format G)
		return $CheckSumvalue
	
}

function ProcessDragDrop ( $object ){ 
    $file=$object.Data.GetFileDropList() 
    if (-NOT ((Get-ItemProperty $file[0]).Attributes -match "Directory")) {
        $tbSourceFile.Text = $file[0]
        $btnCompute.Enabled = $true
    }
}


#Call the Main Functions
GenerateForm

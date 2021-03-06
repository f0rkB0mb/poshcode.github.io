function Get-VirtualEsxiIp {
	param($vm)
	$tmpFileTemplate = ($env:TEMP + "\ipdetect-")
	$tmpFile = $tmpFileTemplate + (Get-Random) + ".png"

	# Take the screenshot.
	$view = $vm | Get-View -Property Name
	$path = $view.CreateScreenShot()
	$path -match "([^/]+/[^/]+$)" | Out-Null
	$relativePath = $matches[1]

	# Determine the VM's datastore.
	$datastore = $vm | Get-Datastore
	$remotePath = ($datastore.DatastoreBrowserPath + "\" + $relativePath)
	Write-Verbose ("Use remote path " + $remotePath)

	# Copy it locally. Requires PowerCLI 4.0 U1.
	Write-Verbose ($remotePath + ", " + $tmpFile)
	Copy-DatastoreItem $remotePath $tmpFile

	# OCR the screenshot.
	$output = Apply-Ocr -pngFile $tmpFile

	# Pull out the IP address.
	$output -match "http://([^/]+)" | Out-Null
	$ip = $matches[1]

	# Clean up.
	Write-Verbose "Cleaning up"
	# Remove-Item -Force $remotePath
	Remove-Item -Force $tmpFile

	# Output the IP.
	Write-Output $ip
}

# Apply OCR to a PNG file and return the text results.
function Apply-Ocr {
	param($pngFile)
	$tmpFileTemplate = ($env:TEMP + "\ipdetectocr-")
	$tmpFile = $tmpFileTemplate + (Get-Random) + ".tif"

	# Convert the PNG to TIFF.
	[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
	$image = [System.Drawing.Image]::FromFile($pngFile)
	$image.Save($tmpFile, [System.Drawing.Imaging.ImageFormat]::TIFF)

	# OCR it! (Requires Microsoft Office Document Imaging)
	$modi = new-object -com MODI.Document
	$modi.Create($tmpFile)
	$modi.OCR()
	$OCRText = ($modi.Images | select -expand Layout).Text
	$modi.Close()
	$image.Dispose()

	# Clean out old left over files.
	foreach ($file in (
		Get-Childitem $tmpFileTemplate* |
		    Where { $_.LastWriteTime -lt ((Get-Date).addMinutes(-1)) } )) {
		Remove-Item -Force $file
	}

	Write-Output $OCRText
}

# Example use:
# Get-VirtualEsxiIp -vm (Get-VM "ESXi 4.0 Instance 3")


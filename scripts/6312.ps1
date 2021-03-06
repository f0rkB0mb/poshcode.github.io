Function createSignature {
	param([string]$Template, [string]$Name, [string]$title, [string]$streetAddress, [string]$City, [string]$postalCode, [string]$officePhone, [string]$mobilePhone, [string]$sigpath, [string]$company)

	$Template = Get-Content -Path $Template
	$templateWork = $Template | foreach {
		$_ -replace "<!--Name-->",$Name `
		-replace "<!--Title-->",$title `
		-replace "<!--streetAddress-->",$streetAddress `
		-replace "<!--City-->",$City `
		-replace "<!--postalCode-->",$postalCode `
		-replace "<!--officePhone-->",$officePhone `
		-replace "<!--mobilePhone-->",$mobilePhone `
		-replace "<!--Company-->",$Company `		
		}
	
			
		if (!$title) {
			$fieldSplit = $templateWork -split "<!`-`-TitleC`-`->([^/]+)<!`-`-CTitleC`-`->"
			$templateWork = $templateWork -replace($fieldSplit[1],"")
			}
	
	    if (!$streetAddress) {
			$fieldSplit = $templateWork -split "<!`-`-streetAddressC`-`->([^/]+)<!`-`-CstreetAddressC`-`->"
			$templateWork = $templateWork -replace($fieldSplit[1],"")
			}
		
		if (!$city) {
			$fieldSplit = $templateWork -split "<!`-`-CityC`-`->([^/]+)<!`-`-CCityC`-`->"
			$templateWork = $templateWork -replace ($fieldSplit[1],"")
			}
			
		if (!$postalCode) {
			$fieldSplit = $templateWork -split "<!`-`-postalCodeC`-`->([^/]+)<!`-`-CpostalCodeC`-`->"
			$templateWork = $templateWork -replace ($fieldSplit[1],"")
			}
		
		if (!$officePhone) {
			$fieldSplit = $templateWork -split "<!`-`-officePhoneC`-`->([^/]+)<!`-`-CofficePhoneC`-`->"
			$templateWork = $templateWork -replace ($fieldSplit[1],"")
			}
		
		if (!$mobilePhone) {
			$fieldSplit = $templateWork -split "<!`-`-mobilePhoneC`-`->([^/]+)<!`-`-CmobilePhoneC`-`->"
			$templateWork = $templateWork -replace ($fieldSplit[1],"")
			}
		
		if (!$company) {
			$fieldSplit = $templateWork -split "<!`-`-companyC`-`->([^/]+)<!`-`-CcompanyC`-`->"
			$templateWork = $templateWork -replace ($fieldSplit[1],"")
			}
		
		$templateWork | Out-File $sigpath
}	


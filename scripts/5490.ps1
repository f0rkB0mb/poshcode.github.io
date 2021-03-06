#
# I'm sick of searching for new cars on KSL manually.
#

#Vars
[string]$KeywordSearch = 'civic'
[string]$YearStart = '2010'
[string]$YearEnd = '2014'
[string]$PriceFrom = '15000'
[string]$PriceTo = '20000'
[string]$BodyStyle = 'Coupe'

Try
{
	Write-Verbose "Requesting URI"
	$Site = "http://www.ksl.com/auto/search/index?o_facetClicked=true&o_facetValue=Coupe&o_facetKey=body&resetPage=true&keyword=$KeywordSearch&yearFrom=$YearStart&yearTo=$YearEnd&priceFrom=$PriceFrom&priceTo=$PriceTo&mileageFrom=&mileageTo=&zip=&miles=0&body[]=$BodyStyle"
	$Request = Invoke-WebRequest -Uri $Site -DisableKeepAlive -Method Get
	
	Write-Verbose "Filtering cars listing from KSL"
	$listing = 	$Request.ParsedHtml.getElementsByTagName('div') | ? {$_.className -eq 'srp-listing-body-right'}
	
	#Intialize array
	Write-Verbose "Building cars object"
	$cars = @()
	
	Foreach ($item in $listing.outerText.Trim())
	{
		#Split listing into individual fields on line breaks.
		$details = $item.Trim().Split("`n")
		
		#Split 3rd line containing Mileage, Location, DaysListed.
		$moredetails = $details[2].Split('|')

		#Build new car object
		$car = New-Object -TypeName PSObject
		$car | Add-Member -Type NoteProperty -Name 'Title' -Value $details[0]
		$car | Add-Member -Type NoteProperty -Name 'Price' -Value $details[1]
		$car | Add-Member -Type NoteProperty -Name 'Mileage' -Value $moredetails[0].Trim().Replace(' Miles','')
		$car | Add-Member -Type NoteProperty -Name 'Location' -Value  $moredetails[1].Trim()
		$car | Add-Member -Type NoteProperty -Name 'DaysListed' -Value $moredetails[2].Trim().Replace(' Days','')
		$car | Add-Member -Type NoteProperty -Name 'Description' -Value $details[3]
		
		#Add car to cars array
		$cars += $car
	}
	
	#Display results by time listed
	$cars = $cars | Sort -Property DaysListed | Out-String
	$cars = $cars.Trim()
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	[System.Windows.Forms.MessageBox]::Show("$cars",'Matching Cars')
}
Catch
{
	Write-Warning "Something screwed up`: $_"
	Exit
}

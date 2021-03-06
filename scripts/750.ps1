#
# get-unitylicense.ps1
#
# Returns license information for a Cisco Unity environment
# Usage: get-unitylicense <server>
#
# Author: Robbie Foust (rfoust@duke.edu)
#

function global:get-unitylicense ([string]$server = $(throw "Please provide a server name!"))
	{

	$webContent = new-object net.webclient
	$page = $webContent.DownloadString("http://$server/avxml/effectivelicense.asp")

	# remove leading whitespace
	$page = $page -replace "^.`n"
	$license = [xml]$page

	new-object psobject | add-member -memberType NoteProperty -name LicLanguagesMax -value $license.AvXmlLicData.Licenses.LicLanguagesMax -passthru |
		add-member -memberType NoteProperty -name LicMaxMsgRecLenIsLicensed -value $license.AvXmlLicData.Licenses.LicMaxMsgRecLenIsLicensed -passthru |
		add-member -memberType NoteProperty -name LicPoolingIsEnabled -value $license.AvXmlLicData.Licenses.LicPoolingIsEnabled -passthru |
		add-member -memberType NoteProperty -name LicSubscribersMax -value $license.AvXmlLicData.Licenses.LicSubscribersMax -passthru |
		add-member -memberType NoteProperty -name LicUMSubscribersMax -value $license.AvXmlLicData.Licenses.LicUMSubscribersMax -passthru |
		add-member -memberType NoteProperty -name LicVMISubscribersMax -value $license.AvXmlLicData.Licenses.LicVMISubscribersMax -passthru |
		add-member -memberType NoteProperty -name LicVoicePortsMax -value $license.AvXmlLicData.Licenses.LicVoicePortsMax -passthru |
		add-member -memberType NoteProperty -name AvLicUtilizationSecondaryServer -value $license.AvXmlLicData.Utilization.AvLicUtilizationSecondaryServer -passthru |
		add-member -memberType NoteProperty -name AvLicUtilizationSubscribers -value $license.AvXmlLicData.Utilization.AvLicUtilizationSubscribers -passthru |
		add-member -memberType NoteProperty -name AvLicUtilizationVMISubscribers -value $license.AvXmlLicData.Utilization.AvLicUtilizationVMISubscribers -passthru
	}

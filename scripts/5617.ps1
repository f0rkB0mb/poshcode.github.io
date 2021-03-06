###################################################################
# Script:     Configuration Manager Collection Tree Documenter    #
# Description Creates a CSV file detailing collectionid, name and #
#             limittocollectionid fields in a suitable format to  #
#             import into Microsoft Visio as an org chart         #
# Last Update 01/12/2014                                          #
# Version     1.0 			
###################################################################

function DocumentCollectionTree
{
    param($LimitCollectionID)
    $info=@()
    $subcollections = Get-WmiObject `
                        -ComputerName $siteserver `
                        -namespace root\sms\site_$sitecode `
                        -query "select * from SMS_Collection where LimitToCollectionID = '$LimitCollectionID'"

    if ($subcollections -ne $null)
    {
        foreach ($subcoll in $subcollections)
        {
            $object = New-Object -TypeName PSObject
            $object | Add-Member -MemberType NoteProperty  -Name CollectionID -Value $subcoll.collectionid
            $object | Add-Member -MemberType NoteProperty  -Name CollectionName -Value $subcoll.name
            $object | Add-Member -MemberType NoteProperty  -Name LimitingCollectionID -Value $LimitCollectionID
            $info += $object
            DocumentCollectionTree $subcoll.collectionid
        }
    }
    $info | export-csv -path "c:\temp\collections.csv" -NoTypeInformation -Append -Force
 }


$collectionid = Read-Host "Enter the root collection id to search from" 
$siteserver = "ServerName"
$sitecode = "sitecode"

DocumentCollectionTree $collectionid

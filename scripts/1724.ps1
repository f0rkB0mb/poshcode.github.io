## An update using New-WebServiceProxy to the MSDN ContentService instead of HttpRest
## See: http: //services.msdn.microsoft.com/ContentServices/ContentService.asmx

## This is a VERY EARLY prototype of a function that could retrieve cmdlet help from TechNet ...
## and hypothetically, other online help sites which used the same format (none)

## Version History
## 0.3 - 2010-03-25 - Fixed a buggy type check which failed on first run. THIS VERSION
## 0.2 - 2010-03-24 - Switched to using the ContentService Web Service.  PoshCode.org/1723
## 0.1 - 2010-03-23 - Initial release depended on HttpRest.  PoshCode.org/1719

param(
   [Parameter(Mandatory=$true,Position=0)]
   [String]$Name
,
   [Parameter(Mandatory=$false,Position=1)]
   [String[]]$Sections= @("Name", "Synopsis", "Syntax", "Description")
)


# http://poshcode.org/1718
function Select-Expand {
<# 
.Synopsis
   Like Select-Object -Expand, but with recursive iteration of a select chain
.Description
   Takes a dot-separated series of properties to expand, and recursively iterates the output of each property ...
.Parameter Property
   A collection of property names to expand.
   
   Each property can be a dot-separated series of properties, and each one is expanded, iterated, and then evaluated against the next
.Parameter InputObject
   The input to be selected from
.Parameter Unique
   If set, this becomes a pipeline hold-up, and the total output is checked to ensure uniqueness
.Parameter EmptyToo
   If set, Select-Expand will include empty/null values in it's output
.Example
   Get-Help Get-Command | Select-Expand relatedLinks.navigationLink.uri -Unique

   This will return the online-help link for Get-Command.  It's the equivalent of running the following command:

   C:\PS> Get-Help Get-Command | Select-Object -Expand relatedLinks | Select-Object -Expand navigationLink | Select-Object -Expand uri | Where-Object {$_} | Select-Object -Unique
#>
param(
   [Parameter(ValueFromPipeline=$false,Position=0)]
   [string[]]$Property
,
   [Parameter(ValueFromPipeline=$true)]
   [Alias("IO")]
   [PSObject[]]$InputObject
,
   [Switch]$Unique
,
   [Switch]$EmptyToo
)
begin { 
   if($unique) {
      $output = @()
   }
}
process {
   foreach($io in $InputObject) {
      foreach($prop in $Property -split "\.") {
         if($io -ne $null) {
            $io = $io | Select-Object -Expand $prop
            Write-Verbose $($io | out-string)
         }
      }
      if(!$EmptyToo -and ($io -ne $null)) {
         $io = $io | Where-Object {$_}
      }
      if($unique) {
         $output += @($io)
      } 
      else {
         Write-Output $io
      }
   }
}
end {
   if($unique) {
      Write-Output $output | Select-Object -Unique
   }
}
}
# New-Alias slep Select-Expand

# http://poshcode.org/1722
function Get-HttpResponseUri {
#.Synopsis
#   Fetch the HEAD for a url and return the ResponseUri.
#.Description
#   Does a HEAD request for a URL, and returns the ResponseUri. This is useful for resolving (in a service-independent way) shortened urls.
#.Parameter ShortUrl
#   A (possibly) shortened URL to be resolved to its redirect location.
   PARAM(
      [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
      [Alias("Uri","Url")]
      [string]$ShortUrl
   )
   $req = [System.Net.HttpWebRequest]::Create($ShortUrl)
   $req.Method = "HEAD"
   $response = $req.GetResponse()
   Write-Output $response.ResponseUri
   $response.Close() # clean up like a good boy
}
# New-Alias Resolve-ShortUri Select-Expand

if( -not("Mtps.ContentService" -as [type] -and $global:MtpsWebServiceProxy -as "Mtps.ContentService")) {
$global:MtpsWebServiceProxy = New-WebServiceProxy "http://services.msdn.microsoft.com/ContentServices/ContentService.asmx?wsdl" -Namespace Mtps
}

function Get-OnlineHelpContent {
param(
   [Parameter(Mandatory=$true,Position=0)]
   [String]$Name
,
   [Parameter(Mandatory=$false,Position=1)]
   [String[]]$Sections= @("Name", "Synopsis", "Syntax", "Description")
)
process { 
   $uri = Get-Help $Name | Select-Expand relatedLinks.navigationLink.uri -Unique | Get-HttpResponseUri
   
   if(!$uri) { throw "Couldn't find online help URL for $Name" }
   
   $id = [IO.Path]::GetFileNameWithoutExtension( $uri.segments[-1] )
   write-verbose "Content Id: $id"

   $content = $MtpsWebServiceProxy.GetContent( (New-Object 'Mtps.getContentRequest' -Property @{locale = $PSUICulture; contentIdentifier = $id; requestedDocuments = (New-Object Mtps.requestedDocument -Property @{Selector="Mtps.Failsafe"}) }) )
   $global:OnlineHelpContent = $content.primaryDocuments |?{$_.primaryFormat -eq "Mtps.Failsafe"} | Select -Expand Any
   
   $NameNode = $global:OnlineHelpContent.SelectSingleNode("//*[local-name()='div' and @class='topic']/*[local-name()='div' and @class='title']")
   $NameNode.SetAttribute("header","NAME")
   
   $global:OnlineHelpContent = $global:OnlineHelpContent.SelectSingleNode("//*[local-name()='div' and @id='mainBody']")
   
   $Synopsis = $global:OnlineHelpContent.SelectSingleNode("*[local-name()='p']")
   $Synopsis.SetAttribute("header","SYNOPSIS")
   
   $headers = $OnlineHelpContent.h2  | ForEach-Object { $_.get_InnerText().Trim() }
   $content = $OnlineHelpContent.div | ForEach-Object { $_ }

   $global:help = @{Name=$NameNode; Synopsis=$Synopsis}
   if($headers.Count -ne $content.Count) { 
      Write-Warning "Unmatched content"
      foreach($header in $headers) {
        $help.$header = $OnlineHelpContent.SelectNodes( "//*[preceding-sibling::*[1][local-name()='h2' and normalize-space()='$header']]" )
        $help.$header.SetAttribute("header",$header.ToUpper())
      }
   }
   else {
      for($h=0;$h -lt $headers.Count; $h++){
         $help.($headers[$h]) = $content[$h]
         $help.($headers[$h]).SetAttribute("header",$headers[$h].ToUpper())
      }
   }
   $help
   
   $content[$Sections] | ForEach-Object { 
      Write-Output
      Write-Output $_.Header
      Write-Output
      Write-Output ($_.get_InnerText() -replace '^[\n\s]*\n|\n\s+$')
   }
}
}

Get-OnlineHelpContent $Name | out-null


$help[$Sections] | ForEach-Object { 
   Write-Host
   Write-Host $_.Header -Fore Cyan
   Write-Host
   Write-Host ($_.get_InnerText() -replace '^[\n\s]*\n|\n\s+$')
}

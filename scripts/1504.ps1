#requires -version 2.0
# Select-Xml 2.2 and Remove-XmlNamespace
# Version History:
# Select-Xml 2.0 was the first script version I wrote, and it didn't function identically to the built-in Select-Xml with regards to parameter parsing
# Select-Xml 2.1 matched the built-in Select-Xml parameter sets, it's now a drop-in replacement if you were using the original with: Select-Xml ... | Select-Object -Expand Node
# Select-Xml 2.2 fixes a bug in the -Content parameterset where -RemoveNamespace was *presumed*


function Select-Xml {
#.Synopsis
#  The Select-XML cmdlet lets you use XPath queries to search for text in XML strings and documents. Enter an XPath query, and use the Content, Path, or Xml parameter to specify the XML to be searched.
#.Description
#  Improves over the built-in Select-XML by leveraging Remove-XmlNamespace to provide a -RemoveNamespace parameter -- if it's supplied, all of the namespace declarations and prefixes are removed from all XML nodes (by an XSL transform) before searching.  
#  
#  However, only raw XmlNodes are returned from this function, so the output isn't currently compatible with the built in Select-Xml, but is equivalent to using Select-Xml ... | Select-Object -Expand Node
#
#  Also note that if the -RemoveNamespace switch is supplied the returned results *will not* have namespaces in them, even if the input XML did, and entities get expanded automatically.
#.Parameter Content
#  Specifies a string that contains the XML to search. You can also pipe strings to Select-XML.
#.Parameter Namespace
#   Specifies a hash table of the namespaces used in the XML. Use the format @{<namespaceName> = <namespaceUri>}.
#.Parameter Path
#   Specifies the path and file names of the XML files to search.  Wildcards are permitted.
#.Parameter Xml
#  Specifies one or more XML nodes to search.
#.Parameter XPath
#  Specifies an XPath search query. The query language is case-sensitive. This parameter is required.
#.Parameter RemoveNamespace
#  Allows the execution of XPath queries without namespace qualifiers. 
#  
#  If you specify the -RemoveNamespace switch, all namespace declarations and prefixes are actually removed from the Xml before the XPath search query is evaluated, and your XPath query should therefore NOT contain any namespace prefixes.
# 
#  Note that this means that the returned results *will not* have namespaces in them, even if the input XML did, and entities get expanded automatically.
[CmdletBinding(DefaultParameterSetName="Xml")]
PARAM(
   [Parameter(Position=1,ParameterSetName="Path",Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
   [ValidateNotNullOrEmpty()]
   [Alias("PSPath")]
   [String[]]$Path
,
   [Parameter(Position=1,ParameterSetName="Xml",Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
   [ValidateNotNullOrEmpty()]
   [Alias("Node")]
   [System.Xml.XmlNode[]]$Xml
,
   [Parameter(ParameterSetName="Content",Mandatory=$true,ValueFromPipeline=$true)]
   [ValidateNotNullOrEmpty()]
   [String[]]$Content
,
   [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false)]
   [ValidateNotNullOrEmpty()]
   [Alias("Query")]
   [String[]]$XPath
,
   [Parameter(Mandatory=$false)]
   [ValidateNotNullOrEmpty()]
   [Hashtable]$Namespace
,
   [Switch]$RemoveNamespace
)
BEGIN {
   function Select-Node {
   PARAM([Xml.XmlNode]$Xml, [String[]]$XPath, $NamespaceManager)
   BEGIN {
      foreach($node in $xml) {
         if($NamespaceManager -is [Hashtable]) {
            $nsManager = new-object System.Xml.XmlNamespaceManager $node.NameTable
            foreach($ns in $Namespace.GetEnumerator()) {
               $nsManager.AddNamespace( $ns.Key, $ns.Value )
            }
         }
         
         foreach($path in $xpath) {
            $node.SelectNodes($path, $NamespaceManager)
   }  }  }  }

   [Text.StringBuilder]$XmlContent = [String]::Empty
}

PROCESS {
   $NSM = $Null; if($PSBoundParameters.ContainsKey("Namespace")) { $NSM = $Namespace }

   switch($PSCmdlet.ParameterSetName) {
      "Content" {
         $null = $XmlContent.AppendLine( $Content -Join "`n" )
      }
      "Path" {
         foreach($file in Get-ChildItem $Path) {
            [Xml]$Xml = Get-Content $file
            if($RemoveNamespace) {
               $Xml = Remove-XmlNamespace $Xml
            }
            Select-Node $Xml $XPath  $NSM
         }
      }
      "Xml" {
         foreach($node in $Xml) {
            if($RemoveNamespace) {
               $node = Remove-XmlNamespace $node
            }
            Select-Node $node $XPath $NSM
         }
      }
   }
}
END {
   if($PSCmdlet.ParameterSetName -eq "Content") {
      [Xml]$Xml = $XmlContent.ToString()
      if($RemoveNamespace) {
         $Xml = Remove-XmlNamespace $Xml
      }
      Select-Node $Xml $XPath  $NSM
   }
}

}




function Remove-XmlNamespace {
#.Synopsis
#  Removes namespace definitions and prefixes from xml documents
#.Description
#  Runs an xml document through an XSL Transformation to remove namespaces from it if they exist.
#  Entities are also naturally expanded
#.Parameter Content
#  Specifies a string that contains the XML to transform.
#.Parameter Path
#  Specifies the path and file names of the XML files to transform. Wildcards are permitted.
#
#  There will bne one output document for each matching input file.
#.Parameter Xml
#  Specifies one or more XML documents to transform
#
[CmdletBinding(DefaultParameterSetName="Xml")]
PARAM( 
   [Parameter(ParameterSetName="Content",Mandatory=$true)]
   [String[]]$Content
,
   [Parameter(Position=0,ParameterSetName="Path",Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
   [Alias("FullName")]
   [String[]]$Path
,
   [Parameter(Position=0,ParameterSetName="Xml",Mandatory=$true,ValueFromPipeline=$true)]
   [Alias("IO","InputObject")]
   [System.Xml.XmlDocument[]]$Xml
)
BEGIN {
   $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
   $xslt.Load(([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader @"
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <xsl:output method="xml" indent="yes"/>
   <xsl:template match="/|comment()|processing-instruction()">
      <xsl:copy>
         <xsl:apply-templates/>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="*">
      <xsl:element name="{local-name()}">
         <xsl:apply-templates select="@*|node()"/>
      </xsl:element>
   </xsl:template>

   <xsl:template match="@*">
      <xsl:attribute name="{local-name()}">
         <xsl:value-of select="."/>
      </xsl:attribute>
   </xsl:template>
</xsl:stylesheet>
"@))))
}
PROCESS {
   switch($PSCmdlet.ParameterSetName) {
      "Content" {
         [System.Xml.XmlDocument[]]$Xml = @( [Xml]($Content -Join "`n") )
      }
      "Path" {
         [System.Xml.XmlDocument[]]$Xml = @()
         foreach($file in Get-ChildItem $Path) {
            $Xml += [Xml](Get-Content $file)
         }
      }
      "Xml" {
      }
   }
   foreach($input in $Xml) {
      $Output = New-Object System.Xml.XmlDocument
      $writer =$output.CreateNavigator().AppendChild()
      $xslt.Transform( $input.CreateNavigator(), $null, $writer )
      $writer.Close() # $writer.Dispose()
      Write-Output $output
   }
}
}

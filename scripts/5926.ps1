#requires -version 2.0

# Improves over the built-in Select-XML by leveraging Remove-XmlNamespace http`://poshcode.org/1492 
# to provide a -RemoveNamespace parameter -- if it's supplied, all of the namespace declarations 
# and prefixes are removed from all XML nodes (by an XSL transform) before searching. 
# IMPORTANT: returned results *will not* have namespaces in them, even if the input XML did. 

# Also, only raw XmlNodes are returned from this function, so the output isn't completely compatible 
# with the built in Select-Xml. It's equivalent to using Select-Xml ... | Select-Object -Expand Node

# Version History:
# Select-Xml 2.0 This was the first script version I wrote.
#                it didn't function identically to the built-in Select-Xml with regards to parameter parsing
# Select-Xml 2.1 Matched the built-in Select-Xml parameter sets, it's now a drop-in replacement 
#                BUT only if you were using the original with: Select-Xml ... | Select-Object -Expand Node
# Select-Xml 2.2 Fixes a bug in the -Content parameterset where -RemoveNamespace was *presumed*
# Version    3.0 Added New-XDocument and associated generation functions for my XML DSL
# Version    3.1 Fixed a really ugly bug in New-XDocument in 3.0 which I should not have released
# Version    4.0 Never content to leave well enough alone, I've completely reworked New-XDocument
# Version    4.1 Tweaked namespaces again so they don't cascade down when they shouldn't. Got rid of the unnecessary stack.
# Version    4.2 Tightened xml: only cmdlet, function, and external scripts, with "-" in their names are exempted from being converted into xml tags.
#                Fixed some alias error messages caused when PSCX is already loaded (we overwrite their aliases for cvxml and fxml)
# Version    4.3 Added a Path parameter set to Format-Xml so you can specify xml files for prety printing
# Version    4.5 Fixed possible [Array]::Reverse call on a non-array in New-XElement (used by New-XDocument)
#                Work around possible variable slipping on null values by:
#                1) allowing -param:$value syntax (which doesn't fail when $value is null)
#                2) testing for -name syntax on the value and using it as an attribute instead
# Version    4.6 Added -Arguments to Convert-Xml so that you can pass arguments to XSLT transforms!
#                Note: when using strings for xslt, make sure you single quote them or escape the $ signs.
# Version    4.7 Fixed a typo in the namespace parameter of Select-Xml
# Version    4.8 Fixed up some uses of Select-Xml -RemoveNamespace
# Version    5.0 Added Update-Xml to allow setting xml attributes or node content
# Version    6.0 Major cleanup, breaking changes.
#       - Added Get-XmlContent and Set-XmlContent for loading/saving XML from files or strings
#       - Removed Path and Content parameters from the other functions (it greatly simplifies thost functions, and makes the whole thing more maintainable)
#       - Updated Update-Xml to support adding nodes "before" and "after" other nodes, and to support "remove"ing nodes
# Version    6.1 Update for PowerShell 3.0
# Version    6.2 Minor tweak in exception handling for CliXml
# Version    6.3 Added Remove-XmlElement to allow removing nodes or attributes
#                This is something I specifically needed to remove "ignorable" namespaces 
#                Specifically, the ones created by the Visual Studio Workflow designer (and perhaps other visual designers like Blend)
#                Which I don't want to check into source control, because it makes diffing nearly impossible
# Version    6.4 Fixed a bug on New-XElement for Rudy Shockaert (nice bug report, thanks!)
# Version    6.5 Added -Parameters @{} parameter to New-XDocument to allow local variables to be passed into the module scope. *grumble*
# Version    6.6 Expose Convert-Xml and fix a couple of bugs (I can't figure how they got here)

function Add-Accelerator {
<#
   .Synopsis
      Add a type accelerator to the current session
   .Description
      The Add-Accelerator function allows you to add a simple type accelerator (like [regex]) for a longer type (like [System.Text.RegularExpressions.Regex]).
   .Example
      Add-Accelerator list System.Collections.Generic.List``1
      $list = New-Object list[string]
      
      Creates an accelerator for the generic List[T] collection type, and then creates a list of strings.
   .Example
      Add-Accelerator "List T", "GList" System.Collections.Generic.List``1
      $list = New-Object "list t[string]"
      
      Creates two accelerators for the Generic List[T] collection type.
   .Parameter Accelerator
      The short form accelerator should be just the name you want to use (without square brackets).
   .Parameter Type
      The type you want the accelerator to accelerate (without square brackets)
   .Notes
      When specifying multiple values for a parameter, use commas to separate the values. 
      For example, "-Accelerator string, regex".
      
      PowerShell requires arguments that are "types" to NOT have the square bracket type notation, because of the way the parsing engine works.  You can either just type in the type as System.Int64, or you can put parentheses around it to help the parser out: ([System.Int64])

      Also see the help for Get-Accelerator and Remove-Accelerator
   .Link
      http://huddledmasses.org/powershell-2-ctp3-custom-accelerators-finally/
#>
[CmdletBinding()]
param(
   [Parameter(Position=0,ValueFromPipelineByPropertyName=$true)]
   [Alias("Key","Name")]
   [string[]]$Accelerator
,
   [Parameter(Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
   [Alias("Value","FullName")]
   [type]$Type
)
process {
   # add a user-defined accelerator  
   foreach($a in $Accelerator) { 
      if($xlr8r::AddReplace) { 
         $xlr8r::AddReplace( $a, $Type) 
      } else {
         $null = $xlr8r::Remove( $a )
         $xlr8r::Add( $a, $Type)
      }
      trap [System.Management.Automation.MethodInvocationException] {
         if($xlr8r::get.keys -contains $a) {
            if($xlr8r::get[$a] -ne $Type) {
               Write-Error "Cannot add accelerator [$a] for [$($Type.FullName)]`n                  [$a] is already defined as [$($xlr8r::get[$a].FullName)]"
            }
            Continue;
         } 
         throw
      }
   }
}
}

&{ 
$local:xlr8r = [psobject].assembly.gettype("System.Management.Automation.TypeAccelerators")
$local:xlinq = [Reflection.Assembly]::Load("System.Xml.Linq, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
$xlinq.GetTypes() | ? { $_.IsPublic -and !$_.IsSerializable -and $_.Name -ne "Extensions" -and !$xlr8r::Get[$_.Name] } | Add-Accelerator

Add-Accelerator "Dictionary" "System.Collections.Generic.Dictionary``2, mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"
Add-Accelerator "PSParser" "System.Management.Automation.PSParser, System.Management.Automation, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"
}


function Get-XmlContent {
#.Synopsis
#   Load an XML file as an XmlDocument
param(
    # Specifies a string that contains the XML to load, or a path to a file which has the XML to load (wildcards are permitted).
    [Parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("PSPath","Path")]
    [String[]]$Content
,
    # If set, loads XML with all namespace qualifiers removed, and all entities expanded.
    [Alias("Rn","Rm")]
    [Switch]$RemoveNamespace
)
begin {
    [Text.StringBuilder]$XmlContent = [String]::Empty
    [bool]$Path = $true
}
process {
    if($Path -and ($Path = Test-Path @($Content)[0] -EA 0)) { 
        foreach($file in Resolve-Path $Content) {
            $xml = New-Object System.Xml.XmlDocument;
            if($file.Provider.Name -eq "FileSystem") {
                Write-Verbose $file.ProviderPath
                $xml.Load( $file.ProviderPath )
            } else {
                $ofs = "`n"
                $xml.LoadXml( ([String](Get-Content $file)) )
            }
        }
        if($RemoveNamespace) {
            $xml.LoadXml( (Remove-XmlNamespace -Xml $xml.DocumentElement) )
        }
        Write-Output $xml

    } else {
        # If the "path" parameter isn't actually a path, assume that it's actually content
        foreach($line in $content) {
            $null = $XmlContent.AppendLine( $line )
        }
    }
}
end {
    if(!$Path) {
        $xml = New-Object System.Xml.XmlDocument; 
        $xml.LoadXml( $XmlContent.ToString() )
        if($RemoveNamespace) {
            $xml.LoadXml( (Remove-XmlNamespace -Xml $xml.DocumentElement) )
        }
        Write-Output $xml
    }

}}


Set-Alias Import-Xml Get-XmlContent
Set-Alias ipxml Get-XmlContent
Set-Alias ipx Get-XmlContent
Set-Alias Get-Xml Get-XmlContent
Set-Alias gxml Get-XmlContent
Set-Alias gx Get-XmlContent

function Set-XmlContent {
param(
    [Parameter(Mandatory=$true, Position=1)]
    [Alias("PSPath")]
    [String]$Path
,
    # Specifies one or more XML nodes to search.
    [Parameter(Position=5,ParameterSetName="Xml",Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Node")]
    [Xml]$Xml
)
process {
    $xml.Save( $Path )
}
}

Set-Alias Export-Xml Set-XmlContent
Set-Alias epxml Set-XmlContent
Set-Alias epx Set-XmlContent
Set-Alias Set-Xml Set-XmlContent
Set-Alias sxml Set-XmlContent
Set-Alias sx Set-XmlContent

function Format-Xml {
#.Synopsis
#   Pretty-print formatted XML source
#.Description
#   Runs an XmlDocument through an auto-indenting XmlWriter
#.Parameter Xml
#   The Xml Document
#.Parameter Path
#   The path to an xml document (on disc or any other content provider).
#.Parameter Indent
#   The indent level (defaults to 2 spaces)
#.Example
#   [xml]$xml = get-content Data.xml
#   C:\PS>Format-Xml $xml
#.Example
#   get-content Data.xml | Format-Xml
#.Example
#   Format-Xml C:\PS\Data.xml
#.Example
#   ls *.xml | Format-Xml
#
[CmdletBinding()]
param(
   [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Document")]
   [xml]$Xml
,
   [Parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="File")]
   [Alias("PsPath")]
   [string]$Path
,
   [Parameter(Mandatory=$false)]
   $Indent=2
)
process {
   ## Load from file, if necessary
   if($Path) { [xml]$xml = Get-Content $Path }
   
   $StringWriter = New-Object System.IO.StringWriter
   $XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter
   $xmlWriter.Formatting = "indented"
   $xmlWriter.Indentation = $Indent
   $xml.WriteContentTo($XmlWriter)
   $XmlWriter.Flush()
   $StringWriter.Flush()
   Write-Output $StringWriter.ToString()
}}
Set-Alias fxml Format-Xml -EA 0
Set-Alias fx   Format-Xml -EA 0

function Select-XmlNodeInternal {
[CmdletBinding()]
param([Xml.XmlNode[]]$Xml, [String[]]$XPath, [Hashtable]$NamespaceManager)
begin {
    Write-Verbose "XPath = $($XPath -join ',')"
    foreach($node in $xml) {
        if($NamespaceManager) {
            $nsManager = new-object System.Xml.XmlNamespaceManager $node.NameTable
            foreach($ns in $NamespaceManager.GetEnumerator()) {
                $nsManager.AddNamespace( $ns.Key, $ns.Value )
            }
            Write-Verbose "Names = $($nsManager | % { @{ $_ = $nsManager.LookupNamespace($_) } } | Out-String)"
        }
        foreach($path in $xpath) {
            $node.SelectNodes($path, $nsManager)
        }
    }
}}

function Select-Xml {
#.Synopsis
#  The Select-XML cmdlet lets you use XPath queries to search for text in XML strings and documents. Enter an XPath query, and use the Content, Path, or Xml parameter to specify the XML to be searched.
#.Description
#  Improves over the built-in Select-XML by leveraging Remove-XmlNamespace to provide a -RemoveNamespace parameter -- if it's supplied, all of the namespace declarations and prefixes are removed from all XML nodes (by an XSL transform) before searching.  
#  
#  However, only raw XmlNodes are returned from this function, so the output isn't currently compatible with the built in Select-Xml, but is equivalent to using Select-Xml ... | Select-Object -Expand Node
#
#  Also note that if the -RemoveNamespace switch is supplied the returned results *will not* have namespaces in them, even if the input XML did, and entities get expanded automatically.
[CmdletBinding(DefaultParameterSetName="Xml")]
param(
    # Specifies an XPath search query. The query language is case-sensitive. This parameter is required.
    [Parameter(Position=1,Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [Alias("Query")]
    [String[]]$XPath
,
    # Specifies a string that contains the XML to search. You can also pipe strings to Select-XML.
    [Parameter(ParameterSetName="Content",Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Content
,
    # Specifies the path and file names of the XML files to search.  Wildcards are permitted.
    [Parameter(Position=5,ParameterSetName="Path",Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("PSPath")]
    [String[]]$Path
,
    # Specifies one or more XML nodes to search.
    [Parameter(Position=5,ParameterSetName="Xml",Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Node")]
    [System.Xml.XmlNode[]]$Xml
,
    # Specifies a hash table of the namespaces used in the XML. Use the format @{<namespaceName> = <namespaceUri>}.
    [Parameter(Position=10,Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Alias("Ns")]
    [Hashtable]$Namespace
,
    # Allows the execution of XPath queries without namespace qualifiers. 
    # 
    # If you specify the -RemoveNamespace switch, all namespace declarations and prefixes are actually removed from the Xml before the XPath search query is evaluated, and your XPath query should therefore NOT contain any namespace prefixes.
    # 
    # Note that this means that the returned results *will not* have namespaces in them, even if the input XML did, and entities get expanded automatically.
    [Alias("Rn","Rm")]
    [Switch]$RemoveNamespace
)
begin {
    $NSM = $Null; if($PSBoundParameters.ContainsKey("Namespace")) { $NSM = $Namespace }
    $XmlNodes = New-Object System.Xml.XmlNode[] 1
    if($PSCmdlet.ParameterSetName -eq "Content") {
        $XmlNodes = Get-XmlContent $Content -RemoveNamespace:$RemoveNamespace
        Select-XmlNodeInternal $XmlNodes $XPath $NSM
    }
}
process {
    switch($PSCmdlet.ParameterSetName) {
        "Path" {
            $node = Get-XmlContent $Path -RemoveNamespace:$RemoveNamespace
            Select-XmlNodeInternal $node $XPath $NSM
        }
        "Xml" {
            foreach($node in $Xml) {
                if($RemoveNamespace) {
                   [Xml]$node = Remove-XmlNamespace -Xml $node
                }
                Select-XmlNodeInternal $node $XPath $NSM
            }
        }
    }
}}
Set-Alias slxml Select-Xml -EA 0
Set-Alias slx Select-Xml -EA 0


function Update-Xml {
#.Synopsis
#  The Update-XML cmdlet lets you use XPath queries to replace text in nodes in XML documents. Enter an XPath query, and use the Content, Path, or Xml parameter to specify the XML to be searched.
#.Description
#  Allows you to update an attribute value, xml node contents, etc.
#
#.Notes
#  We still need to implement RemoveNode and RemoveAttribute and even ReplaceNode
[CmdletBinding(DefaultParameterSetName="Set")]
param(
    # Specifies an XPath for an element where you want to insert the new node.
    [Parameter(ParameterSetName="Before",Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [Switch]$Before
,
    # Specifies an XPath for an element where you want to insert the new node.
    [Parameter(ParameterSetName="After",Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [Switch]$After
,
    # If set, the new value will be added as a new child of the node identified by the XPath
    [Parameter(ParameterSetName="Append",Mandatory=$true)]
    [Switch]$Append
,
    # If set, the node identified by the XPath will be removed instead of set
    [Parameter(ParameterSetName="Remove",Mandatory=$true)]
    [Switch]$Remove
,
    # If set, the node identified by the XPath will be Replace instead of set
    [Parameter(ParameterSetName="Replace",Mandatory=$true)]
    [Switch]$Replace
,
    # Specifies an XPath for the node to update. This could be an element node *or* an attribute node (remember: //element/@attribute )
    [Parameter(Position=1,Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$XPath
,
    # The new value to place in the xml
    [Parameter(Position=2,Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Value
,
    # Specifies one or more XML nodes to search.
    [Parameter(Position=5,Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Node")]
    [System.Xml.XmlNode[]]$Xml
,   
    # Specifies a hash table of the namespaces used in the XML. Use the format @{<namespaceName> = <namespaceUri>}.
    [Parameter(Position=10,Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Alias("Ns")]
    [Hashtable]$Namespace
,   
    # Output the XML documents after adding updating them
    [Switch]$Passthru
)
process
{
    foreach($XmlNode in $Xml) {
        $select = @{}
        $select.Xml = $XmlNode
        $select.XPath = $XPath
        if($Namespace) {  
            $select.Namespace = $Namespace
        }
        $document =
            if($XmlNode -is [System.Xml.XmlDocument]) {
                $XmlNode
            } else { 
                $XmlNode.get_OwnerDocument()
            }
        if($xValue = $Value -as [Xml]) {
            $xValue = $document.ImportNode($xValue.SelectSingleNode("/*"), $true)
        }
        $nodes = Select-Xml @Select | Where-Object { $_ }

        if(@($nodes).Count -eq 0) { Write-Warning "No nodes matched your XPath, nothing will be updated" }
        
        foreach($node in $nodes) {
            $select.XPath = "$XPath/parent::*"
            $parent = Select-Xml @Select
            if(!$xValue) {
                if($node -is [System.Xml.XmlAttribute] -and $Value.Contains("=")) {
                    $aName, $aValue = $Value.Split("=",2)
                    if($aName.Contains(":")){
                        $ns,$name = $aName.Split(":",2)
                        $xValue = $document.CreateAttribute( $name, $Namespace[$ns] )
                    } else {
                        $xValue = $document.CreateAttribute( $aName )
                    }
                    $xValue.Value = $aValue
                }
            }
            
            switch($PSCmdlet.ParameterSetName) {
                "Before" {
                    $null = $parent.InsertBefore( $xValue, $node )
                }
                "After" {
                    $null = $parent.InsertAfter( $xValue, $node )
                }
                "Append" {
                    $null = $parent.AppendChild( $xValue )
                }
                "Remove" {
                    $null = $parent.RemoveChild( $node )
                }
                "Replace" {
                    if(!$xValue) {
                        $xValue = $document.CreateTextNode( $Value )
                    }
                    $null = $parent.ReplaceChild( $xValue, $node )
                }
                "Set" {
                    if(!$xValue -and $node."#text") {
                        $node."#text" = $Value
                    } else {
                        if($node -is [System.Xml.XmlElement]) {
                            if(!$xValue) {
                                $xValue = $document.CreateTextNode( $Value )
                            }
                            $null = $node.set_innerXml("")
                            $null = $node.AppendChild($xValue)
                        }
                        elseif($node -is [System.Xml.XmlAttribute]) {
                            $node.Value = $Value
                        } else {
                            Write-Warning "$XPath selects a node of type $($node.GetType()), which we haven't handled. Please add that handler!"
                        }
                    }
                }
            }
        }
        if($Passthru) {
            Write-Output $XmlNode
        }
    }
}}
Set-Alias uxml Update-Xml -EA 0
Set-Alias ux Update-Xml -EA 0

function Convert-Node {
#.Synopsis 
# Convert a single XML Node via XSL stylesheets
[CmdletBinding(DefaultParameterSetName="Reader")]
param(
   [Parameter(ParameterSetName="ByNode",Mandatory=$true,ValueFromPipeline=$true)]
   [System.Xml.XmlNode]$Node
,
   [Parameter(ParameterSetName="Reader",Mandatory=$true,ValueFromPipeline=$true)]
   [System.Xml.XmlReader]$XmlReader
,
   [Parameter(Position=1,Mandatory=$true,ValueFromPipeline=$false)]
   [System.Xml.Xsl.XslCompiledTransform]$StyleSheet
,
   [Parameter(Position=2,Mandatory=$false)]
   [Alias("Parameters")]
   [hashtable]$Arguments
)
PROCESS {
   if($PSCmdlet.ParameterSetName -eq "ByNode") {
      $XmlReader = New-Object Xml.XmlNodeReader $node
   }

   $output = New-Object IO.StringWriter
   $argList = $null
   
   if($Arguments) {
      $argList = New-Object System.Xml.Xsl.XsltArgumentList
      foreach($arg in $Arguments.GetEnumerator()) {
         $namespace, $name = $arg.Key -split ":"
         ## Fix namespace
         if(!$name) { 
            $name = $Namespace
            $namespace = ""
         }
         
         Write-Verbose "ns:$namespace name:$name value:$($arg.Value)"
         $argList.AddParam($name,"$namespace",$arg.Value)
      }
   }
   
   $StyleSheet.Transform( $XmlReader, $argList, $output )
   Write-Output $output.ToString()
}
}

function Convert-Xml {
#.Synopsis
#   The Convert-XML function lets you use Xslt to transform XML strings and documents.
#.Description
#   Documentation TODO
[CmdletBinding(DefaultParameterSetName="Xml")]
param(
    # Specifies one or more XML nodes to process.
    [Parameter(Position=1,ParameterSetName="Xml",Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Node")]
    [System.Xml.XmlNode[]]$Xml
,   
    # Specifies an Xml StyleSheet to transform with...
    [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [Alias("StyleSheet")]
    [String]$Xslt
,
    # Specify arguments to the XSL Transformation
    [Alias("Parameters")]
    [hashtable]$Arguments
)
begin { 
   $StyleSheet = New-Object System.Xml.Xsl.XslCompiledTransform
   if(Test-Path $Xslt -EA 0) { 
      Write-Verbose "Loading Stylesheet from $(Resolve-Path $Xslt)"
      $StyleSheet.Load( (Resolve-Path $Xslt) )
   } else {
      $OFS = "`n"
      Write-Verbose "$Xslt"
      $StyleSheet.Load(([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader $Xslt))))
   }
}
process {
   foreach($node in $Xml) {
      Convert-Node -Xml (New-Object Xml.XmlNodeReader $node) $StyleSheet $Arguments
   }
}
}
Set-Alias cvxml Convert-Xml -EA 0

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
#  There will be one output document for each matching input file.
#.Parameter Xml
#  Specifies one or more XML documents to transform
[CmdletBinding(DefaultParameterSetName="Xml")]
PARAM(
   [Parameter(Position=1,ParameterSetName="Xml",Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
   [ValidateNotNullOrEmpty()]
   [Alias("Node")]
   [System.Xml.XmlNode[]]$Xml
)
BEGIN { 
   $StyleSheet = New-Object System.Xml.Xsl.XslCompiledTransform
   $StyleSheet.Load(([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader @"
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
   [Text.StringBuilder]$XmlContent = [String]::Empty 
}
PROCESS {
   $Xml | Convert-Node $StyleSheet
}
}
Set-Alias rmns Remove-XmlNamespace -EA 0
Set-Alias rmxns Remove-XmlNamespace -EA 0





function Remove-XmlElement {
#.Synopsis
#  Removes specified elements (tags or attributes) or all elements from a specified namespace from an Xml document
#.Description
#  Runs an xml document through an XSL Transformation to remove tag namespaces from it if they exist.
#  Entities are also naturally expanded
#.Parameter Content
#  Specifies a string that contains the XML to transform.
#.Parameter Path
#  Specifies the path and file names of the XML files to transform. Wildcards are permitted.
#
#  There will be one output document for each matching input file.
#.Parameter Xml
#  Specifies one or more XML documents to transform
[CmdletBinding(DefaultParameterSetName="Xml")]
PARAM(
   [Parameter(Position=0,ParameterSetName="Xml")] #,Mandatory=$true
   #[ValidateNotNullOrEmpty()]
   [XNamespace[]]$Namespace
,
   [Parameter(Position=1,ParameterSetName="Xml",Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
   [ValidateNotNullOrEmpty()]
   [Alias("Node")]
   [System.Xml.XmlNode[]]$Xml
)
BEGIN {
   foreach($Node in @($Xml)) {
      $Allspaces += Get-Namespace -Xml $Node

      $nsManager = new-object System.Xml.XmlNamespaceManager $node.NameTable
      foreach($ns in $Allspaces.GetEnumerator()) {
          $nsManager.AddNamespace( $ns.Key, $ns.Value )
      }

      # If no namespaces are passed in, use the "ignorable" ones from XAML if there are any
      if(!$Namespace) {
         $root = $Node.DocumentElement
         # $nsManager = new-object System.Xml.XmlNamespaceManager $Node.NameTable                       
         $nsManager.AddNamespace("compat", "http://schemas.openxmlformats.org/markup-compatibility/2006")
         if($ignorable = $root.SelectSingleNode("@compat:Ignorable",$nsManager)) {
            foreach($prefix in $ignorable.get_InnerText().Split(" ")) {
               $Namespace += $root.GetNamespaceOfPrefix($prefix)
            }
         }
      }
   }

   
   Write-Verbose "$Namespace"
   $i = 0
   $NSString = $(foreach($n in $Namespace) { "xmlns:n$i='$n'"; $i+=1 }) -Join " "
   $EmptyTransforms = $(for($i =0; $i -lt $Namespace.Count;$i++) {
      "<xsl:template match='n${i}:*'>
      </xsl:template>
      <xsl:template match='@n${i}:*'>
      </xsl:template>"
   })
   
   $XSLT = @"
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" $NSString>
   <xsl:output method="xml" indent="yes"/>
   <xsl:template match="@*|node()">
      <xsl:copy>
         <xsl:apply-templates select="@*|node()"/>
      </xsl:copy>
   </xsl:template>
   $EmptyTransforms
</xsl:stylesheet>
"@
   Write-Verbose $XSLT
 
   $StyleSheet = New-Object System.Xml.Xsl.XslCompiledTransform
   $StyleSheet.Load(([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader $XSLT))))
   [Text.StringBuilder]$XmlContent = [String]::Empty 
}
PROCESS {
   $Xml | Convert-Node $StyleSheet
}
}
#Set-Alias rmns Remove-XmlNamespace -EA 0
#Set-Alias rmxns Remove-XmlNamespace -EA 0

function Get-Namespace {
param(
   [Parameter(Position=0)]
   [String[]]$Prefix = "*"
,
   [Parameter(Position=1,ParameterSetName="Xml",Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
   [ValidateNotNullOrEmpty()]
   [Alias("Node")]
   [System.Xml.XmlNode[]]$Xml
)
   foreach($Node in @($Xml)) {
      $results = @{}
      if($Node -is [Xml.XmlDocument]) {
         $Node = $Node.DocumentElement
      }
      foreach($ns in $Node.CreateNavigator().GetNamespacesInScope("All").GetEnumerator()) {
         foreach($p in $Prefix) {
            if($ns.Key -like $p) {
               $results.Add($ns.Key, $ns.Value)
               break;
            }
         }
      }
      $results
   }
}



######## Helper functions for working with CliXml

function ConvertFrom-CliXml {
   param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [ValidateNotNullOrEmpty()]
      [String[]]$InputObject
   )
   begin
   {
      $OFS = "`n"
      [String]$xmlString = ""
   }
   process
   {
      $xmlString += $InputObject
   }
   end
   {
      $type = [psobject].assembly.gettype("System.Management.Automation.Deserializer")
      $ctor = $type.getconstructor("instance,nonpublic", $null, @([xml.xmlreader]), $null)
      $sr = new-object System.IO.StringReader $xmlString
      $xr = new-object System.Xml.XmlTextReader $sr
      $deserializer = $ctor.invoke($xr)
      $method = @($type.getmethods("nonpublic,instance") | where-object {$_.name -like "Deserialize"})[1]
      $done = $type.getmethod("Done", [System.Reflection.BindingFlags]"nonpublic,instance")
      while (!$done.invoke($deserializer, @()))
      {
         try {
            $method.invoke($deserializer, "")
         } catch {
            write-warning "Could not deserialize $xmlString"
         }
      }
      $xr.Close()
      $sr.Dispose()
   }
}

function ConvertTo-CliXml {
   param(
      [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
      [ValidateNotNullOrEmpty()]
      [PSObject[]]$InputObject
   )
   begin {
      $type = [psobject].assembly.gettype("System.Management.Automation.Serializer")
      $ctor = $type.getconstructor("instance,nonpublic", $null, @([System.Xml.XmlWriter]), $null)
      $sw = new-object System.IO.StringWriter
      $xw = new-object System.Xml.XmlTextWriter $sw
      $serializer = $ctor.invoke($xw)
      $method = $type.getmethod("Serialize", "nonpublic,instance", $null, [type[]]@([object]), $null)
      $done = $type.getmethod("Done", [System.Reflection.BindingFlags]"nonpublic,instance")
   }
   process {
      try {
         [void]$method.invoke($serializer, $InputObject)
      } catch {
         write-warning "Could not serialize $($InputObject.gettype()): $InputObject"
      }
   }
   end {    
      [void]$done.invoke($serializer, @())
      $sw.ToString()
      $xw.Close()
      $sw.Dispose()
   }
}


######## From here down is all the code related to my XML DSL:

function New-XDocument {
#.Synopsis
#   Creates a new XDocument (the new xml document type)
#.Description
#  This is the root for a new XML mini-dsl, akin to New-BootsWindow for XAML
#  It creates a new XDocument, and takes scritpblock(s) to define it's contents
#.Example
# [string]$xml = New-XDocument rss -version "2.0" {
#    channel {
#       title {"Test RSS Feed"}
#       link {"http`://HuddledMasses.org"}
#       description {"An RSS Feed generated simply to demonstrate my XML DSL"}
#       item {
#          title {"The First Item"}
#          link {"http`://huddledmasses.org/new-site-new-layout-lost-posts/"}
#          guid -isPermaLink true {"http`://huddledmasses.org/new-site-new-layout-lost-posts/"}
#          description {"Ema Lazarus' Poem"}
#          pubDate {(Get-Date 10/31/2003 -f u) -replace " ","T"}
#       }
#    }
# }
#
# C:\PS>$xml.Declaration.ToString()  ## I can't find a way to have this included in the $xml.ToString()
# C:\PS>$xml.ToString()
#
# <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
# <rss version="2.0">
#   <channel>
#     <title>Test RSS Feed</title>
#     <link>http ://HuddledMasses.org</link>
#     <description>An RSS Feed generated simply to demonstrate my XML DSL</description>
#     <item>
#       <title>The First Item</title>
#       <link>http ://huddledmasses.org/new-site-new-layout-lost-posts/</link>
#       <guid isPermaLink="true">http ://huddledmasses.org/new-site-new-layout-lost-posts/</guid>
#       <description>Ema Lazarus' Poem</description>
#       <pubDate>2003-10-31T00:00:00Z</pubDate>
#     </item>
#   </channel>
# </rss>
#
#
# Description
# -----------
# This example shows the creation of a complete RSS feed with a single item in it. 
#
# NOTE that the backtick in the http`: in the URLs in the input is unecessary, and I added the space after the http: in the URLs  in the output -- these are accomodations to PoshCode's spam filter. Backticks are not need in the input, and spaces do not appear in the actual output.
#
#
#.Example 
# [XNamespace]$atom="http`://www.w3.org/2005/Atom"
# C:\PS>[XNamespace]$dc = "http`://purl.org/dc/elements/1.1"
# 
# C:\PS>New-XDocument ($atom + "feed") -Encoding "UTF-16" -$([XNamespace]::Xml +'lang') "en-US" -dc $dc {
#    title {"Test First Entry"}
#    link {"http`://HuddledMasses.org"}
#    updated {(Get-Date -f u) -replace " ","T"}
#    author {
#       name {"Joel Bennett"}
#       uri {"http`://HuddledMasses.org"}
#    }
#    id {"http`://huddledmasses.org/" }
#
#    entry {
#       title {"Test First Entry"}
#       link {"http`://HuddledMasses.org/new-site-new-layout-lost-posts/" }
#       id {"http`://huddledmasses.org/new-site-new-layout-lost-posts/" }
#       updated {(Get-Date 10/31/2003 -f u) -replace " ","T"}
#       summary {"Ema Lazarus' Poem"}
#       link -rel license -href "http`://creativecommons.org/licenses/by/3.0/" -title "CC By-Attribution"
#       dc:rights { "Copyright 2009, Some rights reserved (licensed under the Creative Commons Attribution 3.0 Unported license)" }
#       category -scheme "http`://huddledmasses.org/tag/" -term "huddled-masses"
#    }
# } | % { $_.Declaration.ToString(); $_.ToString() }
#
# <?xml version="1.0" encoding="UTF-16" standalone="yes"?>
# <feed xml:lang="en-US" xmlns="http ://www.w3.org/2005/Atom">
#   <title>Test First Entry</title>
#   <link>http ://HuddledMasses.org</link>
#   <updated>2009-07-29T17:25:49Z</updated>
#   <author>
#      <name>Joel Bennett</name>
#      <uri>http ://HuddledMasses.org</uri>
#   </author>
#   <id>http ://huddledmasses.org/</id>
#   <entry>
#     <title>Test First Entry</title>
#     <link>http ://HuddledMasses.org/new-site-new-layout-lost-posts/</link>
#     <id>http ://huddledmasses.org/new-site-new-layout-lost-posts/</id>
#     <updated>2003-10-31T00:00:00Z</updated>
#     <summary>Ema Lazarus' Poem</summary>
#     <link rel="license" href="http ://creativecommons.org/licenses/by/3.0/" title="CC By-Attribution" />
#     <dc:rights>Copyright 2009, Some rights reserved (licensed under the Creative Commons Attribution 3.0 Unported license)</dc:rights>
#     <category scheme="http ://huddledmasses.org/tag/" term="huddled-masses" />
#   </entry>
# </feed>
#
#
# Description
# -----------
# This example shows the use of a default namespace, as well as additional specific namespaces for the "dc" namespace. It also demonstrates how you can get the <?xml?> declaration which does not appear in a simple .ToString().
#
# NOTE that the backtick in the http`: in the URLs in the input is unecessary, and I added the space after the http: in the URLs  in the output -- these are accomodations to PoshCode's spam filter. Backticks are not need in the input, and spaces do not appear in the actual output.#
# 
[CmdletBinding()]
Param(
   # The root node name
   [Parameter(Mandatory = $true, Position = 0)]
   [System.Xml.Linq.XName]$root
,
   # Optional: the XML version. Defaults to 1.0
   [Parameter(Mandatory = $false)]
   [string]$Version = "1.0"
,
   # Optional: the Encoding. Defaults to UTF-8
   [Parameter(Mandatory = $false)]
   [string]$Encoding = "UTF-8"
,
   # Optional: whether to specify standalone in the xml declaration. Defaults to "yes"
   [Parameter(Mandatory = $false)]
   [string]$Standalone = "yes"
,
   # A Hashtable of parameters which should be available as local variables to the scriptblock in args
   [Parameter(Mandatory = $false)]
   [hashtable]$Parameters
,
   # this is where all the dsl magic happens. Please see the Examples. :)
   [AllowNull()][AllowEmptyString()][AllowEmptyCollection()]
   [Parameter(Position=99, Mandatory = $false, ValueFromRemainingArguments=$true)]
   [PSObject[]]$args
)
BEGIN {
   $script:NameSpaceHash = New-Object 'Dictionary[String,XNamespace]'
   if($root.NamespaceName) {
      $script:NameSpaceHash.Add("", $root.Namespace)
   }
}
PROCESS {
   if($Parameters) {
      foreach($key in $Parameters.Keys) {
         Set-Variable $key $Parameters.$key -Scope Script
      }
   }
   New-Object XDocument (New-Object XDeclaration $Version, $Encoding, $standalone),(
      New-Object XElement $(
         $root
         while($args) {
            $attrib, $value, $args = $args
            if($attrib -is [ScriptBlock]) {
               # Write-Verbose "Preparsed DSL: $attrib"
               $attrib = ConvertFrom-XmlDsl $attrib
               Write-Verbose "Reparsed DSL: $attrib"
               & $attrib
            } elseif ( $value -is [ScriptBlock] -and "-DSL".StartsWith($attrib.TrimEnd(':').ToUpper())) {
               $value = ConvertFrom-XmlDsl $value
               Write-Verbose "Reparsed DSL: $value"
               & $value
            } elseif ( $value -is [ScriptBlock] -and "-CONTENT".StartsWith($attrib.TrimEnd(':').ToUpper())) {
               & $value
            } elseif ( $value -is [XNamespace]) {
               New-Object XAttribute ([XNamespace]::Xmlns + $attrib.TrimStart("-").TrimEnd(':')), $value
               $script:NameSpaceHash.Add($attrib.TrimStart("-").TrimEnd(':'), $value)
            } else {
               Write-Verbose "XAttribute $attrib = $value"
               New-Object XAttribute $attrib.TrimStart("-").TrimEnd(':'), $value
            }
         }
      ))
}
}

Set-Alias xml New-XDocument -EA 0
Set-Alias New-Xml New-XDocument -EA 0

function New-XAttribute {
#.Synopsys
#   Creates a new XAttribute (an xml attribute on an XElement for XDocument)
#.Description
#  This is the work-horse for the XML mini-dsl
#.Parameter name
#   The attribute name
#.Parameter value
#  The attribute value
[CmdletBinding()]
Param([Parameter(Mandatory=$true)]$name,[Parameter(Mandatory=$true)]$value)
   New-Object XAttribute $name, $value
}
Set-Alias xa New-XAttribute -EA 0
Set-Alias New-XmlAttribute New-XAttribute -EA 0


function New-XElement {
#.Synopsys
#   Creates a new XElement (an xml tag for XDocument)
#.Description
#  This is the work-horse for the XML mini-dsl
#.Parameter tag
#   The name of the xml tag
#.Parameter args
#   this is where all the dsl magic happens. Please see the Examples. :)
[CmdletBinding()]
Param(
   [Parameter(Mandatory = $true, Position = 0)]
   [System.Xml.Linq.XName]$tag
,
   [AllowNull()][AllowEmptyString()][AllowEmptyCollection()]
   [Parameter(Position=99, Mandatory = $false, ValueFromRemainingArguments=$true)]
   [PSObject[]]$args
)
PROCESS {
  New-Object XElement $(
     $tag
     Write-Verbose "New-XElement $tag $($args -join ',')"
     while($args) {
        $attrib, $value, $args = $args
        if($attrib -is [ScriptBlock]) { # then it's content
           & $attrib
        } elseif ( $value -is [ScriptBlock] -and "-CONTENT".StartsWith($attrib.TrimEnd(':').ToUpper())) { # then it's content
           & $value
        } elseif ( $value -is [XNamespace]) {
           Write-Verbose "New XAttribute xmlns: $($attrib.TrimStart("-").TrimEnd(':')) = $value"
           New-Object XAttribute ([XNamespace]::Xmlns + $attrib.TrimStart("-").TrimEnd(':')), $value
           $script:NameSpaceHash.Add($attrib.TrimStart("-").TrimEnd(':'), $value)
        } elseif($value -match "^-(?!\d)\w") {
            $args = @($value)+@($args)
        } elseif($value -ne $null) {
           Write-Verbose "New XAttribute $($attrib.TrimStart("-").TrimEnd(':')) = $value"
           New-Object XAttribute $attrib.TrimStart("-").TrimEnd(':'), $value
        }        
     }
   )
}
}
Set-Alias xe New-XElement
Set-Alias New-XmlElement New-XElement

function ConvertFrom-XmlDsl {
Param([ScriptBlock]$script)
   $parserrors = $null
   $global:tokens = [PSParser]::Tokenize( $script, [ref]$parserrors )
   [Array]$duds = $global:tokens | Where-Object { $_.Type -eq "Command" -and !$_.Content.Contains('-') -and ($(Get-Command $_.Content -Type Alias,Cmdlet,Function,ExternalScript -EA 0) -eq $Null) }
   if($duds) {
     [Array]::Reverse( $duds )
   }
   [string[]]$ScriptText = "$script" -split "`n"

   ForEach($token in $duds ) {
    # replace : notation with namespace notation
    if( $token.Content.Contains(":") ) {
     $key, $localname = $token.Content -split ":"
     $ScriptText[($token.StartLine - 1)] = $ScriptText[($token.StartLine - 1)].Remove( $token.StartColumn -1, $token.Length ).Insert( $token.StartColumn -1, "'" + $($script:NameSpaceHash[$key] + $localname) + "'" )
    } else {
     $ScriptText[($token.StartLine - 1)] = $ScriptText[($token.StartLine - 1)].Remove( $token.StartColumn -1, $token.Length ).Insert( $token.StartColumn -1, "'" + $($script:NameSpaceHash[''] + $token.Content) + "'" )
    }
    # insert 'xe' before everything (unless it's a valid command)
    $ScriptText[($token.StartLine - 1)] = $ScriptText[($token.StartLine - 1)].Insert( $token.StartColumn -1, "xe " )
   }
   Write-Output ([ScriptBlock]::Create( ($ScriptText -join "`n") ))
}



######## Xaml
#  if($PSVersionTable.CLRVersion -ge "4.0"){
#     trap { continue }
#     [Reflection.Assembly]::LoadWithPartialName("System.Xaml") | Out-Null
#     if("System.Xaml.XamlServices" -as [type]) {
    
   #  }
#  }
   
Export-ModuleMember -alias * -function New-XDocument, New-XAttribute, New-XElement, Remove-XmlNamespace, Remove-XmlElement, Get-Namespace, Get-XmlContent, Set-XmlContent, Convert-Xml, Select-Xml, Update-Xml, Format-Xml, ConvertTo-CliXml, ConvertFrom-CliXml

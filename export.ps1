function Export-PoshCodeGithub {
[CmdletBinding()]
param(
    [Parameter(ValueFromPipelineByPropertyName)]
    $parent,

    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias("child")]
    $children,

    [Parameter(ValueFromPipelineByPropertyName)]
    [alias("pid")]
    $id,

    [Parameter(ValueFromPipelineByPropertyName)]
    [alias("poster")]
    $author,

    [Parameter(ValueFromPipelineByPropertyName)]
    $title,

    [Parameter(ValueFromPipelineByPropertyName)]
    $date,

    [Parameter(ValueFromPipelineByPropertyName)]
    $description,

    [Parameter(ValueFromPipelineByPropertyName)]
    [alias("format")]
    $Language,

    [Parameter(ValueFromPipelineByPropertyName)]
    $code
)
process {

$extension = switch($Language) {
    "asp"        { ".asp" }
    "bash"       { ".sh" }
    "cpp"        { ".cpp" }
    "csharp"     { ".cs" }
    "javascript" { ".js" }
    "posh"       { ".ps1" }
    "text"       { ".txt" }
    "vbnet"      { ".vb" }
    "xml"        { ".xml" }
}

# Work around PowerShell's insistence on BOMs
function Write-AllLines {
    param($Path, $Content)
    $null = New-Item $Path -Type File -Force
    [IO.File]::WriteAllLines((Convert-Path $Path), $content)
}


Write-AllLines "scripts\$id.md" @"
---
pid:            $id
poster:         $author
title:          $title
date:           $date
format:         $Language
parent:         $parent
$(if($parent){   "parent:         $($parent -join ',')"})
$(if($children){ "children:       $($children -join ',')"})
---

# $title

### [download]($id$extension)$(if($parent -ne 0) { " - [parent]($parent.md)" })$( if($children){  " - children: $($(foreach($child in $children) { "[$child]($child.md)" }) -join ', ')" })

$description

``````$language
$code
``````
"@



Write-AllLines "scripts\$id$extension" $code

}
}
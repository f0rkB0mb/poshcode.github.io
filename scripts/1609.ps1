$mytypes = @()
function run-csharpexpression([string] $expression )
{
$global:ccounter = [int]$ccounter + 1
$local:name  =  [system.guid]::NewGuid().tostring().replace('-','_').insert(0,"csharpexpr")
$local:ns = "ShellTools.DynamicCSharpExpression.N${ccounter}"

$local:template = @"
using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;

namespace $ns
{
public static class Runner
{
public static object RunExpression()
{
return [[EXPRESSION]];
}
}
}
"@

$local:source = $local:template.replace("[[EXPRESSION]]",$expression)
#saving to a temporary file so that the error with anonymous types with the same signature doesn't happen
$local:filename = [System.IO.Path]::GetTempFileName()
$null = add-Type $local:source -Language CsharpVersion3 -outputassembly $local:filename 
$null = [System.Reflection.Assembly]::LoadFile($local:filename )
invoke-Expression ('[' + $local:ns + '.Runner]::RunExpression()')
}

set-alias c run-csharpexpression

#test code
c "new{a=1,b=2,c=3}"
c "new{a=1,b=2,c=3}"
(c DateTime.Now).adddays(5)
(c "new{a=1,b=2,c=3}").b
c 'from x in Directory.GetFiles(@"c:\downloads") where x.Contains("win") select x'




#Copyright (c) 2011 Justin Dearing
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.

# The authoritative version is https://github.com/justaprogrammer/PowerShellScripts/blob/master/Script-Proc.ps1. 
# If you have a change I'd love to know about it to consider merging it into github.

param(
    [Parameter(Mandatory=$true,HelpMessage='The name of the stored procedure or user defined function we wish to script')]
    [string] $ProcedureName,
    [string] $Path = "$($ProcedureName).sql",
    [string] $ConnectionString = 'Data Source=.\sqlexpress2k8R2;Initial Catalog=master;Integrated Security=SSPI;'
);

try {
    [System.Data.SqlClient.SqlConnection] $cn = New-Object System.Data.SqlClient.SqlConnection (,$ConnectionString);
    $cn.Open() > $null;
    $cmd = $cn.CreateCommand();
    $cmd.CommandType = [System.Data.CommandType]::StoredProcedure;
    $cmd.CommandText = 'sp_helptext';
    $cmd.Parameters.AddWithValue('@objname', $ProcedureName) > $null;
    [System.Data.IDataReader] $rdr = $cmd.ExecuteReader();
    [string] $sproc_text = '';
    while ($rdr.Read()) {
        $sproc_text += $rdr[0];
    }
    $rdr.Close();
    $sproc_text | Out-File -FilePath $Path;
}
finally {
    if ($cmd -ne $null) { $cmd.Dispose(); }
    if ($cn -ne $null) { $cn.Dispose(); }
}

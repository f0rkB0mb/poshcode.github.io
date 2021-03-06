#function Get-ProcessorInfo {
  $flags = [Reflection.BindingFlags]
  
  $NativeMethods = [PSObject].Assembly.GetType(
    'System.Management.Automation.PsUtils'
  ).GetNestedType('NativeMethods', (32 -as $flags))
  $SYSTEM_INFO = $NativeMethods.GetNestedType('SYSTEM_INFO', (32 -as $flags))
  
  try { $asm = [SysInfo] } catch [Management.Automation.RuntimeException] {
    $AsmBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(
      (New-Object Reflection.AssemblyName('NatMet')), [Reflection.Emit.AssemblyBuilderAccess]::Run
    )
    $ModBuilder = $AsmBuilder.DefineDynamicModule('NatMet', $false)
    $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
    $TypBuilder = $ModBuilder.DefineType('SysInfo', $Attributes, [ValueType])
    [void]$TypBuilder.DefinePInvokeMethod('GetSystemInfo', 'kernel32.dll', `
         [Reflection.MethodAttributes]22, [Reflection.CallingConventions]1, [Void], `
      @($SYSTEM_INFO.MakeByRefType()), [Runtime.InteropServices.CallingConvention]::Winapi, 'Auto')
    $asm = $TypBuilder.CreateType()
  }
  
  $SystemInfo = [Activator]::CreateInstance($SYSTEM_INFO)
  $asm::GetSystemInfo([ref]$SystemInfo)
  $SystemInfo.PSObject.Properties | % {
    if ($_.Name -eq 'wProcessorArchitecture') {
      '{0, 27}: {1}' -f $_.Name, $(
        foreach ($i in $NativeMethods.GetFields((44 -as $flags))) {
          if ($i.GetValue($null) -eq $_.Value) { $i.Name }
        }
      )
    }
    elseif ($_.Name -eq 'dwProcessorType') {
      '{0, 27}: {1}' -f $_.Name, $(
        switch($_.Value){386{'INTEL386'}486{'INTEL486'}586{'INTEL_PENTIUM'}2200{'INTEL_IA64'}8664{'AMD_X8664'}}
      )
    }
    else {
      '{0, 27}: {1}' -f $_.Name, $_.Value
    }
  }
  ""
#}

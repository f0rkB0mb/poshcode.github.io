#As you know there is Stream key in Get-Item cmdlet (in PowerShell ver. -gt 2.0)
#so you do not need any third party utilities to determaine alternative streams
#but PowerShell -le v2 does not support this feature that's why you should
#A)write your own extension, for example:
Set-Alias streams Get-FileStreams

$code = @'
using System;
using System.IO;
using System.Reflection;
using System.ComponentModel;
using System.Collections.Generic;
using Microsoft.Win32.SafeHandles;
using System.Runtime.InteropServices;

[assembly: AssemblyVersion("2.0.0.0")]
[assembly: CLSCompliant(true)]
[assembly: ComVisible(false)]

namespace PSModule {
  internal static class NativeMethods {
    [DllImport("kernel32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern Boolean BackupRead(
        SafeFileHandle hFile,
        IntPtr lpBuffer,
        UInt32 nNumberOfBytesToRead,
        out UInt32 lpNumberOfBytesRead,
        [MarshalAs(UnmanagedType.Bool)]Boolean bAbort,
        [MarshalAs(UnmanagedType.Bool)]Boolean bProcessSecurity,
        ref IntPtr lpContext
    );
    
    [DllImport("kernel32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern Boolean BackupSeek(
        SafeFileHandle hFile,
        UInt32 dwLowBytesToSeek,
        UInt32 dwHighBytesToSeek,
        out UInt32 lpdwLowByteSeeked,
        out UInt32 lpdwHighByteSeeked,
        ref IntPtr lpContext
    );
  }
  
  public sealed class FSStream {
    private FSStream() {}
    
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct WIN32_STREAM_ID {
      public StreamType dwStreamId;
      public Int32      dwStreamAttributes;
      public Int64      Size;
      public Int32      dwStreamNameSize;
    }
    
    internal enum StreamType { //Int32
      Unknown = 0,
      StandardData,
      ExtendedAttributeData,
      SecurityDescriptorData,
      AlternativeDataStream,
      HardLinkInformation,
      PropertyData,
      ObjectIdentifiers,
      ReparsePoints,
      SparseData,
      TransactionData
    }
    
    internal struct StreamInfo {
      public StreamInfo(String name, StreamType type, Int64 size) {
        Name = name;
        Type = type;
        Size = size;
      }
      public readonly String     Name;
      public readonly StreamType Type;
      public readonly Int64      Size;
    }
    
    internal static IEnumerable<StreamInfo> ParseStreams(FileInfo fi) {
      const Int32 buff = 4096;
      
      using (FileStream fs = fi.OpenRead()) {
        IntPtr ctx = IntPtr.Zero;
        IntPtr buf = Marshal.AllocHGlobal(buff);
        
        try {
          while(true) {
            UInt32 m_Read;
            if (!NativeMethods.BackupRead(fs.SafeFileHandle, buf,
              (UInt32)Marshal.SizeOf(typeof(WIN32_STREAM_ID)), out m_Read, 
              false, true, ref ctx)) throw new Win32Exception();
              
            if (m_Read > 0) {
              WIN32_STREAM_ID s = (WIN32_STREAM_ID)Marshal.PtrToStructure(buf,
                                                     typeof(WIN32_STREAM_ID));
              String name = null;
              
              if (s.dwStreamNameSize > 0) {
                if (!NativeMethods.BackupRead(fs.SafeFileHandle, buf,
                  (UInt32)Math.Min(buff, s.dwStreamNameSize), out m_Read,
                  false, true, ref ctx)) throw new Win32Exception();
                name = Marshal.PtrToStringUni(buf, (Int32)m_Read / 2);
              }
              
              yield return new StreamInfo(name, s.dwStreamId, s.Size);
              
              if (s.Size > 0) {
                UInt32 lo, bi;
                NativeMethods.BackupSeek(fs.SafeFileHandle, UInt32.MaxValue,
                                   Int32.MaxValue, out lo, out bi, ref ctx);
              }
            }
            else break;
          }
        }
        finally {
          Marshal.FreeHGlobal(buf);
        }
      }
    }//IEnumerable
    
    public static void GetStreams(String file) {
      try {
        List<StreamInfo> streams = new List<StreamInfo>(ParseStreams(new FileInfo(file)));
        
        foreach (StreamInfo s in streams) {
          Console.WriteLine("{0, 25} {1, 23} {2}",
            (!String.IsNullOrEmpty(s.Name) ? s.Name : "<Unnamed>"), s.Type, s.Size);
        }
        Console.WriteLine("");
      }
      catch (FileNotFoundException e) {
        Console.WriteLine(e.Message);
      }
    }
  }
}
'@

function Get-FileStreams {
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [String]$FileName
  )
  
  begin {
    Add-Type $code
    $FileName = cvpa $FileName
  }
  process {
    [PSModule.FSStream]::GetStreams($FileName)
  }
  end {}
}
#B) use third party libraries or modules
#C) or if you do like SysInternals streams utility like I do then (if this tool
#has been installed) all you need it just enter something like this:
& (gcm -c Application streams).Name **.**
#or
& (gcm -c Application streams).Definition **.**

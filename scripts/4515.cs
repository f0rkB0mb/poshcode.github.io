using System;
using System.IO;
using System.Reflection;
using System.Diagnostics;
using System.Globalization;

[assembly: AssemblyVersion("2.0.0.0")]

namespace WhatIsTool {
  internal sealed class Program {
    static string[] SplitVariable(string eVar) {
      return Environment.ExpandEnvironmentVariables(eVar).Split(new Char[] {';'});
    }
    
    static void Main(string[] args) {
      string query, desc;
      
      if (args.Length == 1) {
        foreach (string path in SplitVariable("%PATH%")) {
          foreach (string ext in SplitVariable("%PATHEXT%")) {
            query = path + @"\" + args[0] + ext.ToLower(CultureInfo.CurrentCulture);
            if (File.Exists(query)) {
              desc = FileVersionInfo.GetVersionInfo(query).FileDescription;
              Console.WriteLine("{0} - {1}", query, String.IsNullOrEmpty(desc) ? "n/a" : desc);
            }
          }
        }
      }
    }
  }
}

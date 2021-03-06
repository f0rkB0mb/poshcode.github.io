using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Security.Cryptography;
using System.Runtime.InteropServices;
using Microsoft.Win32;
using System.IO;

namespace ConsoleApplication1
{

    public class FileInfoExt
    {
        public FileInfoExt(FileInfo fi)
        {
            FI = fi;                            
            Checked = false;                    // Set if the file has already been checked.            
            string SHA512_1st1K;                // SHA512 hash of first 1K bytes.
            string SHA512_All;                  // SHA512 hash of complete file.
        }
        public FileInfo FI { get; private set; }
        public bool Checked { get; set; }       
        public string SHA512_1st1K { get; set; }
        public string SHA512_All { get; set; }
    }


    class Recurse                               // Return FileInfoExt list of files matching filenames, file specifications (IE: *.*), and in directories in pathRec
    {
        public List<FileInfoExt> Recursive(string[] pathRec, string searchPattern, Boolean recursiveFlag)
        {
            List<FileInfoExt> returnList = new List<FileInfoExt>();

            foreach (string d in pathRec)
            {
                returnList.AddRange(Recursive(d, searchPattern, recursiveFlag));               
            }
             return(returnList);
        }

        public List<FileInfoExt> Recursive(string pathRec, string searchPattern, Boolean recursiveFlag)
        {
            List<FileInfoExt> returnList = new List<FileInfoExt>();

            if (File.Exists(pathRec))
            {
                try
                {
                    returnList.Add(new FileInfoExt(new FileInfo(pathRec)));
                }
                catch (Exception e)
                {
                    Console.WriteLine("Add file error: " + e.Message);
                }
            }
            else if (Directory.Exists(pathRec))
            {
                try
                {
                    DirectoryInfo Dir = new DirectoryInfo(pathRec);
                    returnList.AddRange(Dir.GetFiles(searchPattern).Select(s => new FileInfoExt(s)));
                }
                catch (Exception e)
                {
                    Console.WriteLine("Add files from Directory error: " +e.Message);
                }

                if (recursiveFlag == true)
                {
                    try
                    {
                        foreach (string d in (Directory.GetDirectories(pathRec)))
                        {                            
                            returnList.AddRange(Recursive(d, searchPattern, recursiveFlag));                         
                        }
                    }
                    catch (Exception e)
                    {                        
                        Console.WriteLine("Add Directory error: " + e.Message);
                    }
                }
            }
            else
            {
                string filePart = Path.GetFileName(pathRec);
                string dirPart = Path.GetDirectoryName(pathRec);
                if (filePart.IndexOfAny(new char[] { '?', '*' }) >= 0)
                {
                    if ((dirPart == null) || (dirPart == ""))
                        dirPart = Directory.GetCurrentDirectory();
                    if (Directory.Exists(dirPart))
                    {
                        returnList.AddRange(Recursive(dirPart, filePart, recursiveFlag));
                    }
                    else
                    {
                        Console.WriteLine("Invalid file path, directory path, file specification, or program option specified: " + pathRec);
                    }
                }
                else
                {
                    Console.WriteLine("Invalid file path, directory path, file specification, or program option specified: " + pathRec);
                }
            }
            return (returnList);
        }
    }


    class Program
    {
        public static void Main(string[] args)
        {

            Console.WriteLine("Findup.exe v1.0 - use -help for usage information. Created in 2010 by James Gentile.");
            Console.WriteLine(" ");

            string[] paths = new string[0];
            System.Boolean recurse = false;
            System.Boolean delete = false;
            System.Boolean noprompt = false;
            List<FileInfoExt> fs = new List<FileInfoExt>();
            long numOfDupes = 0;
            long bytesRec = 0;                                  // number of bytes recovered.
            long delFiles = 0;                                  // number of files deleted.
            int c = 0;
            int i = 0;
            string deleteConfirm;

            for (i = 0; i < args.Length; i++)
            {
                if ((args[i] == "-help") || (args[i] == "-h"))
                {
                    Console.WriteLine("Usage:    findup.exe <file/directory #1> <file/directory #2> ... <file/directory #N> [-recurse] [-delete] [-noprompt]");
                    Console.WriteLine(" ");
                    Console.WriteLine("Options:  -help     - displays this help infomration.");
                    Console.WriteLine("          -recurse  - recurses through subdirectories.");
                    Console.WriteLine("          -delete   - deletes duplicates with confirmation prompt.");
                    Console.WriteLine("          -noprompt - when used with -delete option, deletes files without confirmation prompt.");
                    Console.WriteLine(" ");
                    Console.WriteLine("Examples: findup.exe c:\\finances -recurse");
                    Console.WriteLine("          findup.exe c:\\users\\alice\\plan.txt d:\\data -recurse -delete -noprompt");
                    Console.WriteLine(" ");
                    Environment.Exit(0);
                }
                if (args[i] == "-recurse")
                {
                    recurse = true;
                    continue;
                }
                if (args[i] == "-delete")
                {
                    delete = true;
                    continue;
                }
                if (args[i] == "-noprompt")
                {
                    noprompt = true;
                    continue;
                }
                Array.Resize(ref paths, paths.Length + 1);
                paths[c] = args[i];
                c++;
            }

            if (paths.Length == 0)
            {
                Console.WriteLine("No files specified, try findup.exe -help");
                Environment.Exit(0);
            }

            Recurse recurseMe = new Recurse();            
            fs.AddRange(recurseMe.Recursive(paths, "*.*", recurse));

            if (fs.Count < 2)
            {
                Console.WriteLine("Findup.exe needs at least 2 files to compare. try findup.exe -help");
                Environment.Exit(0);
            }

            for (i = 0; i < fs.Count; i++)
            {
                if (fs[i].Checked == true)
                    continue;
                fs[i].Checked = true;
              
                for (c = 0; c < fs.Count; c++)
                {
                    if (fs[c].Checked == true)
                        continue;
                    if (fs[i].FI.Length != fs[c].FI.Length)                                 // If file size matches, then check hash.
                        continue;                    
                    if (fs[i].FI.FullName == fs[c].FI.FullName)                             // don't count the same file as a match.
                        continue;                    
                    if (fs[i].SHA512_1st1K == null)                                         // check/hash first 1K first.
                        fs[i].SHA512_1st1K = ComputeInitialHash(fs[i].FI.FullName);                    
                    if (fs[c].SHA512_1st1K == null)
                        fs[c].SHA512_1st1K = ComputeInitialHash(fs[c].FI.FullName);                    
                    if (fs[i].SHA512_1st1K != fs[c].SHA512_1st1K)                           // if the 1st 1K has the same hash..
                        continue;
                    if (fs[i].SHA512_1st1K == null)                                         // if hash error, then skip to next file.
                        continue;
                    if (fs[i].FI.Length > 1024)                                             // skip hashing the file again if < 1024 bytes.
                    {
                        if (fs[i].SHA512_All == null)                                       // check/hash the rest of the files.
                            fs[i].SHA512_All = ComputeFullHash(fs[i].FI.FullName);
                        if (fs[c].SHA512_All == null)
                            fs[c].SHA512_All = ComputeFullHash(fs[c].FI.FullName);
                        if (fs[i].SHA512_All != fs[c].SHA512_All)
                            continue;
                        if (fs[i].SHA512_All == null)                                       // check for hash fail before declairing a duplicate.
                            continue;
                    }
                                
                    Console.WriteLine("  Match: " + fs[i].FI.FullName);
                    Console.WriteLine("   with: " + fs[c].FI.FullName);
                    fs[c].Checked = true;                                                   // do not check or match against this file again.                                 
                    numOfDupes++;                                                           // increase count of matches.

                    if (delete != true)
                        continue;
                    if (noprompt == false)
                    {
                       Console.Write("Delete the duplicate file <Y/n>?");
                       deleteConfirm = Console.ReadLine();
                       if ((deleteConfirm[0] != 'Y') && (deleteConfirm[0] != 'y'))
                          continue;
                    }                                     
                    try
                    {
                       File.Delete(fs[c].FI.FullName);
                       Console.WriteLine("Deleted: " + fs[c].FI.FullName);
                       bytesRec += fs[c].FI.Length;
                       delFiles++;
                    }
                    catch (Exception e)
                    {
                       Console.WriteLine("File delete error: " + e.Message);
                    }                                                
                }                
            }

            Console.WriteLine(" ");
            Console.WriteLine("File checked: " + fs.Count);            
            Console.WriteLine("Duplicates: " + numOfDupes);
            Console.WriteLine("Duplicates deleted: " + delFiles);
            Console.WriteLine("Bytes recovered: " + bytesRec);
            Environment.Exit(0);
        }

        private static string ComputeInitialHash(string path)
        {
            byte[] readBuf = new byte[1024];
            try
            {
                using (var stream = File.OpenRead(path))
                {
                    var length = stream.Read(readBuf, 0, readBuf.Length);
                    var hash = SHA512.Create().ComputeHash(readBuf, 0, length);
                    return BitConverter.ToString(hash);
                }
            }
            catch (Exception e)
            { 
                Console.WriteLine("Hash Error: " + e.Message);
                return (null);
            }
        }

        private static string ComputeFullHash(string path)
        {
            try
            {
                using (var stream = File.OpenRead(path))
                {
                    return BitConverter.ToString(SHA512.Create().ComputeHash(stream));
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("Hash error: " + e.Message);
                return (null);
            }
        }
    }
}

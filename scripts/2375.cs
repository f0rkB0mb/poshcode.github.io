using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.Security.Cryptography;
using System.Runtime.InteropServices;
using Microsoft.Win32;
using System.IO;

namespace Findup
{
    public class FileInfoExt
    {
        public FileInfoExt(FileInfo fi)
        {
            FI = fi;
        }        
        public byte[] SHA512_1st1K;
        public byte[] SHA512_All;
        public FileInfo FI { get; private set; }
        public bool Matched { get; set; }            
    }

    class Recurse                               // Add FileInfoExt objects of files matching filenames, file specifications (E.G. *.txt), and in directories in pathRec, to returnList
    {
        private string dirPart;
        private string filePart;

        public void Recursive(string[] pathRec, string searchPattern, Boolean recursiveFlag, List<FileInfoExt> returnList)
        {

            foreach (string d in pathRec)
            {
                Recursive(d, searchPattern, recursiveFlag, returnList);
            }
            return;
        }

        public void Recursive(string pathRec, string searchPattern, Boolean recursiveFlag, List<FileInfoExt> returnList)
        {
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
                    foreach (FileInfo addf in (Dir.GetFiles(searchPattern)))
                    {
                        returnList.Add(new FileInfoExt(addf));
                    }
                }
                catch (Exception e)
                {
                    Console.WriteLine("Add files from Directory error: " + e.Message);
                }

                if (recursiveFlag == true)
                {
                    try
                    {
                            Recursive((Directory.GetDirectories(pathRec)), searchPattern, recursiveFlag, returnList);
                    }
                    catch (Exception e)
                    {
                        Console.WriteLine("Add Directory error: " + e.Message);
                    }
                }                
            }
            else
            {
                try
                {
                    filePart = Path.GetFileName(pathRec);
                    dirPart = Path.GetDirectoryName(pathRec);
                }
                catch (Exception e)
                {
                    Console.WriteLine("Parse error on: " + pathRec);
                    Console.WriteLine(@"Make sure you don't end a directory with a \ when using quotes. The console arg parser doesn't accept that.");
                    Console.WriteLine("Exception: " + e.Message);
                    return;
                }

                if (filePart.IndexOfAny(new char[] {'?','*'}) >= 0)
                {
                    if ((dirPart == null) || (dirPart == ""))
                        dirPart = Directory.GetCurrentDirectory();
                    if (Directory.Exists(dirPart))
                    {
                        Recursive(dirPart, filePart, recursiveFlag, returnList);
                        return;
                    }
                }
                Console.WriteLine("Invalid file path, directory path, file specification, or program option specified: " + pathRec);                                                        
            }            
        }
    }


    class Findup
    {
        const int HashLen = 512/8;                                 // 64-byte hash for SHA512.

        public static void Main(string[] args)
        {            
            Console.WriteLine("Findup.exe v1.0 - use -help for usage information. Created in 2010 by James Gentile.");
            Console.WriteLine(" ");

            string[] paths = new string[0];
            System.Boolean recurse = false;
            System.Boolean delete = false;
            System.Boolean noprompt = false;
            System.Boolean b4b = false;
            List<FileInfoExt> fs = new List<FileInfoExt>();
            long bytesInDupes = 0;                              // bytes in all the duplicates
            long numOfDupes = 0;                                // number of duplicate files found.
            long bytesRec = 0;                                  // number of bytes recovered.
            long delFiles = 0;                                  // number of files deleted.
            int c = 0;
            int i = 0;
            string deleteConfirm;        
            

            for (i = 0; i < args.Length; i++)
            {
                if ((System.String.Compare(args[i], "-help", true) == 0) || (System.String.Compare(args[i], "-h", true) == 0))
                {
                    Console.WriteLine("Usage:    findup.exe <file/directory #1> <file/directory #2> ... <file/directory #N> [-recurse] [-delete] [-noprompt] [-b4b]");
                    Console.WriteLine(" ");
                    Console.WriteLine("Options:  -help     - displays this help infomration.");
                    Console.WriteLine("          -recurse  - recurses through subdirectories when directories or file specifications (e.g. *.txt) are specified.");
                    Console.WriteLine("          -delete   - deletes duplicates with confirmation prompt.");
                    Console.WriteLine("          -noprompt - when used with -delete option, deletes files without confirmation prompt.");
                    Console.WriteLine("          -b4b      - do a byte-for-byte comparison, instead of SHA-512 hashing. Slower in some cases, faster in others, and most secure.");
                    Console.WriteLine(" ");
                    Console.WriteLine("Examples: findup.exe c:\\finances -recurse");
                    Console.WriteLine("          findup.exe c:\\users\\alice\\plan.txt d:\\data -recurse -delete -noprompt");
                    Console.WriteLine("          findup.exe c:\\data .\\*.txt c:\\reports\\quarter.doc -recurse -b4b");
                    Console.WriteLine(" ");
                    return;
                }
                if (System.String.Compare(args[i], "-recurse", true) == 0)
                {
                    recurse = true;
                    continue;
                }
                if (System.String.Compare(args[i], "-delete", true) == 0)
                {
                    delete = true;
                    continue;
                }
                if (System.String.Compare(args[i], "-noprompt", true) == 0)
                {
                    noprompt = true;
                    continue;
                }
                if (System.String.Compare(args[i], "-b4b", true) == 0)
                {
                    b4b = true;
                    continue;
                }
                Array.Resize(ref paths, paths.Length + 1);                
                paths[c] = args[i];                
                c++;
            }

            if (paths.Length == 0)
            {
                Console.WriteLine("No files specified, try findup.exe -help");
                return;
            }

            Recurse recurseMe = new Recurse();
            recurseMe.Recursive(paths, "*.*", recurse, fs);

            if (fs.Count < 2)
            {
                Console.WriteLine("Findup.exe needs at least 2 files to compare. try findup.exe -help");
                return;
            }

            RNGCryptoServiceProvider rng = new RNGCryptoServiceProvider();
            rng.GetBytes(salt);                                                             // get 512-bit SHA-512 salt.              

            for (i = 0; i < fs.Count; i++)
            {
                if (fs[i].Matched == true)                                                  // If file was already matched, then skip to next.
                    continue;

                for (c = i + 1; c < fs.Count; c++)
                {
                    if (fs[c].Matched == true)                                              // skip already matched inner loop files.
                        continue;
                    if (fs[i].FI.Length != fs[c].FI.Length)                                 // If file size matches, then check hash.
                        continue;
                    if (System.String.Compare(fs[i].FI.FullName, fs[c].FI.FullName, true) == 0) // don't count the same file as a match.
                        continue;
                    if (fs[i].SHA512_1st1K == null)                                         // check/hash first 1K first.                    
                        if (Compute1KHash(fs[i]) == false)
                            continue;                    
                    if (fs[c].SHA512_1st1K == null)                    
                        if (Compute1KHash(fs[c]) == false)
                            continue;                    
                    if (CompareBytes(fs[i].SHA512_1st1K, fs[c].SHA512_1st1K) == false)      // if the 1st 1K has the same hash..
                        continue;
                    if (b4b == true)                                                        // byte for byte comparison specified?
                    {
                        if (B4b(fs[i].FI.FullName, fs[c].FI.FullName) == false)             // call the byte for byte comparison function
                            continue;
                    }
                    else if (fs[i].FI.Length > 1024)                                        // skip hashing the file again if < 1024 bytes.
                    {
                        if (fs[i].SHA512_All == null)                                       // check/hash the rest of the files.
                            if (ComputeFullHash(fs[i]) == false)
                                continue;
                        if (fs[c].SHA512_All == null)
                            if (ComputeFullHash(fs[c]) == false)
                                continue;
                        if (CompareBytes(fs[i].SHA512_All, fs[c].SHA512_All) == false)
                            continue;
                    }

                    Console.WriteLine("Match  : " + fs[i].FI.FullName);
                    Console.WriteLine("with   : " + fs[c].FI.FullName);

                    fs[c].Matched = true;                                                   // do not check or match against this file again.                                 
                    numOfDupes++;                                                           // increase count of matches.
                    bytesInDupes += fs[c].FI.Length;                                        // accumulate number of bytes in duplicates.

                    if (delete != true)                                                     // if delete is specified, try to delete the duplicate file.
                        continue;
                    if (noprompt == false)
                    {
                        Console.Write("Delete the duplicate file <Y/n>?");
                        deleteConfirm = Console.ReadLine();
                        if ((deleteConfirm[0] != 'Y') && (deleteConfirm[0] != 'y'))         // if user typed 'Y' then delete the file.
                            continue;
                    }
                    try
                    {
                        File.Delete(fs[c].FI.FullName);
                        Console.WriteLine("Deleted: " + fs[c].FI.FullName);
                        bytesRec += fs[c].FI.Length;                                        // record bytes recovered.
                        delFiles++;
                    }
                    catch (Exception e)
                    {
                        Console.WriteLine("File delete error: " + e.Message);
                    }
                }
            }

            Console.WriteLine(" ");
            Console.WriteLine("Files checked      : {0:N0}", fs.Count);
            Console.WriteLine("Duplicate files    : {0:N0}", numOfDupes);
            Console.WriteLine("Duplicate bytes    : {0:N0}", bytesInDupes);
            Console.WriteLine("Duplicates deleted : {0:N0}", delFiles);
            Console.WriteLine("Recovered bytes    : {0:N0}", bytesRec);
            return;                                                                             // Exit after displaying statistics.
        }

        private static Boolean B4b(string path1, string path2)
        {
            try
            {
                using (var stream = File.OpenRead(path1))
                {
                    using (var stream2 = File.OpenRead(path2))
                    {                        
                        while (stream.Position != stream.Length)                        
                        {
                            var length = stream.Read(largeBuf, 0, largeBuf.Length);
                            var length2 = stream2.Read(largeBuf2, 0, largeBuf2.Length);
                            if (length != length2)
                                return false;
                            if (CompareBytes(largeBuf, largeBuf2, length) == false)
                                return false;
                        }
                    }
                }
                return true;

            }
            catch (Exception e)
            {
                Console.WriteLine("Byte for Byte comparison failed: " + e.Message);
                return false;
            }

        }
        
        private static Boolean CompareBytes(byte[] byteArray1, byte[] byteArray2, int Len = HashLen)
        {
            int i = 0;
            while (i < Len)
            {
                if (byteArray1[i] != byteArray2[i])
                    return false;
                i++;
            }
            return true ;
        }

        private static readonly byte[] readBuf = new byte[1024];        
        private static readonly byte[] largeBuf = new byte[HashLen*200];
        private static readonly byte[] largeBuf2 = new byte[HashLen*200];
        private static readonly byte[] salt = new byte[HashLen];        

        private static bool Compute1KHash(FileInfoExt path)
        {
            try
            {
                using (var stream = File.OpenRead(path.FI.FullName))
                {
                    var length = stream.Read(readBuf, 0, readBuf.Length);
                    var _SHA512 = SHA512.Create();
                    _SHA512.TransformBlock(salt, 0, salt.Length, null, 0);
                    _SHA512.TransformFinalBlock(readBuf, 0, length);
                    path.SHA512_1st1K = _SHA512.Hash;                    
                    return true;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("Hash Error: " + e.Message);
                path.Matched = true;                                                            // since the file error'ed out, don't check against it again.
                return false;
            }
        }

        private static bool ComputeFullHash(FileInfoExt path)
        {
            try
            {
                var _SHA512 = SHA512.Create();
                _SHA512.TransformBlock(salt, 0, salt.Length, null, 0);
                using (var stream = File.OpenRead(path.FI.FullName))
                {                   
                    while (true)
                    {
                        var length = stream.Read(largeBuf, 0, largeBuf.Length);
                        if (stream.Position < stream.Length)                                    // if not at end of file...
                            _SHA512.TransformBlock(largeBuf, 0, length, null, 0);               // hash the buffer, and loop.
                        else
                        {
                            _SHA512.TransformFinalBlock(largeBuf, 0, length);                   // if at end of file, hash last time and end looping
                            break;
                        }
                    }
                }
                path.SHA512_All = _SHA512.Hash;                
                return true;
            }
            catch (Exception e)
            {
                Console.WriteLine("Hash error: " + e.Message);
                path.Matched = true;
                return false;
            }
        }
    }
}

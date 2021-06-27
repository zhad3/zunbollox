import std.stdio;
import std.file : read;
import std.exception : ErrnoException;
import core.stdc.stdio : SEEK_SET, SEEK_END;
import std.format : format;

import zencoding.windows949 : fromWindows949;

int main(string[] args)
{
    if (args.length <= 1)
    {
        return convertBetweenFiles("unbollox_me.txt", "clean.txt");
    }
    else
    {
        bool helpWanted = false;

        foreach (arg; args[1 .. $])
        {
            if (arg == "-h" || arg == "--help")
            {
                helpWanted = true;
                break;
            }
        }

        if (helpWanted)
        {
            writeln("zunbollox 1.0.1\n" ~
                    "Usage: zunbollox [-h] [-f <filename>]\n" ~
                    "\n" ~
                    "If no options are provided the program will\n" ~
                    "convert the file \"unbollox_me.txt\" to \"clean.txt\".\n" ~
                    "\n" ~
                    "Options:\n" ~
                    "\t-h\t\tPrint this help message.\n" ~
                    "\t-f <filename>\tConvert specific file. The file must "~
                        "be ascii/latin1 encoded.");
            return 0;
        }
    }

    string sourceFile;
    if (args.length > 2)
    {

        foreach (i, arg; args[1 .. $])
        {
            import std.algorithm : startsWith;

            if (!arg.startsWith("-"))
            {
                continue;
            }

            if (arg == "-f" && i + 2 < args.length)
            {
                sourceFile = args[i + 2];
            }

            if (sourceFile == string.init)
            {
                writeln("No filename provided for option '-f'");
                return 1;
            }

            import std.path : baseName, setExtension, extension, stripExtension;

            const ext = sourceFile.extension;
            const destFile = (sourceFile.baseName.stripExtension ~ "_clean").setExtension(ext);

            if (convertBetweenFiles(sourceFile, destFile) == 0)
            {
                writeln(sourceFile, " -> Converted to ", destFile);
            }
        }
    }

    return 0;
}

static int convertBetweenFiles(string sourceFile, string destFile)
{
    ubyte[] filecontents;
    try
    {
        filecontents = cast(ubyte[]) read(sourceFile);
    }
    catch (Throwable err)
    {
        writeln("Couldn't open file \"" ~ sourceFile ~ "\" with error: %s".format(err.msg));
        return 1;
    }

    File fout;
    try
    {
        import std.utf : toUTF8;

        fout = File(destFile, "w+");
        fout.rawWrite(fromWindows949(filecontents).toUTF8);
    }
    catch (Throwable err)
    {
        writeln("Couldn't open file \"" ~ destFile ~ "\" with error: %s".format(err.msg));
        return 1;
    }

    return 0;
}

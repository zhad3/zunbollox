# zunbollox

Tool to convert text encoded in windows code page 949 to utf-8 (but not vice-versa).

The name is taken from the old tool "UnBollox" or "RO Unbolloxiser" by StelTechCor in the year 2004.
Their tool converts filenames and directory trees whereas this tool just converts text.

## Building

Run `dub build` to build the command line program.  
Run `dub build :gui` to build the GUI program.

## Usage
`./zunbollox -h`
```
zunbollox 1.0.0
Usage: zunbollox [-h] [-f <filename>]

If no options are provided the program will
convert the file "unbollox_me.txt" to "clean.txt".

Options:
	-h		Print this help message.
	-f <filename>	Convert specific file. The file must be ascii/latin1 encoded.
```

![GUI Screenshot](gui-screenshot.png?raw=true)

## Windows

On the release page you will find pre-compiled windows binaries for both the cli and the gui.

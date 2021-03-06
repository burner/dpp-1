/**
   Command-line options
 */
module dpp.runtime.options;

@safe:

version(Windows)
    enum exeExtension = ".exe";
else
    enum exeExtension = "";


struct Options {

    enum usage = "Usage: d++ [options] [D compiler options] <filename.dpp> [D compiler args]";

    string[] dppFileNames;
    string indentation;
    bool debugOutput;
    string[] includePaths;
    bool keepPreCppFiles;
    bool keepDlangFiles;
    bool preprocessOnly;
    string dlangCompiler = "dmd";
    string[] dlangCompilerArgs;
    string[] defines;
    bool earlyExit;

    this(string[] args) {

        import clang: systemPaths;
        import std.exception: enforce;
        import std.path: stripExtension, extension, buildPath, absolutePath;
        import std.file: tempDir;
        import std.algorithm: map, filter, canFind, startsWith;
        import std.array: array;
        import std.conv: text;

        parseArgs(args);
        if(earlyExit) return;

        if(preprocessOnly)
            enforce(args.length == 2,
                    text("Wrong argument length. Expected 2, got ", args.length,
                         " for preprocessing only.\n", usage));
        else
            enforce(args.length >= 2, "Not enough arguments\n" ~ usage);

        dppFileNames = args.filter!(a => a.extension == ".dpp").array;
        enforce(dppFileNames.length != 0, "No .dpp input file specified\n" ~ usage);

        // Remove the name of this binary and the name of the .dpp input file from args
        // so that a D compiler can use the remaining entries.
        dlangCompilerArgs =
            args[1..$].filter!(a => a.extension != ".dpp").array ~
            dFileNames;

        // if no -of option is given, default to the name of the .dpp file
        if(!dlangCompilerArgs.canFind!(a => a.startsWith("-of")) && !dlangCompilerArgs.canFind("-c"))
            dlangCompilerArgs ~= "-of" ~
                args.
                filter!(a => a.extension == ".dpp" || a.extension == ".d")
                .front
                .stripExtension
                ~ exeExtension;

        includePaths = systemPaths ~ includePaths;
    }

    string[] dFileNames() @safe pure const {
        import std.algorithm: map;
        import std.array: array;
        return dppFileNames.map!toDFileName.array;
    }

    static string toDFileName(in string dppFileName) @safe pure nothrow {
        import std.path: stripExtension;
        return dppFileName.stripExtension ~ ".d";
    }

    private void parseArgs(ref string[] args) {
        import std.getopt: getopt, defaultGetoptPrinter, config;
        auto helpInfo =
            getopt(
                args,
                config.passThrough,
                "print-cursors", "Print debug information", &debugOutput,
                "include-path", "Include paths", &includePaths,
                "keep-pre-cpp-files", "Do not delete the temporary pre-preprocessed file", &keepPreCppFiles,
                "keep-d-files", "Do not delete the temporary D file to be compiled", &keepDlangFiles,
                "preprocess-only", "Only transform the .dpp file into a .d file, don't compile", &preprocessOnly,
                "compiler", "D compiler to use", &dlangCompiler,
                "define", "C Preprocessor macro", &defines,
            );

        if(helpInfo.helpWanted) {
            () @trusted {
                defaultGetoptPrinter(usage, helpInfo.options);
            }();
            earlyExit = true;
        }
    }

    this(in string[] dppFileNames,
         in string indentation = "",
         in bool debugOutput = false)
    pure nothrow
    {
        this.dppFileNames = dppFileNames.dup;
        this.indentation = indentation;
        this.debugOutput = debugOutput;
    }

    Options indent() pure nothrow const {
        auto ret = Options(dppFileNames, indentation ~ "    ", debugOutput);
        ret.includePaths = includePaths.dup;
        ret.defines = defines.dup;
        return ret;
    }

    void log(T...)(auto ref T args) @trusted const {
        version(unittest) import unit_threaded.io: writeln = writelnUt;
        else import std.stdio: writeln;

        version(unittest) enum shouldLog = true;
        else             const shouldLog = debugOutput;

        if(shouldLog)
            debug writeln(indentation, args);
    }
}

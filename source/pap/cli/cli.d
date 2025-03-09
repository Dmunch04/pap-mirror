module pap.cli.cli;

import core.stdc.stdlib : EXIT_SUCCESS, EXIT_FAILURE;
import std.stdio : writefln;
import std.getopt;

import pap.pap;
import pap.constant;

private const string USAGE = "pap [command] [options]";

/++
 + The ProgramOptions struct is used to store the options that are passed to the program through the CLI.
 +/
public struct ProgramOptions
{
    public bool verbose;
    public bool detach;
}

/++
 + The getCLI function is the entry point for the CLI. It parses the arguments and calls the appropriate subcommand.
 +/
public int getCLI(string[] args)
{
    import std.algorithm : startsWith;
    import std.array : split;

    auto subCommands = [
        "version": &versionSubcommand,
        "up": &upSubcommand,
        "down": &downSubcommand,
        "cmd": &cmdSubcommand
    ];

    if (args.length < 1)
    {
        defaultGetoptPrinter(USAGE, []);
        return EXIT_FAILURE;
    }

    if (args[0].startsWith(":"))
    {
        auto cmd = args[0].split(":");
        if (cmd.length != 2 || cmd[1] == "")
        {
            defaultGetoptPrinter(USAGE, []);
            return EXIT_FAILURE;
        }

        return cmdSubcommand(cmd[1] ~ args[1..$]);
    }
    else
    {
        auto func = (args[0] in subCommands);

        if (func is null)
        {
            defaultGetoptPrinter(USAGE, []);
            return EXIT_FAILURE;
        }

        return (*func)(args);
    }

    return EXIT_SUCCESS;
}

private int versionSubcommand(string[] args)
{
    writefln("pap v%s-%s", VERSION, BUILD);

    return EXIT_SUCCESS;
}

private int upSubcommand(string[] args)
{
    bool verbose = false;
    bool detach = false;
    auto opts = getopt(
        args,
        "verbose|v", "Verbose output mode", &verbose,
        "detach|d", "Detach the pap up loop", &detach
    );

    if (opts.helpWanted)
    {
        defaultGetoptPrinter("pap up [options]", opts.options);
    }

    ProgramOptions options;
    options.verbose = verbose;
    options.detach = detach;

    return up(options);
}

private int downSubcommand(string[] args)
{
    return EXIT_SUCCESS;
}

/++
 + The cmdSubcommand function is used to execute a command that is passed as an argument to the CLI.
 +/
public int cmdSubcommand(string[] args)
{
    runStageCommand(args[0], args[1..$]);

    return EXIT_SUCCESS;
}

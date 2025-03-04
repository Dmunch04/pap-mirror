module pap.cli.cli;

import core.stdc.stdlib : EXIT_SUCCESS, EXIT_FAILURE;
import std.stdio : writefln;
import std.getopt;

//import clid;
//import argparse;

import pap.pap;
import pap.constant;
import pap.cli.config;

const string USAGE = "pap [command] [options]";

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

public int versionSubcommand(string[] args)
{
    writefln("pap v%s-%s", VERSION, BUILD);

    return EXIT_SUCCESS;
}

public int upSubcommand(string[] args)
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

    CLIConfig config;
    config.verbose = verbose;
    config.detach = detach;

    return up(config);
}

public int downSubcommand(string[] args)
{
    return EXIT_SUCCESS;
}

public int cmdSubcommand(string[] args)
{
    writefln(args[0]);

    return EXIT_SUCCESS;
}

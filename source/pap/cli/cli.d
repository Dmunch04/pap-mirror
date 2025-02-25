module pap.cli.cli;

import clid;

import pap.cli.config;

public CLIConfig getCLIOptions(string[] args)
{
    return parseArguments!CLIConfig(args);
}

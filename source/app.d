import pap;

import argparse;
import pap.cli;

//mixin CLI!(VersionSubcommand, UpSubcommand, CmdSubcommand).main!run;


int main(string[] args)
{
    //return run(args[1..$]);
    return getCLI(args[1..$]);
}

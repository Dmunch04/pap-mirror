module pap.cli.config;

import clid;
import clid.validate;

public struct CLIConfig
{
    @Parameter("version")
    @Description("print the version and exit")
    public bool showVersion = false;

    @Parameter("verbose", 'v')
    @Description("verbose output")
    public bool verbose = false;

    @Parameter("config", 'c')
    @Description("the configuration to build")
    public string config = "";
}

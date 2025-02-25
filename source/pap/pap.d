module pap.pap;

import dyaml;

import pap.constant;
import pap.cli;
import pap.config.configurations : ConfigurationsConfig, constructConfig;

public class PapCLI
{
    private CLIConfig config;
    private ConfigurationsConfig configurations;

    this(CLIConfig config)
    {
        this.config = config;

        tryLoadConfig();
    }

    private bool tryLoadConfig()
    {
        import std.file : exists;
        import std.stdio : writefln;

        Node root;
        if (exists("./pap.yml"))
        {
            root = Loader.fromFile("./pap.yml").load();
        }
        else if (exists("./pap.yaml"))
        {
            root = Loader.fromFile("./pap.yaml").load();
        } else
        {
            writefln("Configuration file '%s' does not exist.", "pap.yml");
            return false;
        }

        configurations = constructConfig(root);
        writefln("config1 name: %s", configurations.configurations[0].name);
        writefln("config2 name: %s", configurations.configurations[1].name);

        writefln("config1 trigger-cmd: %s", configurations.configurations[0].triggers.cmd[0].name);
        writefln("config1 trigger-job: %s %s", configurations.configurations[0].triggers.job[0].name, configurations.configurations[0].triggers.job[0].when);

        writefln("config2 trigger-watch: %s", configurations.configurations[1].triggers.watch[0].file);
        writefln("config2 trigger-cmd: %s", configurations.configurations[1].triggers.cmd[0].name);

        foreach (config; configurations.configurations)
        {
            writefln("config name: %s", config.name);
            foreach (step; config.flow.steps)
            {
                writefln("step name: %s", step.name);
            }
        }

        return true;
    }
}

public int run(string[] args)
{
    auto config = getCLIOptions(args);

    if (config.showVersion)
    {
        import std.stdio : writeln;
        import std.format : format;

        writeln(format!"pap v%s-%s"(VERSION, BUILD));

        return 0;
    }

    auto cli = new PapCLI(config);
    // do something

    return 0;
}

module pap.pap;

import dyaml;

import pap.constant;
import pap.cli;
import pap.config.stages;
import pap.util.mapper;

public class PapCLI
{
    private CLIConfig config;
    private StagesConfig stages;

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

        bool validated;
        stages = map!StagesConfig(root, validated);
        if (!validated)
        {
            writefln("Config validation failed because of previous errors.");
            return false;
        }

        if (!stages.validate())
        {
            writefln("Config validation failed because of previous errors.");
            return false;
        }

        foreach (stage; stages.stages)
        {
            writefln("config name: %s", stage.name);
            foreach (step; stage.flow.steps)
            {
                writefln("step name: %s", step.name);
            }

            writefln("");
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

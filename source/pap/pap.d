module pap.pap;

import std.stdio : stderr, writefln;
import core.stdc.stdlib : EXIT_SUCCESS, EXIT_FAILURE;

import dyaml;

import pap.constant;
import pap.cli;
import pap.recipes;
import pap.util.mapper;
import pap.flow;

public class PapCLI
{
    private CLIConfig config;
    private ProjectRecipe project;
    private StageRecipe[] stages;

    package StageTriggerWatchRecipe[] watchers;
    package string[string] commandMap;

    private bool initialized;

    package this(CLIConfig config)
    {
        this.config = config;

        this.initialized = tryLoadConfig();
    }

    private bool tryLoadConfig()
    {
        import std.file : exists;

        Node root;
        if (exists("./pap.yml"))
        {
            root = Loader.fromFile("./pap.yml").load();
        }
        else if (exists("./pap.yaml"))
        {
            root = Loader.fromFile("./pap.yaml").load();
        }
        else
        {
            stderr.writeln("Configuration file 'pap.yml' does not exist.");
            return false;
        }

        bool validated;
        if (root.containsKey("project"))
        {
            this.project = map!ProjectRecipe(root["project"], validated);
            if (!validated)
            {
                stderr.writeln("Config validation failed because of previous errors.");
                return false;
            }

            if (!this.project.validate())
            {
                stderr.writeln("Config validation failed because of previous errors.");
                return false;
            }
        }

        validated = false;
        StagesRecipe stagesRecipe = map!StagesRecipe(root, validated);
        if (!validated)
        {
            stderr.writeln("Config validation failed because of previous errors.");
            return false;
        }

        if (this.project.includes.length > 0)
        {
            foreach (file; this.project.includes)
            {
                if (file.exists)
                {
                    Node fileRoot = Loader.fromFile(file).load();

                    bool includeValidated;
                    StagesRecipe includeStages = map!StagesRecipe(fileRoot, includeValidated);
                    if (!includeValidated)
                    {
                        stderr.writeln("Config validation failed because of previous errors.");
                        return false;
                    }

                    stagesRecipe.stages ~= includeStages.stages;
                }
            }
        }

        if (!stagesRecipe.validate())
        {
            stderr.writeln("Config validation failed because of previous errors.");
            return false;
        }
        this.stages = stagesRecipe.stages;

        getWatchers();
        createCommandMap();

        return true;
    }

    private void getWatchers()
    {
        foreach (StageRecipe stage; this.stages)
        {
            if (stage.triggers.watch.length > 0)
            {
                this.watchers ~= stage.triggers.watch;
            }
        }
    }

    private void createCommandMap()
    {
        foreach (StageRecipe stage; this.stages)
        {
            if (stage.triggers.cmd.length > 0)
            {
                foreach (StageTriggerCmdRecipe cmd; stage.triggers.cmd)
                {
                    if (cmd.name !in this.commandMap)
                    {
                        this.commandMap[cmd.name] = stage.name;
                    }
                    else
                    {
                        stderr.writeln("Command '%s' is already registered to stage '%s'", cmd.name, stage.name);
                    }
                }
            }
        }
    }

    public void upLoop()
    {
        import std.stdio : readln;
        import std.string : strip;
        import std.file : getcwd;

        FlowNode[] nodes = createFlow(this.stages, this.stages[0]);
        foreach (node; nodes)
        {
            writefln(node.toString);
        }

        FlowTree flow = createFlowTree(nodes, nodes[0]);
        foreach (FlowTree child1; flow.children)
        {
            writefln(child1.stageName);
            foreach (FlowTree child2; child1.children)
            {
                writefln(child2.stageName);
                foreach (FlowTree child3; child2.children)
                {
                    writefln(child3.stageName);
                }
            }
        }

        writefln("Entering pap CLI v%s-%s", VERSION, BUILD);
        writefln("At %s", getcwd());
        writefln("Type 'help' for a list of available commands.");

        string line;
        while (true)
        {
            if ((line = readln().strip) !is null)
            {
                if (cliLoopCommands(line))
                {
                    break;
                }
            }

            // do something
        }
    }

    private bool cliLoopCommands(string line)
    {
        import std.algorithm : startsWith;
        import std.array : split;
        import std.file : getcwd;

        if (line == "help" || line == "h")
        {
            writefln("Available commands:");
            writefln("  help                Shows this message");
            writefln("  info                Show information about the current configuration");
            writefln("  exit                Exit the CLI");
            writefln("  reload              Reloads the pap configuration file");
            writefln("  cmd [command]       Run a user-defined command");
            writefln("  :[command]          Run a user-defined command (Alternative)");
        }
        else if (line == "info")
        {
            writefln("Current directory: %s", getcwd());
            writefln("Watchers:");
            foreach (watcher; this.watchers)
            {
                string path;
                if (watcher.file != "")
                {
                    path = watcher.file;
                }
                else
                {
                    path = watcher.directory;
                }

                writefln("  - %s", path);
            }
        }
        else if (line == "reload")
        {
            if (tryLoadConfig())
            {
                writefln("Configuration reloaded.");
            }
        }
        else if (line.startsWith("cmd"))
        {
            auto cmd = line.split(" ");
            if (cmd.length != 2 || cmd[1] == "")
            {
                writefln("Invalid command.");
            }

            // cmdSubcommand(cmd[1] ~ args[1..$]);
        }
        else if (line.startsWith(":"))
        {
            auto cmd = line.split(":");
            if (cmd.length != 2 || cmd[1] == "")
            {
                writefln("Invalid command.");
            }

            // cmdSubcommand(cmd[1] ~ args[1..$]);
        }
        else if (line == "exit" || "e" || "down")
        {
            return true;
        }

        return false;
    }
}

public int up(CLIConfig config)
{
    auto cli = new PapCLI(config);
    if (!cli.initialized)
    {
        return EXIT_FAILURE;
    }

    // do something
    cli.upLoop();

    return EXIT_SUCCESS;
}

public int runStageCommand(string cmd, string[string] cmdMap = null)
{
    if (cmdMap == null)
    {
        auto cli = new PapCLI(CLIConfig(false, false));
        if (!cli.initialized)
        {
            return EXIT_FAILURE;
        }

        cmdMap = cli.commandMap;
    }

    if (cmd !in cmdMap)
    {
        stderr.writefln("Command '%s' could not be found", cmd);
        return EXIT_FAILURE;
    }

    // do something
    return EXIT_SUCCESS;
}

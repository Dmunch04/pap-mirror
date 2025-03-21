module pap.pap;

import std.stdio : stderr, writefln;
import core.stdc.stdlib : EXIT_SUCCESS, EXIT_FAILURE;

import dyaml;
import ymlmap;

import pap.constant;
import pap.cli;
import pap.recipes;
import pap.flow;

/++
 + The PapCLI class handles the CLI commands. It is responsible for loading the configuration file and
 + handling the user input.
 +/
public class PapCLI
{
    private ProgramOptions options;
    private ProjectRecipe project;
    private StageRecipe[] stages;

    package StageTriggerWatchRecipe[] watchers;
    package string[string] commandMap;

    private bool initialized;

    package this(ProgramOptions options)
    {
        this.options = options;

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

    /++
     + The upLoop method is the main loop of the CLI. It handles the user input and executes the commands.
     +/
    public void upLoop()
    {
        import std.algorithm : each;
        import std.stdio : writeln;

        writeln("aa");
        FlowNode[] nodes = createFlow(stages, stages[0]);
        //nodes.each!(n => writeln(n.toString()));
        foreach (n; nodes)
        {
            writeln(n.toString);
        }
        //writeln();
        //FlowTree tree = createFlowTree(nodes, nodes[1]);
        //writeln(tree.children[0].stageName);

        import std.stdio : readln;
        import std.string : strip;
        import std.file : getcwd;

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

/++
 + The up function is the entry point for the 'up' command. It initializes the CLI and starts the main loop.
 +/
public int up(ProgramOptions options)
{
    auto cli = new PapCLI(options);
    if (!cli.initialized)
    {
        return EXIT_FAILURE;
    }

    // do something
    cli.upLoop();

    return EXIT_SUCCESS;
}

/++
 + The runStageCommand function is a helper function that can be used to run a stage command from the CLI.
 +/
public int runStageCommand(string cmd, string[] args, StageRecipe[] stages = null, string[string] cmdMap = null)
{
    if (stages is null || cmdMap is null)
    {
        auto cli = new PapCLI(ProgramOptions(false, false));
        if (!cli.initialized)
        {
            return EXIT_FAILURE;
        }

        stages = cli.stages;
        cmdMap = cli.commandMap;
    }

    if (cmd !in cmdMap)
    {
        stderr.writefln("Command '%s' could not be found", cmd);
        return EXIT_FAILURE;
    }

    StageRecipe entryStage;
    foreach (stage; stages)
    {
        if (stage.name == cmdMap[cmd])
        {
            entryStage = stage;
            break;
        }
    }

    // do something
    FlowNode[] nodes = createFlow(stages, entryStage);
    FlowTree flow = createFlowTree(nodes, nodes[0]);

    writefln(flow.stageName);

    return EXIT_SUCCESS;
}

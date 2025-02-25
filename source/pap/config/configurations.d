module pap.config.configurations;

import dyaml;

public ConfigurationsConfig constructConfig(Node root)
{
    ConfigurationsConfig config;
    config.configurations = [];

    import std.stdio : writeln;
    foreach (Node node; root["configurations"])
    {
        ConfigurationConfig configuration;
        configuration.name = node["name"].as!string;

        ConfigurationTriggerConfig triggers;
        triggers.cmd = [];
        triggers.watch = [];
        triggers.job = [];
        if (node.containsKey("trigger"))
        {
            Node triggerNode = node["trigger"];

            if (triggerNode.containsKey("cmd"))
            {
                foreach (Node trigger; triggerNode["cmd"])
                {
                    ConfigurationTriggerCmdConfig cmd;
                    cmd.name = trigger["name"].as!string;
                    triggers.cmd ~= cmd;
                }
            }

            if (triggerNode.containsKey("watch"))
            {
                foreach (Node trigger; triggerNode["watch"])
                {
                    ConfigurationTriggerWatchConfig watch;

                    if (!trigger.containsKey("file") && !trigger.containsKey("directory"))
                    {
                        writeln("Error: watch trigger must have either 'file' or 'directory' key.");
                        return config; // ??
                    }

                    if (trigger.containsKey("file"))
                    {
                        watch.file = trigger["file"].as!string;
                    }
                    if (trigger.containsKey("directory"))
                    {
                        watch.directory = trigger["directory"].as!string;
                    }

                    triggers.watch ~= watch;
                }
            }

            if (triggerNode.containsKey("job"))
            {
                foreach (Node trigger; triggerNode["job"])
                {
                    ConfigurationTriggerJobConfig job;
                    job.name = trigger["name"].as!string;
                    job.when = trigger["when"].as!string;
                    triggers.job ~= job;
                }
            }

            configuration.triggers = triggers;
        }

        ConfigurationFlowConfig flow;
        flow.steps = [];
        if (node.containsKey("flow"))
        {
            Node flowNode = node["flow"];

            if (!flowNode.containsKey("steps"))
            {
                writeln("Error: flow must have 'steps' key.");
                return config; // ??
            }

            foreach (Node step; flowNode["steps"])
            {
                ConfigurationFlowStepConfig flowStep;
                flowStep.name = step["name"].as!string;

                if (step.containsKey("run"))
                {
                    flowStep.run = step["run"].as!string;
                }

                if (step.containsKey("uses"))
                {
                    flowStep.uses = step["uses"].as!string;
                }

                if (step.containsKey("with"))
                {
                    string[string] value;
                    foreach (pair; step["with"].mapping)
                    {
                        value[pair.key.as!string] = pair.value.as!string;
                    }

                    flowStep.withs = value;
                }

                flow.steps ~= flowStep;
            }

            configuration.flow = flow;
        }

        config.configurations ~= configuration;
    }

    return config;
}

public struct ConfigurationsConfig
{
    ConfigurationConfig[] configurations;
}

public struct ConfigurationConfig
{
    string name;
    ConfigurationTriggerConfig triggers;
    ConfigurationFlowConfig flow;
}

public struct ConfigurationTriggerConfig
{
    ConfigurationTriggerCmdConfig[] cmd;
    ConfigurationTriggerWatchConfig[] watch;
    ConfigurationTriggerJobConfig[] job;
}

public struct ConfigurationTriggerCmdConfig
{
    string name;
}

public struct ConfigurationTriggerWatchConfig
{
    string file;
    string directory;
}

public struct ConfigurationTriggerJobConfig
{
    string name;
    string when;
}

public struct ConfigurationFlowConfig
{
    ConfigurationFlowStepConfig[] steps;
}

public struct ConfigurationFlowStepConfig
{
    string name;
    string run;

    string uses;
    string[string] withs;
}

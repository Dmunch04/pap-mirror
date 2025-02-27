module pap.config.stages;

import pap.util.mapper;

public struct StagesConfig
{
    /// The stages configuration. (Required)
    @Field("stages")
    @Required
    StageConfig[] stages;
}

public struct StageConfig
{
    /// The name of the stage. (Required)
    @Field("name")
    @Required
    string name;

    /// The trigger configuration for the stage. (Optional)
    @Field("triggers")
    StageTriggerConfig triggers;

    /// The flow configuration for the stage. (Optional)
    @Field("flow")
    StageFlowConfig flow;
}

public struct StageTriggerConfig
{
    /// The command invocable triggers for the stage. (Optional)
    @Field("cmd")
    StageTriggerCmdConfig[] cmd;

    /// The file/directory watch triggers for the stage. (Optional)
    @Field("watch")
    StageTriggerWatchConfig[] watch;

    /// The stage triggers for the stage. (Optional)
    @Field("stage")
    StageTriggerStageConfig[] stage;
}

public struct StageTriggerCmdConfig
{
    /// The name of the command trigger. (Required)
    @Field("name")
    @Required
    string name;
}

public struct StageTriggerWatchConfig
{
    /// The file to watch for changes. (Optional)
    @Field("file")
    string file;

    /// The directory to watch for changes. (Optional)
    @Field("directory")
    string directory;
}

public struct StageTriggerStageConfig
{
    /// The name of the stage trigger. (Required)
    @Field("name")
    @Required
    string name;

    /// The condition to trigger the stage. (Required)
    @Field("when")
    @Required
    string when;
}

public struct StageFlowConfig
{
    /// The steps of the flow. (Required)
    @Field("steps")
    @Required
    StageFlowStepConfig[] steps;
}

public struct StageFlowStepConfig
{
    /// The name of the step. (Required)
    @Field("name")
    @Required
    string name;

    /// The command to run for the step. (Optional)
    @Field("run")
    string run;

    /// The require configuration for the step. (Optional)
    @Field("require")
    StageFlowStepRequireConfig require;

    /// The outside-defined action of the step. (Optional)
    @Field("uses")
    string uses;

    /// The configuration for the step. (Optional)
    @Field("with")
    string[string] withs;
}

public struct StageFlowStepRequireConfig
{
    /// The condition to require the step. (Optional)
    @Field("condition")
    string condition;

    /// The parent stage to require the step. (Optional)
    @Field("parent_stage")
    string parentStage;

    /// The parent step to require the step. (Optional)
    @Field("flags")
    string[] flags;
}

public bool validate(StagesConfig config)
{
    // test for certain things such as the watch trigger : can only have ONE of either 'file' or 'directory', not both
    // more?

    return true;
}

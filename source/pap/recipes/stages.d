module pap.recipes.stages;

import ymlmap;

// TODO: it would be cool if we could eliminate the `id` field from `Stage` objects.
// So instead of this:
// ```
// stages:
//   - id: some-stage
//     name: Some Stage
//     ...
// ```
// we could have this:
// ```
// stages:
//   some-stage:
//     name: Some Stage
// ```
// 
// TODO: multiple 'when's for StageTrigger so you don't need to add multiple times just for multiple conditions

public struct StagesRecipe
{
    /// The stages recipe. (Required)
    @Field("stages")
    @Required
    StageRecipe[] stages;
}

public struct StageRecipe
{
    /// The unique identifier of the stage. (Required)
    @Field("id")
    @Required
    string id;

    /// The name of the stage. (Optional - defaults to stage id)
    @Field("name")
    string name;

    /// The trigger recipe for the stage. (Optional)
    @Field("trigger")
    StageTriggerRecipe triggers;

    /// The container recipe for the stage. (Optional)
    @Field("container")
    StageContainerRecipe container;

    /// The flow recipe for the stage. (Optional)
    @Field("flow")
    StageFlowRecipe flow;
}

public struct StageTriggerRecipe
{
    /// The command invocable triggers for the stage. (Optional)
    @Field("cmd")
    StageTriggerCmdRecipe[] cmd;

    /// The file/directory watch triggers for the stage. (Optional)
    @Field("watch")
    StageTriggerWatchRecipe[] watch;

    /// The stage triggers for the stage. (Optional)
    @Field("stage")
    StageTriggerStageRecipe[] stage;

    // TODO: Git Trigger?
    // more triggers?
}

public struct StageTriggerCmdRecipe
{
    /// The name of the command trigger. (Required)
    @Field("name")
    @Required
    string name;
}

public struct StageTriggerWatchRecipe
{
    /// The file to watch for changes. (Optional)
    @Field("file")
    string file;

    /// The directory to watch for changes. (Optional)
    @Field("directory")
    string directory;
}

public struct StageTriggerStageRecipe
{
    /// The id of the triggering stage. (Required)
    @Field("id")
    @Required
    string id;

    /// The condition to trigger the stage. (Required)
    @Field("when")
    @Required
    string when;
}


public struct StageContainerRecipe
{
    /// The name of the container orchestration tool to be used. Can be 'docker' or 'podman'
    @Field("engine")
    @Required
    string engine;

    /// The image of the container. (Required)
    @Field("image")
    @Required
    string image;

    /// The environment variables for the container. (Optional)
    @Field("environment")
    string[string] environment;

    /// The hostname for the container. (Optional)
    @Field("hostname")
    string hostname;

    /// The network for the container. (Optional)
    @Field("network")
    string network;
}

public struct StageFlowRecipe
{
    /// The steps of the flow. (Required)
    @Field("steps")
    @Required
    StageFlowStepRecipe[] steps;
}

public struct StageFlowStepRecipe
{
    /// The name of the step. (Required)
    @Field("name")
    @Required
    string name;

    /// The command to run for the step. (Optional)
    @Field("run")
    string run;

    /// The require recipe for the step. (Optional)
    @Field("require")
    StageFlowStepRequireRecipe require;

    /// The outside-defined action of the step. (Optional)
    @Field("uses")
    string uses;

    /// The map of inputs for the `uses` action. (Optional)
    @Field("with")
    string[string] withs;
}

public struct StageFlowStepRequireRecipe
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

/++
 + Validate the stages recipe.
 + Returns `true` if no errors found, otherwise `false`.
 +/
public bool validate(StagesRecipe recipe)
{
    import std.stdio : stderr;
    import std.algorithm : canFind;

    const STAGE_TRIGGER_WHEN = [
        "complete", "failed", "started",
        "canceled", "skipped"
    ];

    const STAGE_CONTAINER_ENGINE = [
        "docker", "podman"
    ];

    const STEP_REQUIRE_CONDITION = [
        "and", "or"
    ];

    bool failed;
    string[] stageIds;

    if (recipe.stages.length > 0)
    {
        foreach (stage; recipe.stages)
        {
            // TODO: step names?
            if (stageIds.canFind(stage.id))
            {
                stderr.writefln("Cannot have stages with duplicate id '%s'", stage.id);
                failed = true;
            }

            stageIds ~= stage.id;

            // Watch Trigger Validation
            if (stage.triggers.watch.length > 0)
            {
                foreach (watch; stage.triggers.watch)
                {
                    if (watch.file != "" && watch.directory != "")
                    {
                        stderr.writefln("Watch Trigger for '%s' must only have a file or a directory, not both!", stage.id);
                        failed = true;
                    }
                    else if (watch.file == "" && watch.directory == "")
                    {
                        stderr.writefln("Watch Trigger for '%s' must either have a file or a directory!", stage.id);
                        failed = true;
                    }
                }
            }

            // Stage Trigger Validation
            if (stage.triggers.stage.length > 0)
            {
                foreach (stageTrigger; stage.triggers.stage)
                {
                    if (stageTrigger.id == "")
                    {
                        stderr.writefln("Stage Trigger for '%s' must have an id field!", stage.id);
                        failed = true;
                    }
                    else if (!STAGE_TRIGGER_WHEN.canFind(stageTrigger.when))
                    {
                        stderr.writefln("Stage Trigger for '%s' must have a valid when condition!", stage.id);
                        failed = true;
                    }
                }
            }

            // Step Require Validation
            if (stage.flow.steps.length > 0)
            {
                foreach (step; stage.flow.steps)
                {
                    if (step.require.condition != "" && !STEP_REQUIRE_CONDITION.canFind(step.require.condition))
                    {
                        stderr.writefln("Step Require for '%s' must have a valid condition!", step.name);
                        failed = true;
                    }
                }
            }

            // Container Validation
            if (stage.container.engine != "" && !STAGE_CONTAINER_ENGINE.canFind(stage.container.engine))
            {
                stderr.writefln("Container Engine for '%s' must be either 'docker' or 'podman'", stage.id);
                failed = true;
            }

            // Post-Processing
            // If stage name not set, default it to the stage id
            if (stage.name.length == 0)
            {
                stage.name = stage.id;
            }
        }
    }

    return !failed;
}

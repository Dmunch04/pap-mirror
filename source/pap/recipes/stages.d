module pap.recipes.stages;

import pap.util.mapper;

public struct StagesRecipe
{
    /// The stages Recipeuration. (Required)
    @Field("stages")
    @Required
    StageRecipe[] stages;
}

public struct StageRecipe
{
    /// The name of the stage. (Required)
    @Field("name")
    @Required
    string name;

    /// The trigger Recipeuration for the stage. (Optional)
    @Field("trigger")
    StageTriggerRecipe triggers;

    /// The flow Recipeuration for the stage. (Optional)
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
    /// The name of the stage trigger. (Required)
    @Field("name")
    @Required
    string name;

    /// The condition to trigger the stage. (Required)
    @Field("when")
    @Required
    string when;
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

    /// The require Recipeuration for the step. (Optional)
    @Field("require")
    StageFlowStepRequireRecipe require;

    /// The outside-defined action of the step. (Optional)
    @Field("uses")
    string uses;

    /// The Recipeuration for the step. (Optional)
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

    const STEP_REQUIRE_CONDITION = [
        "and", "or"
    ];

    string[] stageNames;

    if (recipe.stages.length > 0)
    {
        foreach (stage; recipe.stages)
        {
            // TODO: step names?
            if (stageNames.canFind(stage.name))
            {
                stderr.writefln("Cannot have stages with duplicate name '%s'", stage.name);
                return false;
            }

            stageNames ~= stage.name;

            // Watch Trigger Validation
            if (stage.triggers.watch.length > 0)
            {
                foreach (watch; stage.triggers.watch)
                {
                    if (watch.file != "" && watch.directory != "")
                    {
                        stderr.writefln("Watch Trigger for '%s' must only have a file or a directory, not both!", stage.name);
                        return false;
                    }
                    else if (watch.file == "" && watch.directory == "")
                    {
                        stderr.writefln("Watch Trigger for '%s' must either have a file or a directory!", stage.name);
                        return false;
                    }
                }
            }

            // Stage Trigger Validation
            if (stage.triggers.stage.length > 0)
            {
                foreach (stageTrigger; stage.triggers.stage)
                {
                    if (stageTrigger.name == "")
                    {
                        stderr.writefln("Stage Trigger for '%s' must have a name!", stage.name);
                        return false;
                    }
                    else if (!STAGE_TRIGGER_WHEN.canFind(stageTrigger.when))
                    {
                        stderr.writefln("Stage Trigger for '%s' must have a valid when condition!", stage.name);
                        return false;
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
                        return false;
                    }
                }
            }
        }
    }

    return true;
}

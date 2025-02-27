module pap.flow;

import pap.recipes;

public enum FlowNodeCondition
{
    EMPTY,
    ROOT,
    COMPLETE,
    FAILED,
    STARTED,
    CANCELED,
    SKIPPED
}

package FlowNodeCondition fromString(string condition)
{
    switch (condition)
    {
        case "complete": return FlowNodeCondition.COMPLETE;
        case "failed": return FlowNodeCondition.FAILED;
        case "started": return FlowNodeCondition.STARTED;
        case "canceled": return FlowNodeCondition.CANCELED;
        case "skipped": return FlowNodeCondition.SKIPPED;
        default: return FlowNodeCondition.EMPTY;
    }
}

public struct FlowNode
{
    public string stageName;
    public FlowNode *parent;
    public FlowNodeCondition condition;
}

// Work in progress
public FlowNode[] createFlow(StagesRecipe stages, StageRecipe root, FlowNode rootNode = FlowNode("", null, FlowNodeCondition.EMPTY))
{
    FlowNode[] flow;

    if (rootNode.condition == FlowNodeCondition.EMPTY)
    {
        rootNode = FlowNode(root.name, null, FlowNodeCondition.ROOT);
        flow ~= rootNode;
    }

    foreach (stage; stages.stages)
    {
        if (stage.triggers.stage.length > 0)
        {
            foreach (trigger; stage.triggers.stage)
            {
                if (trigger.name == root.name)
                {
                    FlowNode node = FlowNode(stage.name, &rootNode, fromString(trigger.when));
                    flow ~= node;

                    FlowNode[] children = createFlow(stages, stage, node);
                    flow ~= children;
                }
            }
        }
    }

    return flow;
}

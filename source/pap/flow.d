module pap.flow;

import pap.recipes;

public enum FlowNodeCondition
{
    ROOT,
    COMPLETE,
    FAILED,
    STARTED,
    CANCELED,
    SKIPPED
}

package FlowNodeCondition conditionFromString(string condition)
{
    switch (condition)
    {
        case "complete": return FlowNodeCondition.COMPLETE;
        case "failed": return FlowNodeCondition.FAILED;
        case "started": return FlowNodeCondition.STARTED;
        case "canceled": return FlowNodeCondition.CANCELED;
        case "skipped": return FlowNodeCondition.SKIPPED;
        default: return FlowNodeCondition.ROOT;
    }
}

public class FlowNode
{
    public string stageName;
    public FlowNode parent;
    public FlowNodeCondition condition;

    package this(string stageName, FlowNode parent, FlowNodeCondition condition)
    {
        this.stageName = stageName;
        this.parent = parent;
        this.condition = condition;
    }
}

public FlowNode[] createFlow(StageRecipe[] stages, StageRecipe root, FlowNode rootNode = null)
{
    import std.algorithm : cmp;
    import std.stdio : writeln, writefln;

    FlowNode[] flow;

    if (rootNode is null)
    {
        rootNode = new FlowNode(root.name, null, FlowNodeCondition.ROOT);
        flow ~= rootNode;
    }

    foreach (StageRecipe stage; stages)
    {
        if (stage.triggers.stage.length > 0)
        {
            foreach (trigger; stage.triggers.stage)
            {
                if (trigger.name == root.name)
                {
                    FlowNode node = new FlowNode(stage.name, rootNode, conditionFromString(trigger.when));
                    flow ~= node;

                    FlowNode[] children = createFlow(stages, stage, node);
                    flow ~= children;
                }
            }
        }
    }

    return flow;
}

public FlowNode[] getDirectChildren(FlowNode[] nodes, FlowNode parent)
{
    FlowNode[] children;

    foreach (FlowNode node; nodes)
    {
        if (node.parent == parent)
        {
            children ~= node;
        }
    }

    return children;
}

public struct FlowTree
{
    public string stageName;
    public FlowNodeCondition condition;
    public FlowTree[] children;
}

public FlowTree createFlowTree(FlowNode[] nodes, FlowNode parent)
{
    FlowTree[] children;
    foreach (FlowNode node; nodes.getDirectChildren(parent))
    {
        children ~= createFlowTree(nodes, node);
    }

    FlowTree tree = FlowTree(parent.stageName, parent.condition, children);
    return tree;
}

module pap.flow;

import pap.recipes;

/++
 + The conditions for which the stage should be triggered
 +/
public enum FlowNodeCondition
{
    /// Used to indicate the root/top-level node
    ROOT,
    /// The parent stage was completed successfully
    COMPLETE,
    /// The parent stage failed somewhere
    FAILED,
    /// The parent stage was started
    STARTED,
    /// The parent stage was canceled, either by user or pap
    CANCELED,
    /// The parent stage was skipped due to not being triggered or ?
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

/++
 + This class represents a node in the generated flow.
 + It holds basic information such as the name of the stage it represents,
 + as well as the condition the parent stage needs to meet in order for this node to trigger.
 +
 + Note: Multiple nodes can represent the same stage, depending on the trigger
 +/
public class FlowNode
{
    /// The name of the defined stage this node represents
    public string stageName;
    /// The parent node of this node. This is the node the `condition` will be checked on
    public FlowNode parent;
    /// The condition for this node to be triggered. The condition is checked on the `parent` node
    public FlowNodeCondition condition;

    package this(string stageName, FlowNode parent, FlowNodeCondition condition)
    {
        this.stageName = stageName;
        this.parent = parent;
        this.condition = condition;
    }
}

/++
 + Creates a linear flow.
 + It takes in all the stage recipes and the root stage recipe to base the flow on.
 +/
public FlowNode[] createFlow(StageRecipe[] stages, StageRecipe root, FlowNode rootNode = null)
{
    FlowNode[] flow;

    if (rootNode is null)
    {
        rootNode = new FlowNode(root.name, null, FlowNodeCondition.ROOT);
        flow ~= rootNode;
    }

    foreach (StageRecipe stage; stages)
    {
        if (stage.name == root.name) continue;

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

/++
 + Finds all the direct children of the node.
 + It takes in all of the nodes to be checked, as well as the parent node to find the children from.
 + It then iterates all the nodes and checks which nodes has a direct link to the parent node.
 +/
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

/++
 + Struct representing a node of flow tree.
 + Has the name of the stage it represents, as well as the condition for it to be triggered.
 + It holds all it's direct children
 +/
public struct FlowTree
{
    /// The name of the defined stage this node represents
    public string stageName;
    /// The condition for this node to be triggered. The condition is checked on the parent node
    public FlowNodeCondition condition;
    /// The node's direct children. This means the children that has a direct link to this node, and which their conditions will be checked on
    public FlowTree[] children;
}

/++
 + Creates a flow tree from a previously generated linear flow array.
 + It takes in the flow array, as well as the parent node which should be the root node
 +/
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

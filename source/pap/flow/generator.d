module pap.flow.generator;

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

    override string toString() const
    {
        import std.conv : to;

        string parentName;
        if (parent !is null)
        {
            parentName = parent.stageName;
        }
        else
        {
            parentName = "ROOT";
        }

        return parentName ~ " -> " ~ stageName ~ " IF " ~ condition.to!string;
    }
}

/++
 + Creates a linear flow.
 + It takes in all the stage recipes and the root stage recipe to base the flow on.
 +
 + Not really linear anymore now that it supports recursion.
 + And on that note, how would that even work? Take this example
 + 2 stages are defined; a main stage for building the app, and a recovery stage if the main stage fails.
 + Stage 1 is being triggered by command (:build) or Stage 2 if 'complete'.
 + Stage 2 is being triggered by Stage 1 if 'failed'.
 + ENTRY -> Stage 1 triggered -> Building... -> Error Occurred -> Stage 2 triggered -> ?
 + How does stage 1 knows it should be triggered since that's at least 1 step behind in the flow
 + ([ROOT -> Stage 1, Stage 1 -> Stage 2, Stage 2 -> Stage 1])
 +                           ^^^^                ^^^^
 +   The step that should be triggered     The step we're at
 +/
public FlowNode[] createFlow(StageRecipe[] stages, StageRecipe root, FlowNode rootNode = null, FlowNode[] flow = null)
{
    // TODO: I'm not really sure if this is working as intended after allowing for recursive nodes (node 1 can be triggered by node 2 and v.v.)
    // So far it seems to be working alright? I'm pretty sure 'pap.yml.old' is producing the same output as before (should probably test to be sure).
    // The new 'pap.yml' produces:
    // ROOT -> Stage 1 IF ROOT (entrypoint)
    // Stage 1 -> Stage 2 IF FAILED
    // Stage 2 -> Stage 1 IF COMPLETE

    if (flow is null)
    {
        flow = [];
    }

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
                    if (flow.hasNode(node)) return flow;
                    flow ~= node;

                    FlowNode[] children = createFlow(stages, stage, node, flow);
                    foreach (FlowNode child; children)
                    {
                        if (!flow.hasNode(child))
                        {
                            flow ~= child;
                        }
                    }
                }
            }
        }
    }

    return flow;
}

private bool hasNode(FlowNode[] nodes, FlowNode node)
{
    foreach (FlowNode child; nodes)
    {
        if (child.parent !is null && node.parent !is null)
        {
            if (child.parent.stageName == node.parent.stageName
                && child.stageName == node.stageName
                && child.condition == node.condition)
            {
                return true;
            }
        }
        else if (child.parent is null || node.parent is null)
        {
            if (child.stageName == node.stageName && child.condition == node.condition)
            {
                return true;
            }
        }
    }

    return false;
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

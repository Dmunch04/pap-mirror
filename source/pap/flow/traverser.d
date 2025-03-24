module pap.flow.traverser;

import pap.recipes : StageRecipe;
import pap.flow.generator;

public enum StageState
{
    PENDING,
    RUNNING,
    FAILED,
    COMPLETED,
    CANCELED
}

public synchronized class TraverselState
{
    private StageState[string] states;

    StageState getState(string stageId)
    {
        if (stageId !in this.states)
        {
            this.states[stageId] = StageState.PENDING;
        }

        return this.states[stageId];
    }

    void setState(string stageId, StageState state)
    {
        this.states[stageId] = state;
    }
}

public struct StageTask
{
    public string stage;
    FlowNodeCondition condition;
}

public struct StageQueueResult
{
}

public class FlowTraverser
{
    import std.container : DList;

    private StageRecipe entryStage;
    private StageRecipe[] stages;

    private FlowNode[] nodes;
    private FlowTree nodeTree;

    private DList!StageTask[] queues;
    private auto state = new shared(TraverselState);

    public this(StageRecipe entryStage, StageRecipe[] stages)
    {
        this.entryStage = entryStage;
        this.stages = stages;

        this.nodes = createFlow(stages, entryStage);
        this.nodeTree = createFlowTree(nodes, nodes[0]);

        DList!StageTask cur;
        createTaskQueues(nodeTree, queues, cur);
    }

    public void traverse()
    {
        import std.parallelism : parallel;
        import std.algorithm : each;
        import pap.flow.executor : executeStageQueue;
        
        queues.parallel.each!(queue => executeStageQueue(queue, state));
        
        // only execute the next stage if the state of the next stage is PENDING or FAILED?
    }

    //package static bool executeStageQueue(DList!StageTask task)
    //{
    //    return true;
    //}

    private void createTaskQueues(FlowTree node, ref DList!StageTask[] queues, ref DList!StageTask currentQueue)
    {
        currentQueue.insertBack(StageTask(node.stageId, node.condition));

        if (node.children.length == 0)
        {
            queues ~= currentQueue.dup;
        }
        else
        {
            foreach (child; node.children)
            {
                createTaskQueues(child, queues, currentQueue.dup);
            }
        }

        currentQueue.removeBack();
    }
}

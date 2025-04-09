module pap.flow.traverser;

import pap.recipes : StageRecipe;
import pap.flow.generator;

public enum StageState
{
    PENDING,
    COMPLETE,
    FAILED,
    STARTED,
    CANCELED,
    SKIPPED
}

public bool compareStateToCondition(StageState state, FlowNodeCondition cond)
{
    switch (state)
    {
        case StageState.STARTED:
            return cond == FlowNodeCondition.STARTED;
        case StageState.COMPLETE:
            return cond == FlowNodeCondition.COMPLETE;
        case StageState.FAILED:
            return cond == FlowNodeCondition.FAILED;
        case StageState.CANCELED:
            return cond == FlowNodeCondition.CANCELED;
        case StageState.SKIPPED:
            return cond == FlowNodeCondition.SKIPPED;
        default:
            return false;
    }
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
        debug debugQueues();
    }

    public void traverse()
    {
        import std.parallelism : parallel;
        import std.algorithm : each, minElement, remove, countUntil;
        import pap.flow.executor : executeStageQueue, test;

        DList!StageTask[] qs = this.queues.dup;
        DList!StageTask firstQ = qs.minElement!"a[].walkLength";
        qs = qs.remove(qs.countUntil!(q => q == firstQ));

        //executeStageQueue(queue, state);
        
        //queues.parallel.each!(queue => executeStageQueue(queue, state));
        queues.parallel.each!(queue => test(queue, state, stages));

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

    private void debugQueues(DList!StageTask[] queues = null)
    {
        if (queues is null)
        {
            queues = this.queues;
        }
    
        import std.stdio : writeln, write;
        import std.range;

        assert(queues.length > 0);

        writeln("stageQueues = [");
        size_t i;
        foreach (queue; queues)
        {
            size_t j;
            size_t l = queue[].walkLength;

            write("\t[");
            write(l, "; ");
            foreach (elem; queue[])
            {
                write(elem.stage);
                if (j++ < l - 1)
                {
                    write(", ");
                }
            }
            write("]");

            if ((i++) + 1 < queues.length)
            {
                writeln(",");
            }
            else
            {
                writeln();
            }
        }
        writeln("];");
    }
}

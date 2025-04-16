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
    // If the condition is for the previous stage to have started, but it's state changes before the check is made,
    // we just to need to check if the stage has been started (previously or now).
    // TLDR: it doesn't need to have the 'STARTED' state in this case.
    // TODO: More? (Other than 'PENDING'. Not sure if 'FAILED' should also be added?)
    if (cond == FlowNodeCondition.STARTED && state != StageState.PENDING)
    {
        return true;
    }

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

    public StageState getState(string stageId)
    {
        if (stageId !in this.states)
        {
            this.states[stageId] = StageState.PENDING;
        }

        return this.states[stageId];
    }

    public void setState(string stageId, StageState state)
    {
        this.states[stageId] = state;
    }

    debug public bool testStates(int i)
    {
        import std.stdio : writeln;
        import std.conv : to;

        if (this.states.length != i) return false;

        writeln(this.states.to!string);
        return true;
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
        import std.algorithm : each, sort;
        import pap.flow.executor : executeStageQueue;
        import std.array : array;

        DList!StageTask[] sorted = this.queues.dup.sort!("a[].walkLength > b[].walkLength").array;

        //queues.parallel.each!(queue => executeStageQueue(queue, state, stages));
        sorted.parallel.each!(queue => executeStageQueue(queue, state, stages));
        
        //import std.algorithm : minElement, remove, countUntil;
        //DList!StageTask[] qs = this.queues.dup;
        //DList!StageTask firstQ = qs.minElement!"a[].walkLength";
        //qs = qs.remove(qs.countUntil!(q => q == firstQ));
        
        //test(firstQ, state, stages);
        //DList!StageTask[] fq = [firstQ];
        //fq.parallel.each!(queue => test(queue, state, stages));
        //qs.parallel.each!(queue => test(queue, state, stages));

        debug
        {
            bool success = false;
            do
            {
                success = state.testStates(13);
            }
            while (!success);
        }
    }

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

    debug private void debugQueues(DList!StageTask[] queues = null)
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

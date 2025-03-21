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

    StageState getState(string stageName)
    {
        if (stageName !in this.states)
        {
            this.states[stageName] = StageState.PENDING;
        }

        return this.states[stageName];
    }

    void setState(string stageName, StageState state)
    {
        this.states[stageName] = state;
    }
}

public class FlowTraverser
{
    private StageRecipe entryStage;
    private StageRecipe[] stages;

    private FlowNode[] nodes;
    private FlowTree nodeTree;

    private int treeDepth;

    public this(StageRecipe entryStage, StageRecipe[] stages)
    {
        this.entryStage = entryStage;
        this.stages = stages;

        this.nodes = createFlow(stages, entryStage);
        this.nodeTree = createFlowTree(nodes, nodes[0]);
    }

    // get in level order based on the parent/root stage.
    // how would we go about recusive stages? stage 1 <-> stage 2. stage 1 is root, stage 2 is run but tree/flow ends there (can't go backwards because it doesn't know it).
    // perhaps we should revert back to not allowing recursive flows (stage triggers). we could instead implement the `retry` section idea.
    // question: is it bad to only support a linear flow? i could see the upside to having the ability to "travel backwards", but is it needed? what does other similar programs do?
    // note: each stage's flow-steps can also have requirements, meaning that the method/function responsible for executing the stage/steps needs full context.
    // note: a stage can only be triggered once while the flow is running.
    // if a stage depends on 2 stages and both parent stages meets the trigger condition,
    // the stage will only be triggered by the parent stage to first meet their condition.
    private FlowTree[] getNextStages()
    {
        // level order traversel queue
        return [];
    }

    public void traverse()
    {
        import std.parallelism : parallel;

        auto state = new shared(TraverselState);

        // execute stages in parrallel or concurrently
    }
    
    public int[][] levelOrder(FlowTree root)
    {
        int[][] levels;
        dfs(root, 0, levels);
        return levels;
    }
    
    public void dfs(FlowTree cur, int lvl, ref int[][] levels)
    {
    }
}

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
    
    private FlowTree[] getNextStages()
    {
        // level order traversel queue
    }
    
    public void traverse()
    {
        auto state = new shared(TraverselState);
        
        // execute stages in parrallel or concurrently
    }
}

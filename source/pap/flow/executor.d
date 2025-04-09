module pap.flow.executor;

import std.container : DList;

import pap.recipes.stages : StageRecipe, getStageById;
import pap.flow.generator : FlowNodeCondition;
import pap.flow.traverser : StageState, TraverselState, StageTask, StageQueueResult, compareStateToCondition;

public bool test(DList!StageTask queue, ref shared(TraverselState) state, StageRecipe[] stages)
{
    import std.stdio : writeln;

    StageTask previous;
    StageState currentState;
    //while (true)
    //{
    //    if (previous.stage.length <= 0)
    //    {
    //        previous = queue.front;
    //    }
    //}
    
    foreach (StageTask stageTask; queue[])
    {
        currentState = state.getState(stageTask.stage);
        if (currentState == StageState.PENDING)
        {
            state.setState(stageTask.stage, StageState.STARTED);
        
            int retries;
            while (currentState != StageState.COMPLETE)
            {
                if (retries > 3)
                {
                    state.setState(stageTask.stage, StageState.FAILED);
                    return false;
                }
                
                //writeln(previous.stage.length <= 0);
                //writeln(stageTask.condition == FlowNodeCondition.ROOT);
                //writeln(compareStateToCondition(state.getState(previous.stage), stageTask.condition));
                if (previous.stage.length <= 0 || stageTask.condition == FlowNodeCondition.ROOT || compareStateToCondition(state.getState(previous.stage), stageTask.condition))
                {
                    state.setState(stageTask.stage, StageState.STARTED);
                    
                    StageRecipe stage = stages.getStageById(stageTask.stage);
                    writeln("Started stage: " ~ stage.name);
                    state.setState(stageTask.stage, StageState.COMPLETE);
                    currentState = StageState.COMPLETE;
                    
                    // execute stage
                    // check condition
                    // set state to COMPLETE
                
                    continue;
                }
                
                retries++;
            }
        }
        
        previous = stageTask;
    }
    
    return true;
}

public bool executeStageQueue(DList!StageTask queue, ref shared(TraverselState) state)
{
    // is while-true loop better?
    StageTask previous;
    foreach (StageTask stageTask; queue[])
    {
        StageState stageState = state.getState(stageTask.stage);
        if (stageState == StageState.PENDING)
        {
            // while loop? until condition is met
            //if (state.getState(previous.stage) == stageTask.condition)
            //{
                //state.setState(stageTask.stage, StageState.STARTED);
                // execute stage
            //}
            //else
            {
                return false;
            }
        
            // check condition
            // set state to STARTED
            // execute stage
        }
        else if (stageState == StageState.FAILED)
        {
            // ??
        }
        else
        {
            return false;
        }
        
        previous = stageTask;
    }

    return true;
}
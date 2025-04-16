module pap.flow.executor;

import std.container : DList;

import pap.recipes.stages : StageRecipe, getStageById;
import pap.flow.generator : FlowNodeCondition;
import pap.flow.traverser : StageState, TraverselState, StageTask, StageQueueResult, compareStateToCondition;

public bool test(DList!StageTask queue, ref shared(TraverselState) state, StageRecipe[] stages)
{
    import std.stdio : writeln;
    import std.conv : to;

    StageTask previous;
    StageState currentState;
    //while (true)
    //{
    //    if (previous.stage.length <= 0)
    //    {
    //        previous = queue.front;
    //    }
    //}

    //writeln("beginning stage queue: ", i);
    // if current state has `STARTED` condition and previous stage finished before the current check?
    master: foreach (StageTask stageTask; queue[])
    {
        currentState = state.getState(stageTask.stage);

        if (currentState == StageState.PENDING)
        {
            state.setState(stageTask.stage, StageState.STARTED);

            int retries;
            while (currentState != StageState.COMPLETE)
            {
                if (retries > 2048)
                {
                    state.setState(stageTask.stage, StageState.SKIPPED);
                    continue master;
                }

                if (previous.stage.length <= 0 || stageTask.condition == FlowNodeCondition.ROOT || compareStateToCondition(state.getState(previous.stage), stageTask.condition))
                {
                    state.setState(stageTask.stage, StageState.STARTED);

                    StageRecipe stage = stages.getStageById(stageTask.stage);

                    // execute stage
                    
                    // if execution went bad (return false or something)
                    // set state to FAILED
                    // else state to COMPLETE
                    state.setState(stageTask.stage, StageState.COMPLETE);

                    continue master;
                }

                currentState = state.getState(stageTask.stage);
                retries++;
            }
        }
        
        if (currentState == StageState.STARTED)
        {
            while (currentState == StageState.STARTED)
            {
                currentState = state.getState(stageTask.stage);
            }
            
            continue master;
        }
        
        if (currentState == StageState.FAILED)
        {
            // what to do here?
            // like retry? should the rest of the chain/queue be canceled?
            // i suppose not since the next stage might be dependent on this stage failing.
            // but what about the stage after that? the next stage would be skipped, and i suppose the next stage would be skipped too.
            // is this just fine then?
            
            continue master;
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

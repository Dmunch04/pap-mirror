module pap.flow.executor;

import std.container : DList;

import pap.flow.traverser : StageState, TraverselState, StageTask, StageQueueResult;

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
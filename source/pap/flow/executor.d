module pap.flow.executor;

import std.container : DList;

import pap.flow.traverser : StageState, TraverselState, StageTask, StageQueueResult;

public bool executeStageQueue(DList!StageTask queue, ref shared(TraverselState) state)
{
    foreach (StageTask stageTask; queue[])
    {
        StageState stageState = state.getState(stageTask.stage);
        if (stageState == StageState.PENDING)
        {
            // get parent???
        
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
    }

    return true;
}
module pap.flow.executor;

import std.container : DList;

import pap.recipes.stages : StageRecipe, getStageById;
import pap.flow.generator : FlowNodeCondition;
import pap.flow.traverser : StageState, TraverselState, StageTask, StageQueueResult, compareStateToCondition;

private const(int) MAX_RETRIES = 4096; // 2048?

public bool executeStageQueue(DList!StageTask queue, ref shared(TraverselState) state, StageRecipe[] stages)
{
    StageTask previous;
    StageState currentState;
    
    // TODO: something is wrong here; sometimes (but only sometimes) 'stage1-retry' isn't skipped but instead completed? why is that??
    // ^^ it might have something to do with the sorting of the queues. although not sure. but after having sorted the DList![] array
    // ^^ before passing it to the parallel task, it most of the times worked (skipped) but now it always failes (completed).
    // ^^ however if the sorting is really the problem, then it seems like this is not as robust as i'd hoped.
    // ^^^ sorting it backwards (long to small), instead of small to long, actually seems to work haha. perhaps it's because there's something
    // ^^^ wrong with that specific queue? because it's so short? because it's "recursive"? i have no idea. more testing is needed.
    // 
    // TODO: inside flow/generator.d i explained how the "recursive" should really be done. like stage1 <-> stage1-retry, however the current queue for those looks like:
    // 0: stage1 =(failed)> 1: stage1-retry
    // but if stage1 fails and triggers stage1-retry, then how would stage1-retry trigger stage1 again after completing? the queue ends there so?
    master: foreach (StageTask stageTask; queue[])
    {
        currentState = state.getState(stageTask.stage);
    
        if (currentState == StageState.PENDING)
        {
            // TODO: has it really started here? wouldn't it still technically be pending since the check for stage condition hasn't been made?
            //state.setState(stageTask.stage, StageState.STARTED);
    
            int retries;
            while (currentState != StageState.COMPLETE)
            {
                if (retries > MAX_RETRIES)
                {
                    state.setState(stageTask.stage, StageState.SKIPPED);
                    continue master;
                }
    
                if (previous.stage.length <= 0 || stageTask.condition == FlowNodeCondition.ROOT || compareStateToCondition(state.getState(previous.stage), stageTask.condition))
                {
                    state.setState(stageTask.stage, StageState.STARTED);
    
                    StageRecipe stage = stages.getStageById(stageTask.stage);
    
                    // execute stage
                    StageExecutionResult result = stage.execute();
                    
                    if (!result.success)
                    {
                        state.setState(stageTask.stage, StageState.FAILED);
                    }
                    else
                    {
                        state.setState(stageTask.stage, StageState.COMPLETE);
                    }
                    
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
            // 
            // ^^ actually as discussed in flow/generator.d: (quote)
            // however it's important to keep track of which stages
            // has already been started (no longer pending) so it isn't triggered twice by a delayed stage completing. now of course in this instance STAGE1 will be triggered
            // until successful. so perhaps unless the state is PENDING or FAILED it shouldn't be triggered again? hmm
            // (quote-end), we should be able to run a failed stage again, however it should only be if it has been triggered. so again how would the queue:
            // 0: stage1 =(failed)> 1: stage1-retry
            // work out?
            
            continue master;
        }
    
        previous = stageTask;
    }
    
    return true;
}

public struct StageExecutionResult
{
    /// The ID of the stage that was executed.
    string stageId;
    /// Whether the stage was executed successfully.
    bool success;
    
    /// The name of the step that failed, if any.
    string failedStep;
    /// The error message, if any.
    string errorMessage;
}

public StageExecutionResult execute(StageRecipe stage)
{
    // TODO: execute each step
    return StageExecutionResult(stage.id, true, "");
}

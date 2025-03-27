function [task] = updateStaircase(task,td,data)

ii = td.targSide;
jj = td.whichStair;
respCorr = data.respCorrect1;

thisIntensity = data.stimMaskISI;

%% update staircase stimulus levels based on response on last trial
if task.stairType == 1
    
    if task.stair.inLog10
        thisIntensity = log10(thisIntensity);
    end
    task.stair.q{ii,jj} = QuestUpdate(task.stair.q{ii,jj},thisIntensity,respCorr);
    task.stair.q{ii,jj}.ntrials = task.stair.q{ii,jj}.ntrials+1;
elseif task.stairType == 2
    task.stair.q{ii,jj} = PAL_AMUD_updateUD(task.stair.q{ii,jj},respCorr);
    if task.stair.reduceStepSize %CHECK IF TIME TO HALF THE STEP SIZE
        if task.stair.q{ii,jj}.reversal(end)==task.stair.revsToReduceStep
            task.stair.q{ii,jj}.stepSizeUp=task.stair.q{ii,jj}.stepSizeUp*0.5;
            task.stair.q{ii,jj}.stepSizeDown=task.stair.q{ii,jj}.stepSizeDown*0.5;
        end
    end
elseif  task.stairType == 3
    respPres = any(data.chosenRes1(1) == task.buttons.stim2);
    task.stair.ss{ii,jj} = updateSIAM(task.stair.ss{ii,jj},td.targPres,respPres);
end

%% decide whether each staircase is done

if task.stairType==2
    stairsDone = false(task.stair.nSeparateConds,task.stair.nPerCond);
    for i=1:task.stair.nSeparateConds
        for c=1:task.stair.nPerCond
            stairsDone(i,c) = task.stair.q{i,c}.stop;
        end
    end
    
elseif task.stairType==3
    
    if task.stair.terminateByReversalCount
        stairsDone = false(task.stair.nSeparateConds,task.stair.nPerCond);
        propDones   = zeros(task.stair.nSeparateConds,task.stair.nPerCond);
        for i = 1:task.stair.nSeparateConds
            for c = 1:task.stair.nPerCond
                stairsDone(i,c) = task.stair.ss{i,c}.nRevStableSteps>=task.stair.nRevToStop;
                propDones(i,c)  = task.stair.ss{i,c}.nRevStableSteps/task.stair.nRevToStop;
            end
        end
        
    else
        stairsDone = false(task.stair.nTypes,task.stair.nPerType);
    end
end

task.stair.done = stairsDone;

function task = setupStairs(task)

if task.stairType==1
    if task.stair.inLog10
        tGuess= log10(task.stair.threshStartGuess);
        tGuessSd=log10(task.stair.threshSDStartGuess);
    else
        tGuess= task.stair.threshStartGuess;
        tGuessSd=task.stair.threshSDStartGuess;
    end
    tGuess=squeeze(tGuess);
    pThreshold=task.stair.threshLevel;
    for i=1:task.stair.nSeparateConds
        for c=1:task.stair.nPerCond
            task.stair.q{i,c}=QuestCreate(tGuess(c),tGuessSd,pThreshold,task.stair.beta,task.stair.delta,task.stair.gamma);
            task.stair.q{i,c}.normalizePdf=1; % This adds a few ms per call to QuestUpdate, but otherwise the pdf will underflow after about 1000 trials.
            task.stair.q{i,c}.ntrials = 0;
        end
    end
    task.stair.q{1,1}.subj=task.subj;
    task.stair.q{1,1}.date=date;
    
elseif task.stairType==2
    if task.stair.inLog10
        tGuess= log10(task.stair.threshStartGuess);
        tMin = log10(task.stair.minIntensity);
        if isinf(tMin)
            tMin = -10;
            fprintf(1,'\n(%s) Warning: minIntensity for staircase is negative infinity when logged. Setting to %.1f\n\n', mfilename, tMin);
        end
        tMax = log10(task.stair.maxIntensity);
    else
        tGuess= task.stair.threshStartGuess;
        tMin = task.stair.minIntensity;
        tMax = task.stair.maxIntensity;
    end
    for i=1:task.stair.nSeparateConds
        for c=1:task.stair.nPerCond
            task.stair.q{i,c}=PAL_AMUD_setupUD('Up',task.stair.nUp,'Down',task.stair.nDn,'stepSizeUp',task.stair.stepUp,'stepSizeDown',task.stair.stepDn,'stopCriterion',task.stair.stopCriterion,'stopRule',task.stair.stopRule,'startValue',tGuess(c),'xMax',tMax,'xMin',tMin,'truncate',task.stair.truncate);
        end
    end
    task.stair.q{1,1}.subj=task.subj;
    task.stair.q{1,1}.date=date;
    
elseif task.stairType==3
    for i=1:task.stair.nSeparateConds
        for c=1:task.stair.nPerCond
            startlev = task.stair.threshStartGuess;
            %set bounds, [min max]
            if task.stair.inLog10
                theStart = log10(startlev);
                theBounds  = log10([task.stair.minIntensity task.stair.maxIntensity]);
            else
                theStart = startLev;
                theBounds = [task.stair.minIntensity task.stair.maxIntensity];
            end
            
            task.stair.ss{i,c} = initSIAM(task.stair.t, task.stair.startStep, theStart(c), theBounds, task.stair.revsToHalfContr, task.stair.revsToReset, task.stair.nStuckToReset);
        end
    end
end

%initialize variable that will say which staircases are done
task.stair.done = false(task.stair.nSeparateConds,task.stair.nPerCond);
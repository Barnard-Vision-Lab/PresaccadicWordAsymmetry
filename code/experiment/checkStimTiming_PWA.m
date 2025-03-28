function t = checkStimTiming_PWA(trials, task)

segsToCheck = {'fixation','preCue','stimuli'};

goodTrials = trials.trialDone==1 & ~isnan(trials.trialDone);

for si=1:length(segsToCheck)
    seg = segsToCheck{si};
    
    segI = find(strcmp(task.trialStruct.segmentNames, seg));
    nextSeg = task.trialStruct.segmentNames{segI+1};
    
    eval(sprintf('durs = trials.t%sOns - trials.t%sOns;', nextSeg, seg));
    durs = durs(goodTrials); 
    
    if strcmp(seg, 'stimMaskISI')
        goalDurs = trials.preCueDur(goodTrials)/1000;
    else
        eval(sprintf('goalDurs = task.durations.%s;', seg));
    end
    
    eval(sprintf('t.%s.meanDur = mean(durs);', seg));
    eval(sprintf('t.%s.minDur = min(durs);', seg));
    eval(sprintf('t.%s.maxDur = max(durs);', seg));
    eval(sprintf('t.%s.sdDur = std(durs);', seg));

    durErrors = durs - goalDurs;
    eval(sprintf('t.%s.meanDurError = mean(durErrors);', seg));
    eval(sprintf('t.%s.minDurError = min(durErrors);', seg));
    eval(sprintf('t.%s.maxDurError = max(durErrors);', seg));
    eval(sprintf('t.%s.sdDurError = std(durErrors);', seg));
    
end

function runData = summarizeRunPerformance(runData, trials, task)

%open a textfile
theDate = [datestr(now,'yy') datestr(now,'mm') datestr(now,'dd')];
txtFile = fullfile(task.subjDataFolder,sprintf('%s_%s_RunSummary.txt', task.subj, theDate));

%check if there was a prior file with this same name. If so, add an integer to the end of it.
fileExists = exist(txtFile, 'file');
dfi  = 1;
while fileExists
    dfi = dfi+1;
    txtFile = fullfile(task.subjDataFolder,sprintf('%s_%s_RunSummary_%i.txt', task.subj, theDate,dfi));
    fileExists = exist(txtFile, 'file');
end

tf = fopen(txtFile, 'w');

goodTrials = ~isnan(trials.trialDone);
goodTrials = goodTrials & trials.trialDone==true;

cueVs = [-1 0 1]; %invalid, neutral, valid
cueVNames = {'Invalid','Neutral','Valid'};
nConds = length(cueVs);

runData.pcByCond = NaN(1,nConds);
runData.dprmByCond = NaN(1,nConds);
runData.ntsByCond = NaN(1,nConds);
runData.cueValidity = cueVs;
runData.cueCondLabels = cueVNames;
for cueI = 1:nConds
    cueCond = runData.cueValidity(cueI);
    theseTs = trials.cueValidity==cueCond & goodTrials;
    targSides = trials.targetSide(theseTs);
    
    resp = task.buttons.reportedCategory(trials.chosenRes(theseTs))';
    pres = trials.targetCategory(theseTs);
    
    runData.ntsByCond(cueI) = length(resp);
    
    if ~isempty(resp)
        %and subtract 2 so that these are 0s and 1s
        pres = pres-2;
        resp = resp-2;
        
        respCorrect = resp==pres;
        runData.pcByCond(cueI) = mean(respCorrect(:));
        runData.dprmByCond(cueI) = computeDC(pres(:), resp(:));
             
    end
end

%% gaze behavior


cuedTrls = trials.cueValidity~=0 & goodTrials;
runData.pFixBreak = mean(trials.fixBreak,'omitnan');
runData.pSaccTooSlow = mean(trials.saccadeTimeout(cuedTrls),'omitnan');
trials.saccadeLatency  = NaN(size(trials.fixBreak));
trials.saccadeLatency(cuedTrls) = trials.tMovementStart(cuedTrls) - trials.tpreCueOns(cuedTrls);
runData.meanSaccLat = mean(trials.saccadeLatency(cuedTrls),'omitnan');
runData.medianSaccLat = median(trials.saccadeLatency(cuedTrls),'omitnan');

trials.fixBreak(isnan(trials.fixBreak)) = 0;
trials.saccadeTimeout(isnan(trials.saccadeTimeout)) = 0;

runData.saccPrcts = prctile(trials.saccadeLatency(cuedTrls), task.idealPreCueDurSaccLatPrctls);
runData.newPreCueMin = runData.saccPrcts(1) - task.time.stimuli;
runData.newPreCueMax = runData.saccPrcts(2) - task.time.stimuli;


saccTrls = cuedTrls & ~trials.fixBreak & ~trials.saccadeTimeout;
runData.pWordsGoneBeforeSaccLand = mean(trials.tLanded(saccTrls)>trials.tStimOffset(saccTrls),'omitnan');
runData.pWordsFixated = mean(trials.tLanded(saccTrls)<=trials.tStimOffset(saccTrls),'omitnan');

%% print out results
theTime = clock;

for f = [1 tf]
    fprintf(f,'SUMMARY OF PWA RUN FOR SUBJECT %s ON DATE %s, %i:%i', task.subj, date, theTime(4), theTime(5));
    fprintf(f,'\n%i blocks done, over %.1f minutes\n', runData.blocksDone, (runData.tRunEnd-runData.tRunStart)/60);
    fprintf(f,'\nMean percent correct = %.1f%%\n', runData.meanPCorrect*100);
    fprintf(f,'\nAccuracy by cue condition:\n');
    fprintf(f,'\n\t\t      p(corr)\td''\tnTrls\n');
    for cueI = 1:nConds
        fprintf(f,'%s\t\t%.2f\t%.1f\t%i\n', runData.cueCondLabels{cueI}, runData.pcByCond(cueI), runData.dprmByCond(cueI), runData.ntsByCond(cueI));
    end
    fprintf(f,'\n\nEye movement behavior:\n');
    fprintf(f,'Fixation break on %.1f%% of trials\n', 100*runData.pFixBreak);
    fprintf(f,'Median saccade latency: %.1f ms\n', 1000*runData.medianSaccLat);
    fprintf(f,'Saccade too slow on %.1f%% of trials\n', 100*runData.pSaccTooSlow);
    fprintf(f,'Words disappared before saccade landing on %.1f%% of good-sacade trials\n', 100*runData.pWordsGoneBeforeSaccLand);
    fprintf(f,'Words got fixated after saccade on %.1f%% of good-saccade trials\n', 100*runData.pWordsFixated);
            
    fprintf(f,'\nPercentiles of saccade latency\n');
    for pp = 1:2
        fprintf(f,'\t%ith = %.3f', task.idealPreCueDurSaccLatPrctls(pp), runData.saccPrcts(pp));
    end
    fprintf(f,'\nRecommended preCueMin: %.3f; preCueMax: %.3f', runData.newPreCueMin, runData.newPreCueMax);
end

%% print out timing performance 
t = runData.timing;
for f = [1 tf]

    fprintf(f, '\n\n\nTIMING CHECK:\n');
    fprintf(f,'Stimulus duration: mean=%.4f, min=%.4f, max=%.4f\n', t.stimuli.meanDur, t.stimuli.minDur, t.stimuli.maxDur);
    fprintf(f,'Stimulus duration error: mean=%.4f, min=%.4f, max=%.4f\n', t.stimuli.meanDurError, t.stimuli.minDurError, t.stimuli.maxDurError);
    
    fprintf(f,'preCue duration error: mean=%.4f, min=%.4f, max=%.4f\n', t.preCue.meanDurError, t.preCue.minDurError, t.preCue.maxDurError);

end
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


runData.pcByCond = NaN(1,3);
runData.dprmByCond = NaN(1,3);
runData.ntsByCond = NaN(1,3);
runData.cueConds = [0 1 2];
runData.cueCondLabels = {'Dual-task',['Single-task ' task.strings.posLabels{1}], ['Single-task ' task.strings.posLabels{2}]};
for cueI = 1:length(runData.cueConds)
    cueCond = runData.cueConds(cueI);
    theseTs = trials.cueCond==cueCond & goodTrials;
    targSides = trials.targSide(theseTs);
    
    if cueCond==0
        resp = task.buttons.reportedCategory([trials.chosenRes1(theseTs) trials.chosenRes2(theseTs)]);
        pres = [trials.side1Category(theseTs) trials.side2Category(theseTs)];
        %flip the left/right order on trials when side 2 was post-cued
        %first (targSide==2)
        pres(targSides==2, :) = fliplr(pres(targSides==2, :));
    else
        resp = task.buttons.reportedCategory(trials.chosenRes1(theseTs))';
        if cueCond==1
            pres = trials.side1Category(theseTs);
        else
            pres = trials.side2Category(theseTs);
        end
    end
    
    runData.ntsByCond(cueI) = size(resp,1);
    
    if ~isempty(resp)
        %and subtract 1 so that these are 0s and 1s
        pres = pres-1;
        resp = resp-1;
        
        respCorrect = resp==pres;
        runData.pcByCond(cueI) = mean(respCorrect(:));
        runData.dprmByCond(cueI) = computeDC(pres(:), resp(:));
     
    end
end

%% print out results
theTime = clock;

for f = [1 tf]
    fprintf(f,'SUMMARY OF SCLR RUN FOR SUBJECT %s ON DATE %s, %i:%i', task.subj, date, theTime(4), theTime(5));
    if task.doStair
        fprintf(f,'\nSTAIRCASE RUN\n');
    else
        fprintf(f,'\n\nISI was set to: %.1f ms\n', 1000*task.durations.stimMaskISI);
    end
    fprintf(f,'\n%i blocks done, over %.1f minutes\n', runData.blocksDone, (runData.tRunEnd-runData.tRunStart)/60);
    fprintf(f,'\nMean percent correct = %.1f%%\n', runData.meanPCorrect*100);
    fprintf(f,'\nAccuracy by cue condition:\n');
    fprintf(f,'\n\t\t      p(corr)\td''\tnTrls\n');
    for cueI = 1:length(runData.cueConds)
        fprintf(f,'%s\t\t%.2f\t%.1f\t%i\n', runData.cueCondLabels{cueI}, runData.pcByCond(cueI), runData.dprmByCond(cueI), runData.ntsByCond(cueI));
    end
    
    fprintf(f,'\nMEAN SINGLE-TASK ACCURACY = %.1f%%\n', 100*nanmean(runData.pcByCond(runData.cueConds>0)));
end

%% print out timing performance 
t = runData.timing;
for f = [tf]

    fprintf(f, '\n\n\nTIMING CHECK:\n');
    fprintf(f,'Stimulus duration: mean=%.4f, min=%.4f, max=%.4f\n', t.stimuli.meanDur, t.stimuli.minDur, t.stimuli.maxDur);
    fprintf(f,'Stimulus duration error: mean=%.4f, min=%.4f, max=%.4f\n', t.stimuli.meanDurError, t.stimuli.minDurError, t.stimuli.maxDurError);
    
    fprintf(f,'ISI duration error: mean=%.4f, min=%.4f, max=%.4f\n', t.stimMaskISI.meanDurError, t.stimMaskISI.minDurError, t.stimMaskISI.maxDurError);

end
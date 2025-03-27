function [task] = extractStaircaseData(task)

task.stair.threshEstimates = zeros(task.stair.nTypes,task.stair.nPerType);
task.stair.threshSDs = zeros(task.stair.nTypes,task.stair.nPerType);
task.stair.meanThreshs = zeros(task.stair.nTypes,1);
for sti = 1:task.stair.nTypes
    for ssi = 1:task.stair.nPerType
        if task.stairType == 1
            task.stair.threshEstimates(sti,ssi) = QuestMean(task.stair.q{sti,ssi});
            task.stair.threshSDs(sti,ssi) = QuestSd(task.stair.q{sti,ssi});            
        elseif task.stairType == 2
            lastRevsToCount = max(task.stair.q{sti,ssi}.reversal)-task.stair.revsToIgnore;
            if lastRevsToCount>=task.stair.minRevsForThresh
                task.stair.threshEstimates(sti,ssi) = PAL_AMUD_analyzeUD(task.stair.q{sti,ssi},'reversals',lastRevsToCount);
                task.stair.threshSDs(sti,ssi) = std(task.stair.q{sti,ssi}.x(task.stair.q{sti,ssi}.reversal>task.stair.revsToIgnore));
            else
                ntsStair = length(task.stair.q{sti,ssi}.response);
                lastTrlsToCount = ntsStair-task.stair.trialsIgnoredThresh;
                if lastTrlsToCount<1, lastTrlsToCount=ntsStair; end
                task.stair.threshEstimates(sti,ssi) = PAL_AMUD_analyzeUD(task.stair.q{sti,ssi},'trials',lastTrlsToCount);
                cntTrlIs = (ntsStair-(lastTrlsToCount-1)):ntsStair;
                task.stair.threshSDs(sti,ssi) = std(task.stair.q{sti,ssi}.x(cntTrlIs));
            end
        elseif task.stairType == 3
            [thrsh, ntrls, sd] = estimateSIAM(task.stair.ss{sti,ssi},task.stair.threshType);
            task.stair.threshEstimates(sti,ssi) = thrsh;
            task.stair.threshSDs(sti,ssi) = sd;
            task.stair.numThreshTrials(sti,ssi) = ntrls;
        end
    end
end

if task.stair.inLog10
    task.stair.threshEstimates = 10.^task.stair.threshEstimates;
    task.stair.threshSDs = 10.^task.stair.threshSDs;
end

task.stair.meanThreshs=nanmeanAW(task.stair.threshEstimates,2);
task.stair.meanThreshs(task.stair.meanThreshs>task.stair.maxIntensity)=task.stair.maxIntensity;



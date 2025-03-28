function task = initializeData_PWA(task)

numTrials = size(task.trials,1);

%empty matrix 
emptyMat = NaN(numTrials,1);

%add segment onset times 
for segI = 1:task.trialStruct.nSegments
    eval(sprintf('task.trials.t%sOns = emptyMat;',task.trialStruct.segmentNames{segI}));
end

%others from the Trial function 
trialVars = {'tTrialStart','tITIOns','tITIOff','fixBreak','trialDone','nFixBreakSegs', 'didRecalib','quitDuringRecalib','tFeedback',...
              'tFixBreak','userQuit','trialDone','responseTimeout','stimMaskISI',...
              'chosenRes1','chosenRes2','tRes','respCorrect','pressedWrongSide', ...
              'tMovementStart','tLanded','tSaccTimeout','saccadeLanded','saccadeTimeout'};
          
for tdi = 1:numel(trialVars)
    eval(sprintf('task.trials.%s = emptyMat;',trialVars{tdi}));
end

%initialize variable that will be used to put each trial's data variables into vector 
task.emptyMat = emptyMat;

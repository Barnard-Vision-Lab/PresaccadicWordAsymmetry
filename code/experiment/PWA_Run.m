%% [task, scr, runData] = PWA_Run(task)
% Runs through a set number of blocks of the Pre-saccadic Word recognition Asymmetry experiment 
%
% Inputs:
% - task structure 
%
% Outputs:
% - task: big structure about stimuli
% - scr: structure about screen
% - ruData: structure with important data


function [task, scr, runData] = PWA_Run(task)


%% RESET RANDOM NUMBER GENERATOR
task.initialSeed = ClockRandSeed;
task.startTime=clock;


%% set data folder
theDate=date;
folderDate=[task.subj theDate(4:6) theDate(1:2)];
task.subjFolder = fullfile(task.paths.data,task.subj);
task.subjDataFolder = fullfile(task.subjFolder,folderDate);
if ~isfolder(task.subjDataFolder)
    mkdir(task.subjDataFolder);
end
task.pracDataFolder = fullfile(task.subjDataFolder,'practice');
if ~isfolder(task.pracDataFolder) && task.practice
    mkdir(task.pracDataFolder);
end

%% Initialize Screen
if task.reinitScreen
    [scr, task] = prepScreen(task);
else %set this bgColor variable
    if scr.normalizedLums
        task.bgColor = task.bgLum;
    else
        task.bgColor = floor(task.bgLum*((2^scr.nBits)-1));
    end
end

if task.practice
    task.EYE = task.pracEYE;
    
    if task.demo %long-duration stimuli in demo mode 
        task.time.stimuli = task.time.demoStimDur;
    end
end

if task.EYE == 999 %dummy mode
    ShowCursor;
else
    HideCursor(scr.main);
end

%% get response keys (and disable keyboard, UnifyKeyNames)
task.buttons = setupKeys_PWA();

%% %%%%%  Sounds
task = prepSounds(task);

%% make stimuli (colors, positions, find word images, etc)
task = makeStim_PWA(task, scr);

%% Timing Parameters

if task.EYE==1  
    task.time.ITI = task.time.ITI - task.time.startRecordingTime - task.minFixTime + 0.001;
    if task.time.ITI<0, task.time.ITI = 0; end
end

fps = scr.fps;
task.fps = fps;

%SET EACH TIMING PARAM TO MULTIPLE OF FRAME DURATION
tps = fullFieldnames(task.time);
%and add them to structure task.durations:
for ti = 1:numel(tps)
    tv = tps{ti};
    eval(sprintf('task.durations.%s = durtnMultipleOfRefresh(task.time.%s, fps, task.durationRoundTolerance);', tv, tv));
end

%% Set trial and block order
%makeTrials adds a table called runTrials to task, and it has all blocks 
task = makeTrials_PWA(task);

%set up the "blocks" structure, which is hardly used unless the timing mode is not self paced
startBlockNumber = min(task.runTrials.blockNum);
task.blocks.blockNum  = startBlockNumber + (1:task.numBlocks) - 1;


%% setup trial structure (things that don't change across trials, like segment durations)
task = setupTrialStructure_PWA(task);

%% make images of words for each trial
task = makeImageTextures_PWA(task,scr);

%% Block loop
%set goal times for each start
doRunBlocks            = true;

%initialize block number to the mininum in this runTrials (in case we're re-starting
%a previously unfinished run), minus one (because the number is incremented
%at the start of each iteration of the block loop.
blockNum = startBlockNumber -  1;

%also keep track of how many blocks have been done in this "session" (i.e.,
%since this function was most recently called).
thisSessBlockNum = 0;
blocksCompleted = 0;
userDone = false;
task.tRunStart = GetSecs;
doneTrials = table; %keep track of all trials that are done
while doRunBlocks
    blockNum = blockNum + 1;
    thisSessBlockNum = thisSessBlockNum + 1;
       
    blockGoalStartT = GetSecs;

    %RUN THE BLOCK
    [blockRes, task] = PWA_Block(scr,task,blockNum,thisSessBlockNum,blockGoalStartT);
    
    %save all data 
    doneTrials = [doneTrials; task.trials]; 
    
    %compute single-task accuracy so far, for printing out in concludeBlock
    task.pcSoFar = mean(doneTrials.respCorrect,'omitnan');
    task.ntrialsDone = sum(~isnan(doneTrials.respCorrect));
    
    %extract block data
    ds = fieldnames(blockRes);
    for di = 1:numel(ds)
        eval(sprintf('runData.%s(thisSessBlockNum) = blockRes.%s;',ds{di},ds{di}));
    end
    
    if ~blockRes.userQuitPartway
        blocksCompleted = blocksCompleted+1;
        
        if ~task.practice
            userDone = concludeBlock_PWA(task,scr,thisSessBlockNum);
        end
    end

    %continue blocks?
    doRunBlocks  = (thisSessBlockNum<task.numBlocks) && ~blockRes.userQuitPartway(end) && ~blockRes.terminateByStair && ~userDone;
end
task.tRunEnd = GetSecs;

%Close textures (all at once)
alltex = [task.stringTextures(:); task.maskTextures(:)];
Screen('Close',alltex(~isnan(alltex)));

%% Shut down screen
% re-enable keyboard
ListenChar(1);
ShowCursor;
% Screen(visual.main,'Resolution', scr.oldRes);
Screen('CloseAll');
RestoreCluts; %to undo effect of loading normalized gamma table

if task.doDataPixx
    PsychDataPixx('Close');
end

%switch screen back to the original resolution if necessary
if scr.changeRes
    SetResolution(scr.expScreen,scr.oldRes);
end

% Close the audio device:
if task.usePortAudio
    PsychPortAudio('Close');
else
    Snd('Close');
end

%% collect run data
task.tRunEnd         = GetSecs;
runData.subj         = task.subj;
runData.date         = date;
runData.blocksDone   = blocksCompleted;
runData.tRunStart    = task.tRunStart;
runData.tRunEnd      = task.tRunEnd;
runData.runDuration  = task.tRunEnd - task.tRunStart;
runData.userQuitMidBlock  = blockRes.userQuitPartway;
runData.userDoneBtwnBlocks = userDone;
runData.teriminatedByStair = blockRes.terminateByStair;
runData.meanPCorrect  = mean(runData.pc(~isnan(runData.pc)));

if ~task.practice
    %check stimulus timing
    runData.timing = checkStimTiming(doneTrials, task);
    
    %print
    try
        runData = summarizeRunPerformance(runData, doneTrials, task);
    catch me
        sca
        keyboard
    end
end


%% save run data
if ~task.practice
    theDate = [datestr(now,'yy') datestr(now,'mm') datestr(now,'dd')];
    dataFile = fullfile(task.subjDataFolder,sprintf('%s_%s_RunSummary.mat', task.subj, theDate));
    
    %check if there was a prior file with this same name. If so, add an integer to the end of it.
    fileExists = exist(dataFile, 'file');
    dfi  = 1;
    while fileExists
        dfi = dfi+1;
        dataFile = fullfile(task.subjDataFolder,sprintf('%s_%s_RunSummary_%i.mat', task.subj, theDate,dfi));
        fileExists = exist(dataFile, 'file');
    end
    
    save(dataFile,'runData'); 
end




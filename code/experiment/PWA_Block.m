function [blockRes, task] = PWA_Block(scr,task,blockNum,thisSessBlockNum,goalStartTime)

%% choose trials for this block
task.trials = task.runTrials(task.runTrials.blockNum==blockNum,:);

%% Set where to store the data
[matFileName, eyelinkFileName, task] = setupDataFile_PWA(blockNum, task);
%Extract the name of this m file
[st,i] = dbstack;
scr.codeFilename = st(min(i,length(st))).file;
task.codeFilename = scr.codeFilename;

%% %% initialize data structure
task = initializeData_PWA(task);


%% %%%%%%%%%%%%%%%%
% Initialize eyelink and calibrate tracker
%%%%%%%%%%%%%%%%%%
if task.EYE > 0 %0= no eye-tracking at all; 1=tracking; 999=dummy mode
    
    [el, elStatus] = initializeEyelink(eyelinkFileName, task, scr);
    
    if elStatus == 1
        fprintf(1,'\nEyelink initialized with edf file: %s.edf\n\n',eyelinkFileName);
    else
        fprintf(1,'\nError in connecting to eyelink!\n');
    end
    
    if task.EYE == 1
        calibrateEyelink(el, task, scr);
    end
else
    el = [];
end

%% Start eyelink recording  - before trigger!
%if self-paced, eyetrack recording is turned on and off every trial;
%otherwise, need to start recording now
if task.EYE>0 && ~task.selfPaced
    Eyelink('command','clear_screen');
    
    if task.EYE>0
        if Eyelink('isconnected')==el.notconnected		% cancel if eyeLink is not connected
            return
        end
    end
    [record, task] = startEyelinkRecording(el, task);
    
    % This supplies a title at the bottom of the eyetracker display
    Eyelink('command', 'record_status_message ''Start scan %d''', task.runNumber);
else
    record = false;
end

task.eyelinkIsRecording = record;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Instructions and wait
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if task.EYE > 1 %dummy mode
    ShowCursor;
else
    HideCursor(scr.main);
end

WaitSecs(1);

instruct_PWA(task,scr,thisSessBlockNum);


%% Block start

Priority(scr.maxPriorityLevel); %set priority to max just for running trial - on linux priority level should be 1

task.tBlockStart = GetSecs;
task.startTime=clock;


if task.EYE>0, Eyelink('message', 'BLOCK_START %d', blockNum); end

ti = 0; %counter of trials
nTrials = size(task.trials,1);
doRunTrials = true;

while doRunTrials
    ti = ti +1;
    td = task.trials(ti,:);
    
    
    
    trialGoalStart = GetSecs;
    
    if ti==1
        
        %Insert an ITI with fixation mark before 1st trial (because
        %ITIs are put after each trial);
        drawFixation_PWA(task, scr, 1);
        Screen('Flip', scr.main);
        WaitSecs(task.durations.ITI);
    end
    
    
    if task.EYE>0
        %start eyelink recording and establish fixation
        [el, task, quitDuringRecalib, didRecalib] = preTrialEyetrackerSetup(el,task,scr);
    else
        quitDuringRecalib = false;
        didRecalib = false;
        %define fixation breaks against same positions always:
        task.fixation.newX = task.fixation.posX(1);
        task.fixation.newY = task.fixation.posY(1);
    end
    
    
    %NOW RUN THE TRIAL
    if ~quitDuringRecalib
        
        [trialRes, task] = PWA_Trial(scr,task,td,el,trialGoalStart);
        
        
        if ti==1
            blockRes.blockStartTime = trialRes.tTrialStart;
        end
        
        %extract data
        trialRes.didRecalib = didRecalib;
        trialRes.quitDuringRecalib = quitDuringRecalib;
        dataVars = fieldnames(trialRes);
        trialVars = task.trials.Properties.VariableNames;
        for di = 1:numel(dataVars)
            %check if this one was not initialized in initializeData function
            if ti==1 && ~any(strcmp(trialVars,dataVars{di}))
                eval(sprintf('task.trials.%s = task.emptyMat;',dataVars{di}));
            end
            eval(sprintf('task.trials.%s(ti) = trialRes.%s;',dataVars{di},dataVars{di}));
        end
        
        %if fixbreak, and this is behavioral testing, add that trial back at the end
        if ~trialRes.trialDone && ~task.MRI && ti<=(nTrials-task.nTrialsLeftRepeatAbort)
            nTrials = nTrials + 1;
            task.trials(nTrials, :) = td;
            task.trials.trialNum(nTrials) = nTrials;
            task.trials.overallTrialNum(nTrials) = max(task.trials.overallTrialNum)+1;
        end
        
        
        
    end
    %never terminate based on staircases finishing
    terminateByStair = false;
    
    doRunTrials = (ti < nTrials) && ~trialRes.userQuit && ~quitDuringRecalib && ~terminateByStair;
end

blockRes.trialsDone = ti - 1*trialRes.userQuit;
blockRes.pc = nanmeanAW([task.trials.respCorrect1(:); task.trials.respCorrect2(:)]);
blockRes.pTimeout = nanmeanAW(task.trials.responseTimeout(:));
blockRes.pFixBreak = nanmeanAW(task.trials.fixBreak(:));
blockRes.userQuitPartway = trialRes.userQuit | quitDuringRecalib; %terminate either if pressed q at end of trial or during recalib.
blockRes.terminateByStair = terminateByStair;

task.tBlockEnd = GetSecs;
blockRes.tBlockEnd = task.tBlockEnd;
if task.EYE>0, Eyelink('message', 'BLOCK_END %d', blockNum); end

task.blockDuration = task.tBlockEnd - task.tBlockStart;
blockRes.blockDuration = task.blockDuration;

task.endTime = clock;
task.el      = el;

Priority(0); %set priority back to 0

%% End eye-movement recording and extract eye data

% shut down everything, get EDF file
% get eyelink data file on subject computer
if task.EYE>0
       
    %stop recording
    if task.eyelinkIsRecording
        Screen(el.window,'FillRect',el.backgroundcolour);   % hide display
        WaitSecs(0.1);
        Eyelink('stoprecording');             % record additional 100 msec of data end
        Eyelink('command','clear_screen');
        Eyelink('command', 'record_status_message ''ENDE''');
    end

    %close file
    Eyelink('closefile');
    
    %transfer file 
    status = Eyelink('ReceiveFile');
    if status == 0
        fprintf(1,'\n\nFile transfer went pretty well\n\n');
    elseif status < 0
        fprintf(1,'\n\nError occurred during file transfer\n\n');
    else
        fprintf(1,'\n\nFile has been transferred (%i Bytes)\n\n',status)
    end
        
    %shut down
    Eyelink('shutdown');
    
    
    %move edf file to data folder
    [success, message] = movefile(sprintf('%s.edf',task.eyelinkFileName),sprintf('%s.edf',task.dataFileName));
    if ~success
        fprintf(1,'\n\n\nWARNING: ERROR MOVING EDF FILE ON BLOCK %i\n', blockNum);
        fprintf(1,message);
        fprintf(1,'\n\n\n\n');
    end
    
end



%% save data
save(sprintf('%s.mat',matFileName),'task','scr');
fprintf(1,'\n\nSaving data to: %s.mat\n',matFileName);
fprintf(1,'\nBlock %i took %.3f min.\n\n',blockNum, task.blockDuration/60);



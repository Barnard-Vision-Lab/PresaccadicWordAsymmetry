% START A RUN OF THE LEFT-RIGHT SEMANTIC CATEGORIZATION EXPERIMENT 
% This version: post-masks are consonant strings. SCLR_Cons_Spaced2: inner
% edge ecccentricity increased even further! 
clear all;

%% to do 
% - start with Trial function, make markers, then saccade detection and
% timing
% - list of pseudowords
% - make only 1 real word per trial and 1 pseudoword 
% - make precue interval variable 
% - adjust initializeData_PWA
% - summarizeRunPerformance function 
%% do eye-tracking? 0=no, 1=yes
EYE = 0;

%% set which screen we're using
if strcmp(getHostName(1),'vpixx-linux-machine')
    displayName = 'ViewPixx3D';
else
    displayName = 'ASUS';
end

%% get subject ID
aquestion = 'Enter the subject''s ID\n';
% % KLUGE!!! 
SID='xx'
while isempty(SID)
    SID = input(aquestion, 's');
end


%% do eye-tracking?
keepAskingEye = ~any(EYE == [0 1 999]);
while keepAskingEye
    EYE = input('\nDo you want to do eye-tracking?\n   0=no\n   1=yes\n   999=dummy mode with cursor\n');
    keepAskingEye = ~isfloat(EYE) || (~any(EYE == [0 1 999]));
end

%% Set paths 
paths = PWA_Paths();
cd(paths.code);
addpath(genpath(paths.code));

%% Load paramaters and add fields
params = PWA_Params;
params.subj = SID;
params.EYE = EYE;
params.displayName = displayName;
params.computerName = getHostName(1);
params.reinitScreen   = true;
params.shutDownScreen = true;
params.selfPaced = true;
params.MRI = false;
params.openSecondWindow = false;

%% Practice
aquestion = 'Do you want to do any practice trials?\n Enter ''y'' or ''n'', or ''d'' for long-duration demo\n';
doPracticeResp='x';
while ~any(strcmp(doPracticeResp, {'y','n','d'}))
    doPracticeResp = input(aquestion, 's');
end
doPractice = strcmp(doPracticeResp, 'y') || strcmp(doPracticeResp, 'd');
nPracBlocks = 0;

while doPractice
    params.practice = true;
    params.pracEYE = EYE == 1;
    params.doPracStair = false;
    params.demo = strcmp(doPracticeResp, 'd');
    params.numBlocks = 1;
    nPracBlocks = nPracBlocks+1;
    params.blockNum = nPracBlocks;

       
    %%
    try
        [pracTask, ~, pracRes] = PWA_Run(params);
    catch me
        PsychPortAudio('Close');
        ListenChar(1);
        ShowCursor;
        RestoreCluts; %to undo effect of loading normalized gamma table
        
        sca;
        
        if EYE>0 && Eyelink('IsConnected')
            Eyelink('stoprecording');
            Eyelink('closefile');
            Eyelink('shutdown');
        end 
        rethrow(me);
    end
    
    fprintf(1,'\nPractice block p(correct) = %.3f\n', pracRes.pc);
    
    aquestion = 'Do you want to do another practice block?\n Enter ''y'' or ''n'', or ''d'' for long-duration demo\n';
    doPracticeResp='xxx';
    while ~any(strcmp(doPracticeResp, {'y','n','d'}))
        doPracticeResp = input(aquestion, 's');
    end
    doPractice = strcmp(doPracticeResp, 'y') || strcmp(doPracticeResp, 'd');
end

params.practice = false;


%% set number of blocks, and cue conditions, for main experiment 

numBlocks = -1;
denom = 1;
while  ~all(isfloat(numBlocks)) || (numBlocks<0 || numBlocks>50) || mod(numBlocks, denom)~=0
    numBlocks = input(sprintf('\nEnter number of blocks you would like to do. Must be a multiple of %i (or 0 to quit).\n', denom));
end

params.numBlocks = numBlocks;

params.practice = false;
params.demo = false;
params.shutDownScreen = false;

%% ask to continue
if numBlocks==0
    doMain = 'n';
else
    doMain = 'y';
end
while ~any(strcmp(doMain, {'n','y'}))
    doMain = input('\nDo you want to continue? Enter y or n\n', 's');
end


%% Run main blocks
if strcmp(doMain,'y')
    
    %% actually run all the blocks: 
    try
        [task, scr, runData] = PWA_Run(params);
    catch me
        PsychPortAudio('Close');
        ListenChar(1);
        ShowCursor;
        RestoreCluts; %to undo effect of loading normalized gamma table
        
        sca;
        
        if EYE>0 && Eyelink('IsConnected')
            Eyelink('stoprecording');
            Eyelink('closefile');
            Eyelink('shutdown');
        end 
        rethrow(me);
    end    
end
  

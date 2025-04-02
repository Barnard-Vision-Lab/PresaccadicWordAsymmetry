%function [trialRes, task] = PWACS_Trial(scr,task,td,el,goalStartTime)
% This function runs 1 trial of the experiment.
% Inputs:
% - scr: screen structure
% - task: task structure (which inherited all the fields from the Params
% function)
% - td: a structure, or 1-row table, with fields that describe all the
% parameters for this trial;
% - el: the eyelink structure
% - goalStartTime: if not self-paced, when the first segment should happen.
%
% Outputs:
% - trialRes: a stucture with all the data of what happened on that trial.
% - task: the same task structure as input. May have some additions.

function [trialRes, task] = PWA_Trial(scr,task,td,el,goalStartTime)

% clear keyboard buffer
FlushEvents('KeyDown');

%pull out trialStruct, which has some useful info
ts = task.trialStruct;

Screen('TextSize',scr.main,task.textSize);

% predefine gaze position boundary for initial fixation
cxm = task.fixation.newX(1); %Desired fixation position, defined on each trial
cym = task.fixation.newY(1);
chk = scr.fixCkRad;

circleCheck = length(chk)==1; %if fixation check is a circle or rectangle

% define gaze position boundary for saccade landing
if td.cuedSide>0 %saccade trials (not neutral cue)
    targX = task.saccadeTargets.xPx(td.cuedSide);
    targY = task.saccadeTargets.yPx(td.cuedSide);
    checkCentralFix = ts.checkCentralFix_SaccTrls;
    checkSaccadeLanding = ts.checkSaccadeLanding_SaccTrls;
else %fixation trials, no saccade, neutral cue
    checkCentralFix = ts.checkCentralFix_FixnTrls;
    checkSaccadeLanding = ts.checkSaccadeLanding_FixtTrls;
end
landChk = scr.landingCheckRadPx;


ctrx = scr.centerX;
ctry = scr.centerY;
ctrpx = 3;

if task.EYE>0
    % draw trial information on EyeLink operator screen
    Eyelink('command','clear_screen 0');
    
    Eyelink('command','draw_filled_box %d %d %d %d 15', round(ctrx-ctrpx), round(ctry-ctrpx), round(ctrx+ctrpx), round(ctry+ctrpx));    % fixation
    if circleCheck
        Eyelink('command','draw_filled_box %d %d %d %d 15', round(cxm-chk/8), round(cym-chk/8), round(cxm+chk/8), round(cym+chk/8));    % fixation
        Eyelink('command','draw_box %d %d %d %d 15', cxm-chk, cym-chk, cxm+chk, cym+chk);                   % fix check boundary
    else
        Eyelink('command','draw_filled_box %d %d %d %d 15', round(cxm-chk(1)/8), round(cym-chk(2)/8), round(cxm+chk(1)/8), round(cym+chk(2)/8));    % fixation
        Eyelink('command','draw_box %d %d %d %d 15', cxm-chk(1), cym-chk(2), cxm+chk(1), cym+chk(2));                   % fix check boundary
    end
    
    %Draw box around saccade targget 
    if td.cuedSide>0
        Eyelink('command','draw_box %d %d %d %d 15', targX-landChk(1), targY-landChk(2), targX+landChk(1), targY+landChk(2));
    end
    % This supplies a title at the bottom of the eyetracker display
    Eyelink('command', 'record_status_message ''Block %d of %d, Trial %d of %d''', td.blockNum, task.numBlocks, td.trialNum, size(task.trials,1));
    % this marks the start of the trial
    Eyelink('message', 'TRIALID %d', td.trialNum);
end


%Draw fixation parameters:
fixPos = 1;

%% Run the trial: continuous loop that advances through each section

tTrialStart      = GetSecs;

%Initialize counters for trial events:
segment          = 0; %start counter of segments
fri              = 0; %counter of movie frames
segStartTs       = NaN(1, ts.nSegments);
chosenRes        = NaN;
respCorrect      = NaN;
tMovementStart   = NaN;
tResTone         = NaN;
tSaccTimeout     = NaN;
tRes             = NaN;
tFeedback        = NaN;
fixBreak         = 0;
nFixBreaks       = 0;
tFixBreak        = NaN;
nPressedQuit     = 0; %number of times subject presssed quit. 2 to abort
pressedWrongSide = false;
if any(ts.doMovie)
    frameTimes = NaN(1,ts.framesPerMovie);
end


if task.EYE>0
    Eyelink('message', 'Block %d Trial_START %d', td.blockNum, td.trialNum);
    Eyelink('message', 'Trial_Start_Condition %d',td.cuedSide);
    
    Eyelink('message', 'SYNCTIME');		% zero-plot time for EDFVIEW
end

t = tTrialStart;

if task.selfPaced %don't use goalStartTime input, becaause trial timing will vary
    goalStartTime = tTrialStart;
end

updateSegment = true; %start 1st segment immediately

doStimLoop = true;

%parameters for marker:
%during pre-cue, both sides, both pre-cue color
preCueMarkerSides = 1:2;
preCueMarkerColrs = [1 1];
%during post-cue, both sides, but target side is post-cue color

postCueMarkerSides = 1:2;
postCueMarkerColrs = [1 1];
postCueMarkerColrs(td.targetSide) = 2;

%flags for eye movements
moved  = false;
landed = false;
lndStarted = false;
lnd    = false;
lndStartT = NaN;
badEye = false;

dotsAppeared = false;

tooSlowSaccade = false;

while doStimLoop
    % Time counter
    if segment > 0
        t = GetSecs-segStartTs(segment);
        %update segment if this segment's duration is over, and it's not the last one
        updateSegment = t>(ts.durations(segment)-scr.flipTriggerTime) && segment < ts.nSegments;
    end
    
    if updateSegment
        lastSeg = segment;
        doIncrement = segment < ts.nSegments;
        while doIncrement
            segment = segment + 1;
            %stop at the last segment, and skip segments with duration 0:
            doIncrement = segment < ts.nSegments && ts.durations(segment) == 0;
        end
        
        segmentName = ts.segmentNames{segment};
        thisSegKeyPressed = false;
        thisSegFixBreak   =  false;
    end
    
    %update screen at switch of segment or if we're drawing the movie
    updateScreen = updateSegment || (ts.doMovie(segment) && fri < task.framesPerMovie);
    
    if updateScreen
        if ~ts.doMovie(segment)
            if segment == 1 %immediately start first segment
                goalFlipTime = goalStartTime;
            else
                goalFlipTime = segStartTs(lastSeg) + ts.durations(lastSeg) - scr.flipLeadTime;
            end
        else
            fri = fri+1; %update movie frame counter
            if fri==1
                goalFlipTime = segStartTs(lastSeg) + ts.durations(lastSeg) - scr.flipLeadTime;
            else
                goalFlipTime = frameTimes(fri-1)+ts.movieFrameDur - scr.flipLeadTime;
            end
        end
        
        %Draw fixation below everything else
        drawFixation_PWA(task,scr,fixPos);
        
        switch segmentName
            case 'fixation'
% %                 %fixation mark and pre-masks
                for si = 1:2
                    Screen('DrawTexture', scr.main, task.maskTextures(td.blockNum, td.originalBlockTrialNum, si), [], squeeze(task.maskRects(td.blockNum, td.originalBlockTrialNum, si, :)));
                end
                drawSaccTargDots_PWA(task, scr, 1:2, preCueMarkerColrs)

                %and markers
                drawMarkers_PWA(task, scr, preCueMarkerSides, preCueMarkerColrs);
            case 'preCue'
%                 %pre-masks
                for si = 1:2
                    Screen('DrawTexture', scr.main, task.maskTextures(td.blockNum, td.originalBlockTrialNum, si), [], squeeze(task.maskRects(td.blockNum, td.originalBlockTrialNum, si, :)));
                end
                drawSaccTargDots_PWA(task, scr, 1:2, preCueMarkerColrs)

                %marker
                drawMarkers_PWA(task, scr, preCueMarkerSides, preCueMarkerColrs);
                
                %central cue
                drawCues_PWA(task, scr, td.cuedSide, true);
                
            case 'stimuli'
                %draw two letter strings
                for si=1:2
                    Screen('DrawTexture', scr.main, task.stringTextures(td.blockNum, td.originalBlockTrialNum, si), [], squeeze(task.stringRects(td.blockNum, td.originalBlockTrialNum, si, :)));
                end
                
                %marker
                drawMarkers_PWA(task, scr, preCueMarkerSides, preCueMarkerColrs);
                
                %central cue
                drawCues_PWA(task, scr, td.cuedSide, true);
            
            case 'stimDotsISI'
                %marker
                drawMarkers_PWA(task, scr, preCueMarkerSides, preCueMarkerColrs);
            
            case 'dotsPostcueISI'
               %marker
                drawMarkers_PWA(task, scr, preCueMarkerSides, preCueMarkerColrs);
            
                %dots
                   % drawSaccTargDots_PWA(task, scr, 1:2, preCueMarkerColrs)

%             case 'stimPostcueISI'
%                 %marker
%                 drawMarkers_PWA(task, scr, preCueMarkerSides, preCueMarkerColrs);
%                 
%                  
            case 'postCue'
                %marker
                drawMarkers_PWA(task, scr, postCueMarkerSides, postCueMarkerColrs);
                
                %dots
                %drawSaccTargDots_PWA(task, scr, 1:2, postCueMarkerColrs)

                %cues
                drawCues_PWA(task, scr, td.targetSide, false);
                
        end
        
        
        %Flip screen:
        Screen(scr.main,'DrawingFinished');
        tFlip = Screen('Flip', scr.main, goalFlipTime);
        
        if ts.doMovie(segment)
            frameTimes(fri) = tFlip;
        end
        if updateSegment
            segStartTs(segment) = tFlip;
            if task.EYE>0 %send some eyelink messages
                Eyelink('message', sprintf('EVENT_%sOnset', segmentName));
            end
        end
        
        %         Screenshots:
        %          if strcmp(segmentName, 'stimuli')
        %                 mainImg=Screen('GetImage', scr.main);
        %                 save(sprintf('mainImg_%i.mat',round(rand*100)),'mainImg');
        %                 pause
        %          end
        
    end
    
    
    %% Check eye position
    if task.EYE > 0 && ts.checkEye(segment)
        [x,y] = getCoord(scr, task);
        %in some segments, check for fixation breaks from central fixation
        %mark (actually, adjusted to where the eyes were at start of trial), and
        %end stimulus presentation loop if the eyes move
        
        %if either eye is outside of fixation region, count as fixation break
        if circleCheck
            moved = any(sqrt((x-cxm).^2+(y-cym).^2)>chk) && x>0 && x<scr.xres && ~isnan(y) && y>0 && y<scr.yres;
        else
            if task.horizOnlyFixCheck
                %fixation break only if horizontal position is a valid number but deviates too
                %much, and vertical position does NOT deviate. In other
                %words, only if observer looks horizontally at the words.
                %The goal here is to allow blinks.
                moved = any(abs(x-cxm)>chk(1)) && ~isnan(x) && x>0 && x<scr.xres && any(abs(y-cym)<chk(2)) && ~isnan(y) && y>0 && y<scr.yres;
                %this doesn't quite work because around the time of a blink,
                %the eye position seems to deviate horizontally as well
                %                 if badeye
                %                    fprintf(1,'\nfix break with x = %.1f (dev. of %.1f, over %.1f), y = %.1f (dev. of %.1f, over %.1f)\n',x,abs(x-cxm),chk(1),y,abs(y-cym),chk(2));
                %                 end
            else
                moved = (any(abs(x-cxm)>chk(1)) || any(abs(y-cym)>chk(2))) && x>0 && x<scr.xres && ~isnan(y) && y>0 && y<scr.yres;
            end
        end
        
        if checkCentralFix(segment)
            badeye = moved;
            
            if badeye
                fixBreak = true;
                if ~thisSegFixBreak
                    nFixBreaks = nFixBreaks+1;
                    thisSegFixBreak = true;
                    tFixBreak = GetSecs;
                    if task.EYE>0, Eyelink('message', 'EVENT_fixationBreak'); end
                end
                
                %If this is behavioral training, abort trial
                if ~task.MRI
                    doStimLoop = false;
                end
            end
            
            %in other segments, check for eyes to land at target
        elseif checkSaccadeLanding(segment) && ~landed
            
            if moved && isnan(tMovementStart)
                tMovementStart = GetSecs;
            end
            
            %check if gaze is within window around saccade target
            lnd = (any(abs(x-targX)<landChk(1)) && any(abs(y-targY)<landChk(2))) && x>0 && x<scr.xres && ~isnan(y) && y>0 && y<scr.yres;
            
            %if this is the start of a gaze landing within window, then
            %mark it as such
            if ~lndStarted && lnd
                lndStarted = true;
                lndStartT = GetSecs;
                %if the gaze had already landed before, check how long it has
                %been. If its been long enough, then say landed=true;
            elseif lndStarted && lnd
                lndDur = GetSecs - lndStartT;
                if lndDur>task.minLandingTime
                    landed = true;
                    if ~dotsAppeared
                        
                    end
                end
                %else then landing hasnt started
            elseif ~lnd
                lndStarted = false;
            end
            
            %check if its been too long since pre-cue onset and eyes havent
            %landed yet
            if ~landed 
                timePassed = (GetSecs - segStartTs(task.preCueSegmentI));
                if timePassed>task.maxSaccadeTime
                    tooSlowSaccade = true;
                    
                    tSaccTimeout = GetSecs;
                    if task.EYE>0, Eyelink('message', 'EVENT_saccadeTimeout'); end
                    
                    %Abort trial
                    doStimLoop = false;
                    ts.durations(segment) = t;

                end
            end
            
        end
    end
    
    %% Check for keypress
    if ts.checkResp(segment) && ~tooSlowSaccade && ~fixBreak
        [keyPressed, tKey] = checkTarPress(task.buttons.resp);
        
        
        %determine whether this was the correct response given task events (and
        %this was the first time keypress detected
        if keyPressed>0 && ~thisSegKeyPressed %only record first keypress
            
            chosenRes = keyPressed;
            if keyPressed ~= task.buttons.quit
                %only accept key press for the correct side
                if task.buttons.side(keyPressed) == td.targetSide
                    
                    tRes = tKey;
                    respCorrect = task.buttons.reportedCategory(keyPressed) == td.targetCategory;
                    thisSegKeyPressed = true;
                    endSegment = task.selfPaced;
                    
                else
                    endSegment = false;
                    pressedWrongSide = true;
                end
                %else do nothing
            else %subject pressed quit key
                nPressedQuit = nPressedQuit + 1;
                endSegment = task.selfPaced && (nPressedQuit>1); %end if they press quite twice
            end
            
            %if one of the correct keys was pressed, set duration of this segment so that it ends immediately
            if endSegment
                ts.durations(segment) = t;
            end
        end
    end
    
    %Check if it's time to  break out of this stimulus presentation loop
    %if in the last segment, and its duration is within 1 frame of being over
    if segment == ts.nSegments || sum(ts.durations((segment+1):end))==0
        %doStimLoop becomes false if this is the last segment (with
        %duration>0) and we've reached teh ened of the current segment
        %also abort if user pressed q button twice
        doStimLoop = (GetSecs-segStartTs(segment)) < (ts.durations(segment)-scr.fd) && nPressedQuit < 2;
    end
end

if task.EYE>0
    Eyelink('message', 'Block %d Trial_END %d', td.blockNum, td.trialNum);
end

if (fixBreak || tooSlowSaccade) && ~task.MRI %feeback about fixation break
    
    playPTB_DataPixxSound(5, task);
    
    if fixBreak
        if task.EYE==1, Eyelink('command','draw_text 100 100 15 Fixation break'); end
        errorText = 'Fixation break';
    elseif tooSlowSaccade
        if task.EYE==1, Eyelink('command','draw_text 100 100 15 Fixation break'); end
        errorText = 'Too slow';
    end
    Screen('TextSize',scr.main,task.instructTextSize);
    ptbDrawText(scr,errorText, dva2scrPx(scr, 0, 1),task.textColor);
    
    continueText = 'Press the Enter key to continue, or ''r'' to recalibrate, or Esc to quit experiment.';
    returnKeys = KbName('Return');
    %if length(returnKeys)>1
    %    returnKeys = returnKeys(2);
    %end
    continueKeys = [returnKeys KbName('r') KbName('Escape')];
    espKey = find(continueKeys==KbName('Escape'));
    recalibKey = find(continueKeys==KbName('r'));
    
    ptbDrawText(scr,continueText, dva2scrPx(scr, 0, -1),task.textColor);
    
    Screen(scr.main,'DrawingFinished'); Screen('Flip', scr.main);
    
    %Wait to get a key
    resumeKeyPressed = false;
    while ~resumeKeyPressed
        WaitSecs(0.1);
        FlushEvents('KeyDown');

        [rKeyPressed] = checkTarPress(continueKeys);

        if rKeyPressed == espKey
            nPressedQuit = nPressedQuit+1;
            if nPressedQuit>1, resumeKeyPressed = true; end
            quitAfterFixBreak = true;
        elseif any(rKeyPressed>0) && ~isempty(rKeyPressed)
            resumeKeyPressed = true;
        end
                
      
    end
    
    %Recalibrate if asked
    if rKeyPressed==recalibKey  && task.EYE>0
        Eyelink('stoprecording');
        calibrateEyelink(el,task,scr);
        Eyelink('startrecording');	% start recording
    end
    
    %then draw fixation and wait a bit
    drawFixation_PWA(task,scr,fixPos);
    Screen(scr.main,'DrawingFinished'); Screen('Flip', scr.main);
    
    WaitSecs(2/3);
    trialDone = false;
elseif nPressedQuit<2
    %% play feedback here
    WaitSecs(task.durations.delayBeforeFeedback);
    
    %re-draw the fixation mark to delete the post-cue
    drawFixation_PWA(task,scr,fixPos);
    Screen(scr.main,'DrawingFinished');
    Screen('Flip', scr.main);
    
    
    %Now give feedback for both responses
    if task.feedback
        for rsi = find(~isnan(respCorrect))
            tFeedback(rsi) = playPTB_DataPixxSound(2+~respCorrect(rsi), task);
            
        end
    end
    
    trialDone = true;
    
else %user quit by pressing esc twice
    trialDone = false;
end

%% ITI
trialRes.tITIOns = GetSecs;
WaitSecs(task.durations.ITI);
trialRes.tITIOff = GetSecs;

%% save data

%save onset times of each segment
for segI = 1:ts.nSegments
    eval(sprintf('trialRes.t%sOns = segStartTs(%i) - tTrialStart;',ts.segmentNames{segI},segI));
end

trialRes.tTrialStart = tTrialStart;
trialRes.tMovementStart = tMovementStart - tTrialStart;
trialRes.tLanded        = lndStartT - tTrialStart;
trialRes.tSaccTimeout   = tSaccTimeout - tTrialStart;
trialRes.tRes = tRes - tTrialStart;
trialRes.tFeedback = tFeedback(1) - tTrialStart;
trialRes.fixBreak = 1*fixBreak; %convert from logical to to double
trialRes.saccadeLanded=  1*landed;
trialRes.saccadeTimeout = 1*tooSlowSaccade;
trialRes.nFixBreakSegs = nFixBreaks;
trialRes.tFixBreak = tFixBreak - tTrialStart;
trialRes.userQuit = 1*(nPressedQuit>1);
trialRes.chosenRes = chosenRes;
trialRes.respCorrect = 1*respCorrect;
trialRes.trialDone = trialDone && ~trialRes.userQuit;

%did the subject not respond in time?
trialRes.responseTimeout = trialDone & all(isnan(respCorrect));
%save if subject pressed key with wrong hand
trialRes.pressedWrongSide = pressedWrongSide;



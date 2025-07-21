%% function D = PWA_ComputeEyeData(D,blockEDF,scr)
%
% Loads and analyzes eye D from EDF files for 1 block of the PWA experiment. Returns statistics on
% gaze position and fixation breaks within each trial
%
% Inputs:
% - behavDat: a structure containing D about stimulus and subject's
% responses from each trial of the scan, pulled from task.D from this
% scan's mat file
% - blockEDF: character string, full address of corresponding EDF file to
% be loaded in. If there is no such edf file, input empty string ''
% - scr: structure with important parameters about screen and eye analysis
% parameters:
%         scr.maxEyeDev     maximum eye position deviation from drift-corrected central gaze position. Otherwise counts as fixation break [deg]
%         scr.preBlinkCut   amount time before a blink to cut out of eye trace [ms]
%         scr.postBlinkCut  amount time after a blink to cut out of eye trace [ms]
%         scr.DPP           degrees per pixel of the screen
%         scr.scrCen       [x,y] coordinates of screen center [pixels]
%
% Outputs:
% - D: structure containing various statistics for each trial, like
% mean horizontal and vertical gaze positions, offline-detected fixation breaks, etc.
%
% Notes: output variables are NaNs if there is no edf file, or if edf file
% doesn't have matching trial numbers and cue condition indices.
% Gaze positions are analyzed only for periods of time between
% "blinks", and "blinks" are defined as whenever pupil size is zero, then
% reaching back and forward some number of ms set in scr.preBlinkCut and scr.postBlinkCut
%
% This is currenlty a bit wonky because the eye traces on each dual-task
% trial are computed *twice*, because each dual-task trial has 2 entries in
% behavDat (one for 1st response, one for 2nd response)
%
%

function D = PWA_ComputeEyeData(D,blockEDF,scr, task)

doPlot = false;

coordinateFrame = 'deg';

ip  = PWA_EyeAnalysisParams;

timeMessages  = {'Trial_Start_Condition'  , 'EVENT_fixationOnset', 'EVENT_preCueOnset', 'EVENT_stimuliOnset', 'EVENT_stimDotsISIOnset', 'EVENT_dotsPostcueISIOnset', 'EVENT_postCueOnset','Trial_END'};
timestampVars = {'edfTStart',               'edfTFixOn',           'edfTPrecueOn',        'edfTStimOn',      'edfTStimOff',              'edfTDotsOn',               'edfTPostcueOn','edfTEnd'};


nts = length(D.trialNum);

D.edfTrialNum            = NaN(nts,1);
D.edfBlockNum            = NaN(nts,1);
D.edfMatchesMat          = false(nts,1);
D.matCueCond             = NaN(nts,1);
D.edfFixBreak            = NaN(nts,1);
D.edfTFixBreak           = NaN(nts,1);
D.onlineFixBreak         = NaN(nts,1);

%pre-initialize each timestamp with NaNs
nTimeStamps  = numel(timeMessages);
for tsi = 1:nTimeStamps
    thisVar = timestampVars{tsi};
    eval(sprintf('D.%s = NaN(nts,1);', thisVar));
end

D.nSaccades              = NaN(nts,1);
D.saccVelThresh          = NaN(nts,2);
D.nTargetSaccades        = NaN(nts,1);
D.saccLatency            = NaN(nts,1);
D.saccStartTime          = NaN(nts,1);
D.saccLandTime           = NaN(nts,1);
D.saccDur                = NaN(nts,1);
D.saccPeakVel            = NaN(nts,1);
D.saccStartX             = NaN(nts,1);
D.saccStartY             = NaN(nts,1);
D.saccDX                 = NaN(nts,1);
D.saccDY                 = NaN(nts,1);
D.saccEndX               = NaN(nts,1);
D.saccEndY               = NaN(nts,1);
D.saccAmp                = NaN(nts,1);
D.saccErrorX             = NaN(nts,1);
D.saccErrorY             = NaN(nts,1);
D.saccError              = NaN(nts,1);
D.offlineFixBreak        = false(nts,1);

%load in eye D
if ~isempty(blockEDF)
    try
        edf = Edf2Mat(blockEDF);
        goodEDF = true;
    catch
        fprintf(1,'\n\nWARNING: Failed to open edf file %s\n', blockEDF((end-26):end));
        goodEDF = false;
    end
else
    goodEDF = false;
end

if goodEDF
    msgs = edf.Events.Messages.info;
    msgTimes = edf.Events.Messages.time;

    %time stamp for each measurement:
    time = edf.Samples.time;

    %pull out gaze positions: in pixels, rounded to integers
    posX = round(edf.Samples.posX);
    posY = round(edf.Samples.posY);

    %convert to degrees, relative to screen center (cartesian coordinates)
    if strcmp(coordinateFrame, 'deg')
        posX = scr.DPP*(posX-scr.scrCen(1));
        posY  = scr.DPP*-(posY-scr.scrCen(2));
    end

    %auto-detected saccades
    edfSaccStarts = edf.Events.Esacc.start;
    edfSaccEnds = edf.Events.Esacc.end;

    edfSaccPosX1 = edf.Events.Esacc.posX;
    edfSaccPosY1 = edf.Events.Esacc.posY;
    edfSaccPosX2 = edf.Events.Esacc.posXend;
    edfSaccPosY2 = edf.Events.Esacc.posYend;
    edfSaccPeakVel = edf.Events.Esacc.pvel;

    if strcmp(coordinateFrame, 'deg')
        edfSaccPosX1 = scr.DPP*(edfSaccPosX1-scr.scrCen(1));
        edfSaccPosX2 = scr.DPP*(edfSaccPosX2-scr.scrCen(1));

        edfSaccPosY1  = scr.DPP*-(edfSaccPosY1-scr.scrCen(2));
        edfSaccPosY2  = scr.DPP*-(edfSaccPosY2-scr.scrCen(2));

        edfSaccPeakVel = edfSaccPeakVel*scr.DPP;
    end


    D.hasEDFFile = true(nts,1);


    for ti=1:nts

        %% Find time-stamps and conditions for this trial
        trial = D.trialNum(ti);
        blockNum = D.blockNum(ti);
        cuedSide =     D.cuedSide(ti);


        D.edfTrialNum(ti) = trial;
        D.edfBlockNum(ti) = blockNum;

        trialCond = D.cueCond(ti);
        D.matCueCond(ti) = trialCond;

        msgStart = find(strcmp(msgs,sprintf('TRIALID %i',trial)));

        msgEnd = max(find(strcmp(msgs, sprintf('Block %i Trial_END %i', blockNum, trial))));

        goodTrial = ~isempty(msgStart) & ~isempty(msgEnd);
        if goodTrial, goodTrial  = msgEnd>msgStart; end

        if goodTrial
            trialMsgs =  msgs(msgStart:msgEnd);
            trialMsgTimes = msgTimes(msgStart:msgEnd);

            %% Loop through all timestamps and save them in D
            for tsi = 1:nTimeStamps
                thisMsg = timeMessages{tsi};
                thisVar = timestampVars{tsi};

                %for TRIALID and Trial_END, they need the trial number
                %inserted
                if strcmp(thisMsg, 'Trial_Start_Condition')
                    thisMsg = sprintf('Trial_Start_Condition %d', cuedSide);
                elseif strcmp(thisMsg, 'Trial_END')
                    thisMsg = sprintf('Block %i Trial_END %i', blockNum, trial);
                end

                %find the LAST matching message. This is useful for some
                %like ReadyKeyPress which the subject may have had to try
                %several times
                timeI = find(strcmp(trialMsgs, thisMsg),1,'last');
                if ~isempty(timeI)
                    eval(sprintf('D.%s(ti) = trialMsgTimes(timeI);', thisVar));
                elseif D.trialDone(ti)
                    goodTrial = false;
                    fprintf(1, '\n(%s) Warning! No %s time stored in EDF D for trial %i!\n', mfilename, thisMsg, trial);
                    keyboard
                end
            end

            D.edfFixBreak(ti) = any(strcmp(trialMsgs,'EVENT_fixationBreak'));
            if any(strcmp(trialMsgs,'EVENT_fixationBreak'))
                fixBrkI = find(strcmp(trialMsgs,'EVENT_fixationBreak'));
                fixBrkI = fixBrkI(1);
                D.edfTFixBreak(ti) = trialMsgTimes(fixBrkI);
                D.onlineFixBreak(ti) = true;
            else
                D.onlineFixBreak(ti) = false;
            end

        end

        try
            D.edfMatchesMat(ti) = goodTrial;
        catch
            keyboard
        end
    end
    %% Pull eye D within first part of trial, before pre-cue, to compute median gaze positions, excluding blinks
    %because gaze position x and y are NaN during blanks, when pupil size is 0
    %exclude trials with fixation breaks
    startFixPos = NaN(nts,2);
    goodStarts = false(nts,1);
    sampleRates = NaN(nts,1);
    dTs = NaN(nts,1);
    adaptiveVelThreshs = NaN(nts,2);
    D.startFixPos = NaN(nts,2);
    for ti=1:nts
        if goodTrial && ~D.onlineFixBreak(ti)

            %compute sample rate across whole trial
            time1 = D.edfTStart(ti);
            time2 = D.edfTEnd(ti);
            inTime = time>=time1 & time<time2;
            trialTimes = time(inTime);

            %gaze positions:
            trialX = posX(inTime);
            trialY = posY(inTime);

            %compute eyelink sample rate (Hz)
            sampleRates(ti) = round(1000/mean(diff(trialTimes)));
            %compute time between samples
            dT = mean(diff(trialTimes));
            dTs(ti) = round(1000*dT)/1000;

            %% calculate velocity thresholds for saccade
            %determine when there were blinks
            [~, ~, goodTimes, blinkCutTimes, noBlinkIntervals] = computeGazePosAndBlinks(time1, time2, edf);
            nNoBlinkInts = size(noBlinkIntervals,1);

            velThreshs = NaN(nNoBlinkInts,2);
            for goodInt = 1:nNoBlinkInts
                intervalStartT = noBlinkIntervals(goodInt, 1);
                intervalEndT   = noBlinkIntervals(goodInt,2);

                if (intervalEndT-intervalStartT)>50
                    intervalInTime = trialTimes>=intervalStartT & trialTimes<intervalEndT;

                    %compute velocities
                    postns = [trialX(intervalInTime) trialY(intervalInTime)];
                    velcts   = vecvel(postns, sampleRates(ti), ip.VELTYPE);

                    %compute velocity threshold . Only for "goodTimes", which excludes intervals with blinks
                    velThreshs(goodInt,:) = computeSaccadeVelocityThreshold(velcts, ip.velThreshSDs);
                else
                    fprintf(1,'Not using interval of %i ms to calculate sacacde velocity thresh\n', intervalEndT-intervalStartT)
                end
            end
            %the average over these intervals
            adaptiveVelThreshs(ti,:) = median(velThreshs,1,'omitnan');

            %% compute median gaze position in first fixation interval
            %start time: TStart (which is in runSingleTrial)
            time1 = D.edfTFixOn(ti);
            time2 = D.edfTPrecueOn(ti);
            [medPos, ~, ~, ~, ~, pDataRemainAfterBlinkCut] = computeGazePosAndBlinks(time1, time2, edf);
            if pDataRemainAfterBlinkCut>0.7
                %convert to det
                medPos(1) = scr.DPP*(medPos(1)-scr.scrCen(1));
                medPos(2)  = scr.DPP*-(medPos(2)-scr.scrCen(2));

                D.startFixPos(ti,:) = medPos;
                goodStarts(ti) = true;
            end
        end
    end
    meanInitialFixPos = mean(D.startFixPos(goodStarts,:));
    adaptiveVelThresh = median(adaptiveVelThreshs,1,'omitnan');

    sampleRate = mean(sampleRates,'omitnan');
    dT  = mean(dTs,'omitnan');

    %minimum saccade duration, in *samples*
    minSamples = ip.minSaccDur*sampleRate/1000;

    %merge interval for sucesssive saccades, in *samples*
    mergeInt = ip.saccMergeInt*sampleRate/1000;



    %% find saccades on cued trials
    try
        cuedTrials = find(D.cueCond>0 & D.trialDone==1);
    catch
        keyboard
    end
       


    for ti=cuedTrials'
        time1 = D.edfTPrecueOn(ti);
        time2 = D.edfTPostcueOn(ti);

        inTime = time>=time1 & time<time2;
        trialTimes = time(inTime);


        %gaze positions:
        %in pixels, relative to upper left
        trlXPos = posX(inTime);
        trlYPos = posY(inTime);

        %CORRECT FOR DRIFT, BASED ON MEDIAN FIXATIONS AT TRIAL STARTS?
        trlXPos = trlXPos - meanInitialFixPos(1);
        trlYPos = trlYPos - meanInitialFixPos(2);

        postns = [trlXPos trlYPos];
        velcts   = vecvel(postns, sampleRate, ip.VELTYPE);
        %Detect saccades (merging successsive events less than mergeInt apart)
        saccs = detectSaccades(postns, velcts, adaptiveVelThresh, minSamples, mergeInt);
        D.nSaccades(ti) = size(saccs,1);
        D.saccVelThresh(ti,:) = adaptiveVelThresh;

        fixPos = [0 0]; %assume central fixation at first
        if ~isempty(saccs)
            %first excludes saccades that are too small or too big
            saccs = saccs(saccs.amp>=ip.minSaccAmp & saccs.amp<=ip.maxSaccAmp, :);

            %set onset and offset times to be "absolute", relative to
            %the clock time in edf.samples.time
            saccs.onsetTime  = trialTimes(saccs.onsetSample);
            saccs.offsetTime = trialTimes(saccs.offsetSample);

            %did it start at fixation?
            saccs.startAtFix = (abs(saccs.startX-fixPos(1)) < task.fixCheckRad(1)) & abs(saccs.startY-fixPos(2)<task.fixCheckRad(2));

            %how far did the saccade end up relative to target location?
            saccs.endErrorX = saccs.endX - task.saccadeTargets.xDeg(D.cuedSide(ti));
            saccs.endErrorY = saccs.endY - task.saccadeTargets.yDeg(D.cuedSide(ti));
            saccs.endError = ((saccs.endErrorX.^2) + (saccs.endErrorY.^2)).^0.5;

            %did each saccade end at the target for this trial? Use the
            %same criteria as live during the experiment
            saccs.endAtTarget = abs(saccs.endErrorX)<task.landingCheckRad(1) & abs(saccs.endErrorY)<task.landingCheckRad(2);

            theSaccadeI = find(saccs.startAtFix & saccs.endAtTarget);
            D.nTargetSaccades(ti) = length(theSaccadeI);

            if D.nTargetSaccades(ti)>1
                keyboard
            elseif D.nTargetSaccades(ti)==1
                theSacc = saccs(theSaccadeI,:);
                D.saccLatency(ti) = theSacc.onsetTime - D.edfTPrecueOn(ti);
                D.saccStartTime(ti) = theSacc.onsetTime;
                D.saccLandTime(ti) = theSacc.offsetTime;
                D.saccDur(ti) = theSacc.offsetTime - theSacc.onsetTime+1;
                D.saccPeakVel(ti) = theSacc.peakVelocity;
                D.saccStartX(ti) = theSacc.startX;
                D.saccStartY(ti) = theSacc.startY;
                D.saccDX(ti) = theSacc.dx;
                D.saccDY(ti) = theSacc.dy;
                D.saccEndX(ti) = theSacc.endX;
                D.saccEndY(ti) = theSacc.endY;
                D.saccAmp(ti) = theSacc.amp;
                D.saccErrorX(ti) = theSacc.endErrorX;
                D.saccErrorY(ti) = theSacc.endErrorY;
                D.saccError(ti) = theSacc.endError;
            else
                fprintf(1,'\nTrial %i no good saccades found!\n', ti)

            end

        else
            D.nTargetSaccades(ti) = 0;
        end


    end
else
    D.hasEDFFile = false(nts,1);
end


 %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing the eye data
% Mariam Latif
% June 2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; 

%% Pathing
% Paths (from Mariam's Desktop)
rootEdfPath = '/Users/mariamlatif/Desktop/VisionLab/PWA/edf_mat/';
rootDataPath = '/Users/mariamlatif/Desktop/VisionLab/PWA/data/';

% paths.proj = fileparts(fileparts(which('PWA_AllAnalysis.m')));
% paths.analysis = fullfile(paths.proj,'analysis');
% rootDataPath = fullfile(paths.proj,'data');
% rootEdfPath = fullfile(paths.proj,'edf_mat');
% paths.results = fullfile(paths.proj,'results');


% Directories
edfDirs = dir(rootEdfPath);
edfDirs = edfDirs([edfDirs.isdir] & ~startsWith({edfDirs.name}, '.'));

%% Looping through
for p = 1:length(edfDirs)
    participantID = edfDirs(p).name;  % redcap participant ID #

    edfPath = fullfile(rootEdfPath, participantID);
    edfFiles = dir(fullfile(edfPath, sprintf('%s_edf*.mat', participantID)));

    % Data path (date-named subfolder)
    dataPath = fullfile(rootDataPath, participantID);
    if ~isfolder(dataPath)
        warning('Data path not found for participant %s', participantID);
        continue
    end

    % Subfolders
    dateSubDirs = dir(dataPath);
    dateSubDirs = dateSubDirs([dateSubDirs.isdir] & ~startsWith({dateSubDirs.name}, '.'));

    for d = 1:length(dateSubDirs)
        dateFolder = dateSubDirs(d).name;
        fullDataPath = fullfile(dataPath, dateFolder);
        dataFiles = dir(fullfile(fullDataPath, sprintf('%s_*.mat', participantID)));

        % Loop over pairs
        for e = 1:length(edfFiles)
            edfFile = fullfile(edfPath, edfFiles(e).name);
            try
                load(edfFile, 'edfData');
            catch
                warning('Failed to load %s', edfFile);
                continue;
            end

            for b = 1:length(dataFiles)
                dataFile = fullfile(fullDataPath, dataFiles(b).name);
                data = load(dataFile);

                if ~isfield(data, 'scr') || ~isfield(data.scr, 'ppd')
                    warning('scr or scr.ppd missing in %s. Skipping.', dataFile);
                    continue;
                end
                if ~isfield(data, 'task')
                    warning('task missing in %s. Skipping.', dataFile);
                    continue;
                end

                scr = data.scr;
                task = data.task;
                % Check!
                fprintf('Processing: %s & %s\n', edfFiles(e).name, dataFiles(b).name);

                %% Processing saccade data
                % Gaze position to unit of degree conversion

                xPos = edfData.Samples.posX;
                yPos = edfData.Samples.posY;
                time = edfData.Samples.time;
                
                degPerPx = 1/scr.ppd  % reciprocal of pixels per degree, also saved in the scr structure
                xPosDeg = degPerPx * (xPos- scr.centerX);
                yPosDeg  = degPerPx * -1*(yPos-scr.centerY);
                
                % Looking at messages
                messages = edfData.Events.Messages.info;
                messageTimes = edfData.Events.Messages.time;
                
                trialStart = find(contains(messages, 'Trial_START'));
                trialEnd = find(contains(messages, 'Trial_END'));
                
                preCueIdx = find(strcmp(messages, 'EVENT_preCueOnset'));
                %stimDotsIdx = find(strcmp(messages, 'EVENT_stimDotsISIOnset'));
                postCueIdx = find(strcmp(messages, 'EVENT_postCueOnset'));
                
                %% Testing for a single trial:
                goodTrials = find(task.trials.trialDone);
                task.trials.isGoodTrial = false(height(task.trials), 1);
                for g= 1:length(goodTrials)
                    ti=goodTrials(g);
                    if g > length(preCueIdx)|| g> length(postCueIdx)||g>length(trialStart)||g>length(trialEnd)
                        warning('Skipping trial %d (g=%d): not enough messages.',ti,g);
                        continue;
                    end
                    preCueTime=messageTimes(preCueIdx(g));
                    postCueTime=messageTimes(postCueIdx(g));
                    startTime=messageTimes(trialStart(g));
                    endTime=messageTimes(trialEnd(g));
                % for ti=goodTrials'
                % 
                %     % Parsing to one trial
                %     startTime = messageTimes(trialStart(ti));
                %     endTime   = messageTimes(trialEnd(ti));
                    trialSampleIdx = time >= startTime & time <= endTime;
                
                    % Gaze data for that trial in degrees
                    trialX = xPosDeg(trialSampleIdx);
                    trialY = yPosDeg(trialSampleIdx);
                    trialT = time(trialSampleIdx);
                
                    % Segmenting a trial
                
                    % preCueTime = messageTimes(preCueIdx(ti));
                    % %stimDotsTime = messageTimes(stimDotsIdx(ti));
                    % postCueTime = messageTimes(postCueIdx(ti))
                    % Segment within the trial
                    %segmentIdx = time >= preCueTime & time <= stimDotsTime;
                    segmentIdx = time >= preCueTime & time <= postCueTime;
                    segmentX = xPosDeg(segmentIdx);
                    segmentY = yPosDeg(segmentIdx);
                    segmentT = time(segmentIdx);
               
                    %timestamps for this part of this trial
                    trialTimes = time(trialStart:trialEnd);
                    %trialTimes = edf.Events.Messages.time(startIndex:endIndex);
                
                    %compute eyelink sample rate (Hz)
                    sampleRate = round(1000/mean(diff(trialTimes)));
                
                    %minimum saccade duration, in *samples*
                    minSaccDur = 10; % ms, minSaccDur is the minimum acceptable saccade duration, maybe 10 ms
                    minSamples = minSaccDur*sampleRate/1000;
                
                    % make a 2-column vector of gaze positions
                    postns = [trialX trialY];
                
                    % calculate gaze velocities
                    velcts   = vecvel(postns, sampleRate, 1);
                
                    %Detect saccades (merging successsive events less than mergeInt apart)
                    velThresh = [20 20]; % 20/s degrees, velThresh is a velocity threshold, which to start you could set to something like 20 deg/s
                    mergeInt = 10; % 10 ms - check!
                    saccs = detectSaccades(postns, velcts, velThresh, minSamples, mergeInt)
                    %disp(saccs)
               
                    %% Find the "good" saccade
                    % use info in task.saccadeTargets.xDeg and yDeg which are the
                    % coordinates for the 2 saccade targets
                    % task.trials is the data table. "targetSide" is 1 for left, 2 for
                    % right. 
                    %for trial ti, the x- coordinate of where the eye should go
                    %was: 
                    % task.saccadeTargets.xDeg(task.trials.cuedSide(ti)) 
                    % task.saccadeTa
                    %other useful variables in task.trials: 
                    % - cuedSide: 1 (left), 2 (right) or 0 (neutral)
                    % - fixBreak: 1 if the eyetracker detected a fixation break online,
                    % which means trials wasnt completed
                    % - trialDone: 1 if the trial was successfully completed 
                    
                    % skipping the neutral condition
                    if task.trials.cuedSide(ti)==0
                        warning ('Trial %d is neutral cue. Skipping good saccade selection.', ti);
                        continue;
                    end

                    %finding the cued position
                    cuedSide = task.trials.cuedSide(ti);  % 1 or 2
                    targetX = task.saccadeTargets.xDeg(cuedSide);
                    targetY = task.saccadeTargets.yDeg(cuedSide);

                    %skipping trials with no saccades detected
                    if isempty(saccs)
                        warning('No saccades detected in trial %d. Skipping.', ti);
                        continue;
                    end

                    %computing starting and endpoint
                    saccEndX= saccs.endX;
                    saccEndY = saccs.endY;
                    distsToTarget = sqrt((saccEndX - targetX).^2 + (saccEndY - targetY).^2);

                    saccStartX = saccs.startX;
                    saccStartY = saccs.startY;
                    distsToCenter = sqrt(saccStartX.^2 + saccStartY.^2);

                    %checking for saccades within 1 deg of fixation for
                    %start & within 1 deg of target for end
                    validIdx = (distsToCenter <= 1) & (distsToTarget <= 1);

                    validSaccs = saccs(validIdx, :);
                    validDistsToCenter = distsToCenter(validIdx);
                    validDistsToTarget = distsToTarget(validIdx);
                    numValidSaccades = height(validSaccs);

                    %noting how many valid saccades there are (should be only 1!)
                    fprintf('Number of valid saccades: %d\n', numValidSaccades);

                    % choosing the saccade with the smallest distance to the cued target
                    %bestSaccade = distToCenter + distsToTarget;
                    %[~, bestIdx] = min(bestSaccade);

                    % picking the 'best valid saccade'
                    if numValidSaccades > 0
                        totalDistance = validDistsToCenter + validDistsToTarget;
                        [~, bestIdx] = min(totalDistance);
                        goodSaccade = validSaccs(bestIdx, :);
                    else
                        %no valid saccade found
                        goodSaccade = [];
                        warning('No saccades found within 1° radius of both (0,0) and the target.');
                    end

                    if isempty(goodSaccade)
                        continue; 
                    end
                    task.trials.isGoodTrial(ti) = true;
                    
                    %extracing the 'good' saccade
                    %goodSaccade = saccs(bestIdx, :);
                    %goodSaccade = saccs(bestIdx);

                    %plotting
                    figure(1); clf;
                    hold on;
                    axis equal;
                    xlabel('X Position (deg)');
                    ylabel('Y Position (deg)');
                    title(sprintf('Trial %d: Good Saccade', ti));
                    hold on;
                    plot(trialX, trialY, 'k-'); % Plot full trial gaze in black
                    hold on;
                    %plot([goodSaccade.startX goodSaccade.endX], ...
                        %[goodSaccade.startY goodSaccade.endY], ...
                        %'m-', 'LineWidth', 1);
                    saccadeIndices = goodSaccade.onsetSample(1):goodSaccade.offsetSample(1);
                    plot(trialX(saccadeIndices), trialY(saccadeIndices), 'm-', 'LineWidth', 1);
                    hold on;
                    % plotting a marker at the start point 
                    plot(goodSaccade.startX(1), goodSaccade.startY(1), 'o', 'MarkerFaceColor', 'green', 'MarkerSize', 3);
                    % plotting a marker at the end point 
                    plot(goodSaccade.endX(end), goodSaccade.endY(end), 'o', 'MarkerFaceColor', 'blue', 'MarkerSize', 3);
                    %scatter(goodSaccade.endX, goodSaccade.endY, 100, 'm', 'filled');
                    %ylim([-3 3]);
                    xlim([-4 4]);
                    xline(0)
                    hold on;
                    yline(0)
                    axis equal;
                    hold off;
                    break;
                end
            end
        end
    end
end
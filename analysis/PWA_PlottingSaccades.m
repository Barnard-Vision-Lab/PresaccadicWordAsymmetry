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
                for ti=goodTrials'
                
                    % Parsing to one trial
                    startTime = messageTimes(trialStart(ti));
                    endTime   = messageTimes(trialEnd(ti));
                    trialSampleIdx = time >= startTime & time <= endTime;
                
                    % Gaze data for that trial in degrees
                    trialX = xPosDeg(trialSampleIdx);
                    trialY = yPosDeg(trialSampleIdx);
                    trialT = time(trialSampleIdx);
                
                    % Segmenting a trial
                
                    preCueTime = messageTimes(preCueIdx(ti));
                    %stimDotsTime = messageTimes(stimDotsIdx(ti));
                    postCueTime = messageTimes(postCueIdx(ti))
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
                    
                
                    %%
                    % All gaze positions
                    figure(1); clf; %clear figure 1
                    legend();
                    plot(trialX, trialY, 'k-'); % Plot full trial gaze in black
                    hold on;
                    plot(segmentX, segmentY, 'r-'); % Plot full segment gaze in red
                    hold on; 
                
                    for i = 1:height(saccs)
                        sX = saccs.startX(i);
                        sY = saccs.startY(i);
                        eX = saccs.endX(i);
                        eY = saccs.endY(i);
                
                        scatter([sX eX], [sY eY], 50,'g', 'filled');
                        plot([sX eX], [sY eY], 'b-');
                    end
                    hold on;
                    ylim([-5 5])
                    xlim([-6 6])
                    xlabel('X Position (deg)');
                    ylabel('Y Position (deg)');
                    title('Detected Saccades');
                    xline(0)
                    hold on;
                    yline(0)
                    axis equal;
                    hold off;
                
                    %pause
                end
            end
        end
    end
end
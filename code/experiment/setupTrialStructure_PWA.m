function task = setupTrialStructure_PWA(task)

%setup segments
segmentNames = task.trialSegments;
nSegments = numel(segmentNames);
checkEye = true(1,nSegments); %whether to check for fixation breaks; 
checkResp = false(1,nSegments); %whether to check for manual response; only during response interval
doMovie = false(1,nSegments); %in case some segments are 'movies' that need updating every frame

task.stimSegmentI = find(strcmp(segmentNames,'stimuli'));
task.responseSegmentI = find(strcmp(segmentNames, 'postCue'));

%set durations
durations = zeros(1,nSegments);
for segI = 1:nSegments
    eval(sprintf('durations(segI) = task.durations.%s;',segmentNames{segI}));
end

%set checkEye to false in segments we dont want 
checkEye(task.responseSegmentI) = 0;

%set checkResp to true when we want to be checking for a response 
checkResp(task.responseSegmentI) = 1;

%if self-paced version, set response interval duration to inf
if task.selfPaced
    durations(task.responseSegmentI) = inf;
end

trialStruct.nSegments      = nSegments;
trialStruct.segmentNames   = segmentNames;
trialStruct.checkEye       = checkEye;
trialStruct.checkResp      = checkResp;
trialStruct.doMovie        = doMovie;
trialStruct.durations      = durations;

task.trialStruct = trialStruct;

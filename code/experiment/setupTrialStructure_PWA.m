function task = setupTrialStructure_PWA(task)

%setup segments
segmentNames        = task.trialSegments;
nSegments           = numel(segmentNames);
doMovie             = false(1,nSegments); %in case some segments are 'movies' that need updating every frame

task.stimSegmentI = find(strcmp(segmentNames,'stimuli'));
task.stimOffsetSegmentI = task.stimSegmentI+1;
task.stimOffsetSegment = segmentNames{task.stimOffsetSegmentI};
task.responseSegmentI = find(strcmp(segmentNames, 'postCue'));
task.preCueSegmentI = find(strcmp(segmentNames, 'preCue'));

%set durations
durations = zeros(1,nSegments);
for segI = 1:nSegments
    eval(sprintf('durations(segI) = task.durations.%s;',segmentNames{segI}));
end

%set checkEye to false in segments we dont want 
checkEye = true(1,nSegments); %whether to check gaze position... either check centerFix or check saccade
checkEye(task.responseSegmentI) = false;

%set checkCentralFix: depends on whether its a saccade or fixation trial
%for saccade trials, true only in initial fixation interval
checkCentralFix_SaccTrls = false(1,nSegments);
checkCentralFix_SaccTrls(strcmp(segmentNames, 'fixation')) = true;

%for no-saccade fixation trials, true only in initial fixation interval
checkCentralFix_FixnTrls = true(1,nSegments);
checkCentralFix_FixnTrls(task.responseSegmentI) = false;


%set checkSaccadeLanding: depends on whether its a saccade or fixation
%trial
%for saccade trials, checkSaccadeLanding is true in all but fixation
%segment, and response (postcue) segment 
checkSaccadeLanding_SaccTrls = true(1,nSegments);
checkSaccadeLanding_SaccTrls(strcmp(segmentNames, 'fixation')) = false;
checkSaccadeLanding_SaccTrls(task.responseSegmentI) = false;

%for fixation trials, its always false
checkSaccadeLanding_FixtTrls = false(1, nSegments);

%set checkResp to true when we want to be checking for a response 
checkResp  = false(1,nSegments); %whether to check for manual response; only during response interval
checkResp(task.responseSegmentI) = 1;

%if self-paced version, set response interval duration to inf
if task.selfPaced
    durations(task.responseSegmentI) = inf;
end

trialStruct.nSegments           = nSegments;
trialStruct.segmentNames        = segmentNames;
trialStruct.checkEye            = checkEye;
trialStruct.checkCentralFix_SaccTrls     = checkCentralFix_SaccTrls;
trialStruct.checkCentralFix_FixnTrls     = checkCentralFix_FixnTrls;
trialStruct.checkSaccadeLanding_SaccTrls = checkSaccadeLanding_SaccTrls;
trialStruct.checkSaccadeLanding_FixtTrls = checkSaccadeLanding_FixtTrls;
trialStruct.checkResp           = checkResp;
trialStruct.doMovie             = doMovie;
trialStruct.durations           = durations;

task.trialStruct = trialStruct;

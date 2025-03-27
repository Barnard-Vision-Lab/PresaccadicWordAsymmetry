function params = PWA_Params

%paths
params.paths    = PWA_Paths;

%% Background luminance 
params.bgLum                    = 1; 

%% LETTER STRINGS
params.strings.fontName           = 'Courier New';
params.strings.contrast           = -1;
params.strings.xHeightDeg         = 0.6;
params.strings.antiAlias          = 0;

params.strings.centerEcc          = 2.75;  
params.strings.posPolarAngles     = [180 0]; %left, right
params.strings.posLabels          = {'Left','Right'};


if params.bgLum>0
    params.strings.lum            = params.bgLum + params.strings.contrast*params.bgLum;
else
    params.strings.lum            = 1*params.strings.contrast;
end
params.strings.color               = ones(1,3)*round(params.strings.lum*255);

%STIMULUS SET
params.strings.lengths            = [5 6];
%Load stimulus set from csv file. 
params.strings.listFile = fullfile(params.paths.stimuli,'PosSC.csv');
params.strings.lexicon = readtable(params.strings.listFile);

%filter by lengths
params.strings.lexicon = params.strings.lexicon(ismember(params.strings.lexicon.length, params.strings.lengths), :);

params.strings.lexicon.stringNum = (1:size(params.strings.lexicon, 1))';
params.strings.categories        = flipud(unique(params.strings.lexicon.category)); 
params.strings.nCatg             = numel(params.strings.categories); 
params.strings.nLeng             = length(params.strings.lexicon.length);

params.strings.maskFontName =   'BACS2serif';


%% FIXATION MARK 
params.fixation.ecc              = 0; 
params.fixation.posPolarAngles   = 0; 

%Disc (actually now a ring)
params.fixation.discDiameter     = 0.38; %dva
params.fixation.discColor        = [50 50 50]; 

%Cross
params.fixation.crossWidth      = 2;   %pix 
params.fixation.crossLength     = params.fixation.discDiameter; %dva 
params.fixation.crossColor     = [0 0 0];

%Dot
params.fixation.dotDiameter      = 0.11;  
params.fixation.dotType          = 2; % 0 (default) squares, 1 circles (with anti-aliasing), 2 circles (with high-quality anti-aliasing, if supported by your hardware). If you use dot_type = 1 you'll also need to set a proper blending mode with the Screen('BlendFunction') command!
%dot colors for feedback: 1=base; 2=miss, 3=hit; 4=false alarm, 
params.fixation.dotColor = [255 255 255];

%% SPATIAL CUES

%cueColors:  
hues = [0.33];   
sats = [1];
vals = [0.66]; 

params.cue.color_pre        = round(255*hsv2rgb([hues' sats' vals']));
params.cue.neutralColor     = params.cue.color_pre;
params.cue.color_post       = round(255*hsv2rgb([0.9 1 0.66]));
params.cue.posPolarAngles   = params.strings.posPolarAngles;
params.cue.thick            = 4;
params.cue.length           = 0.16;
params.cue.minEcc           = 0.05; 
params.cue.maxEcc           = params.cue.minEcc+params.cue.length; 

%Whether to get sequential responses to both sides in dual-task
params.dualTaskBothResps = true;

%% markers for saccade endpoints
params.marker.color      = params.cue.color_pre;
params.marker.posPolarAngles = params.strings.posPolarAngles;
params.marker.distH       = 2.75; %absolute value of horizontal distance from screen center
params.marker.distY       = [0.6 1.0]; %absolute value of start and end distances from horizontal midline 
params.marker.thick      = params.cue.thick;
params.marker.length     = abs(diff(params.marker.distY));

%% Eyetracking 
% initlFixCheckRad: 
% if just 1 number, it's the radius of circle in which gaze position must land to start trial. 
% if its a 1x2 vector, then it defines a rectangular region of acceptable
% gaze potiion. 
% Then new fixation position is defined as mean gaze position in small time window at trial start 

params.calibShrink              = 0.5;   %shrinkage of calibration area in vertical dimension (horizontal is adjusted further by aspect ratio to make square
params.squareCalib              = true;  %whether calibration area should be square 
params.horizOnlyFixCheck        = false; %fixation break is defined only by really detected horizontal deviations, 
params.eyelinkSampleRate        = 500;

params.initlFixCheckRad         = [1.5 2];  
params.fixCheckRad              = [1 1.5]; % radius of circle (or dims of rectangle) in which gaze position must remain to avoid fixation breaks. [deg]
params.maxFixCheckTime          = 0.500; % maximum fixation check time before recalibration attempted 
params.minFixTime               = 0.200; % minimum correct fixation time
params.nMeanEyeSamples          = 10;    %number of eyelink samples over which to average gaze position to determine new fixation point 

params.maxSaccadeTime           = 0.500; %[s] max time between pre-cue and eyes landing at target location before trial ends with a beep 
params.minLandingTime           = 0.030; %[s] min time during which gaze has to be within maxLandingError degrees from saccade target 
params.maxLandingError          = 2.5; %[deg] max distance between gaze position and saccade target location to count as success 

%% Number of trials per block:
params.trialsPerBlock           = 25;
params.practiceTrialsPerBlock   = 12;
params.nTrialsLeftRepeatAbort   = 3; 

%% Timing parameters
params.time.startRecordingTime  = 0.100; % time to wait after initializing eyelink recording before continuing 

trialSegs = {'fixation','preCue','stimuli','stimPostcueISI','postCue'};
%NOTE: ITI is not in this list of trialSegs because it is actually done
%separately, after the feedback beeps, outside of the main trial loop. 
params.trialSegments = trialSegs;

params.time.fixation            = 0.500;
params.time.preCue              = 0.100; %[0.050 0.200]; %min max
params.time.stimuli             = 0.075;  
params.time.stimPostcueISI      = 0.050; %lasts until response
params.time.postCue             = inf; 

params.time.demoStimDur         = 0.150;


%add the ITI separately, outside of the main trial loop
params.time.ITI                 = 0.5; % total intertrial duration  

params.time.delayBeforeFeedback = 0.35; %time between last response and first feedback beep 

%To precisely control timing, determine when frame flips are asked for 
params.flipperTriggerFrames = 1.25;  %How many video frames before desired stimulus time should the screen Flip command be executed 
params.flipLeadFrames = 0.5;        %Within the screen Flip command, how many video frames before desired time should flip be asked for 

%Tolerance in rounding off durations to be in multiples of monitor frame
%duration. If rounding up would make an error less than this, round up.
%Otherwise, round down. 
params.durationRoundTolerance = 0.0026; 

%

%% TEXT
params.instructTextFont         = 'Ubuntu Light';
params.textColor                = [0 0 0]; %round([1 1 1]*params.strings.baseLum*255); %for instructions etc
params.textAntialias            = 1; %for everything but the actual stimuli 
params.textSize                 = 22;
params.instructTextSize         = 20; 
%make color for text in initial instructions (same as cue colors but lower
%saturation)
chsv = rgb2hsv(params.cue.color_pre/255);
chsv(:,2) = chsv(:,2)*0.9;
params.instructCueColrs = round(255*hsv2rgb(chsv));

params.doFadeOut   = false;  %whether instructions text fades out

%% Feedback
params.feedback                 = true;
params.blockEndFeedback         = false;

%Feedback Sounds
params.sounds(1).name             = 'responseTone'; 
params.sounds(2).name             = 'correctTone'; 
params.sounds(3).name             = 'incorrectTone';
params.sounds(4).name             = 'targetTone';   
params.sounds(5).name             = 'fixBreakTone'; 

params.sounds(1).toneDur         = 0.025; 
params.sounds(2).toneDur         = 0.100; 
params.sounds(3).toneDur         = 0.100; 
params.sounds(4).toneDur         = 0.033;
params.sounds(5).toneDur         = 0.150; %this is actually 2 incorrect tones concatenated 

params.sounds(1).toneFreq        = 400; 
params.sounds(2).toneFreq        = 600; 
params.sounds(3).toneFreq        = 180; 
params.sounds(4).toneFreq        = 675; 
params.sounds(5).toneFreq        = 180; %this is actually 2 incorrect tones concatenated 

params.soundsOutFreq             = 48000; %output sampling frequency 
params.soundsBlankDur            = 0;  %amount of blank time before sound signal starts 

params.doDataPixx               = false;


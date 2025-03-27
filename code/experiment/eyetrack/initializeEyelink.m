% function [el, status] = initializeEyelink(eyefilename, task, scr)
% by Alex White, March 2015
% based on initEyelink by Martin Rolfs
% integrated with John Palmer's EL routines 
% 
% This function: 
% - creates structure el with default settings
% - changes some settings in el and adds some field 
% - initializes connection to Eyelink machine with function EyelinkInit 
%   (as opposed to Eyelink('initialize'), which seems to determine what
%   kind of calibraiton routine you get). 
% - sends some commands to eyelink to change settings, such as calibration
%   area 
% - Opens edf file with name eyefilename 
% - Prints out some header information to eyefilename 
%
% Inputs: 
% - eyefilename, a character string 
% - task: structure
% - scr: structure 
%
% Outputs: 
% - structure el 
% - status, which is -1 in dummy mode, 0 if no connection, 1 if
%   good connection 
%
% Note: this function will kill the program and close screen if there's an error in
%   establishing connection 
% 
% 12/15/16: scr and task are no longer global variables. 


function [el, status] = initializeEyelink(eyefilename, task, scr)

%on the new eyelin 1000+, the default setting is to not actually apply the
%drift correction. But we can change that here. 
enableTrueDriftCorrect = true; 

%--------------------------------------%
% Initialize el structure with eyelink defaults
%--------------------------------------%

% sets things like calibration target physical parametres 
el=EyelinkInitDefaults(scr.main); 

%--------------------------------------%
% Add some arguments to el structure  
%--------------------------------------%

% specify eye to be used
el.eye = el.RIGHT_EYE;							% use eye code defined by low level routine

% move args into el structure
el.screenRect = scr.rect;
el.pixelsperdegree = scr.ppd;
el.eyefilename = strcat(eyefilename,'.edf');
el.xcenter = scr.centerX;
el.ycenter = scr.centerY; 

%--------------------------------------%
% modify a few of the default settings %
%--------------------------------------%
el.backgroundcolour = scr.bgColor;		% background color when calibrating
el.foregroundcolour = scr.fgColor;        % foreground color when calibrating

%Set sounds: 

el.calibrationfailedsound = 1;				% no sounds indicating success of calibration
el.calibrationsuccesssound = 1;

% define beep sounds (frequency, volume, duration);
%Here I'm lowering the volume 
el.cal_target_beep=[900 0.5 0.05];
el.drift_correction_target_beep=[900 0.5 0.05];
el.calibration_failed_beep=[400 0.6 0.25];
el.calibration_success_beep=[800 0.5 0.25];
el.drift_correction_failed_beep=[400 0.6 0.25];
el.drift_correction_success_beep=[800 0.5 0.25];

%el.drift_correction_target_beep = el.cal_target_beep; %because drift correction causes some crash due to Snd? 

el.helptext='Press RETURN to toggle camera image';
el.helptext=[el.helptext '\n' 'Press C to Calibrate'];
el.helptext=[el.helptext '\n' 'Press V to Validate'];
el.helptext=[el.helptext '\n' 'Press D to Drift Correct only'];
el.helptext=[el.helptext '\n' 'Press ESC to exit and begin experiment'];


EyelinkUpdateDefaults(el);


%--------------------------------------%
% Initialize eye tracker and test if operational
%--------------------------------------%

if ~EyelinkInit(task.EYE~=1)  %if task.EYE>1, then initialize in dummy mode                      % Initialization of Eyelink
    reddUp(true, task, scr); %close connection and screen
    error('ERROR: Bad Eyelink Initialization');
end


%Two crucial difference from Martin Rolfs' old initEyelink: 
% (1) Martin used Eyelink('initialize'), which seems to set things 
% differently than EyelinkInit. 
% Martin's code: 
% if (Eyelink('initialize') ~= 0) %Eyelink('initialize') returns status 0 if ok, -1 if error 
%      Eyelink('initializedummy'); %if there's an error, initialize in dummy mode
% end
% 
% (2) In my code from Martin's lab, there was a separate
% EyelinkDoTrackerSetup function, the one that executes the calibration.
% This seems to be an older version from the one currently sent out with
% PTB. I don't understand all the differences, but the new one uses
% something called el.callbacks. 
%
% It's the combination of these two differences that affects how the
% calibration works. Using EyelinkInit and then calling the newer standared
% EyelinkDoTrackerSetup lets you see the eye image on the stimulus monitor
% when calibrating. 


% JPs code to check again, seems unnecesary here
% if Eyelink('Isconnected') ~= 1, 				% make sure it is connected
% 	error('Error in initializeEyelink:  Eyelink not connected');
% end;

%--------------------------------------%
% Send eyelink commands to change settings: 
%--------------------------------------%
Eyelink('Command', 'clear_screen 0');	% initialize screen on operater PC

Eyelink('Command', 'screen_pixel_coords = %d %d %d %d', ...
	el.screenRect(1),el.screenRect(2),el.screenRect(3)-1,el.screenRect(4)-1);
	
Eyelink('Message', 'DISPLAY_COORDS %d %d %d %d', ...
	el.screenRect(1),el.screenRect(2),el.screenRect(3)-1,el.screenRect(4)-1);

Eyelink('Command', sprintf('active_eye = %i',el.eye+1));	% set eye to record..apparently needs +1
Eyelink('Command', 'binocular_enabled = NO');	
Eyelink('Command', 'head_subsample_rate = 0');	% normal (no anti-reflection)
Eyelink('Command', 'heuristic_filter = 1 1');	% ON for filter (normal)...also possible [1 1]	
Eyelink('Command', 'pupil_size_diameter = NO');	% no for pupil area (yes for dia)
%Eyelink('Command', 'simulate_head_camera = NO');% NO to use head camera

%turn off the disabling of application of drift correction 
if enableTrueDriftCorrect
    Eyelink('Command', 'driftcorrect_cr_disable = OFF');
end

if task.MRI
    %Setting to 5pt calibration for the scanner: 
    Eyelink('Command', 'calibration_type = HV5');
else
    Eyelink('Command', 'calibration_type = HV9');
end
Eyelink('Command', 'enable_automatic_calibration = YES');	% YES default
Eyelink('Command', 'randomize_calibration_order = YES');	% YES default
Eyelink('Command', 'automatic_calibration_pacing = 1000');	% 1000 ms default

Eyelink('Command', 'randomize_calibration_order = YES');% YES default
Eyelink('Command', 'randomize_validation_order = YES');	% YES default

%set sample rate 
Eyelink('command', 'sample_rate = %d', task.eyelinkSampleRate);

%--------------------------------------%
% Set calibraiton area 
%--------------------------------------%
if task.squareCalib
    aspectRatio  = scr.rect(3)/scr.rect(4);
    calibAreaH   = task.calibShrink(1)/aspectRatio; %makes it square
    calibAreaV   = task.calibShrink(1);
else
    calibAreaH   = task.calibShrink(1);
    calibAreaV   = task.calibShrink(2);
end

calibAreaStr = sprintf('calibration_area_proportion = %.3f %.3f',calibAreaH, calibAreaV);
Eyelink('command', calibAreaStr); % shrinking of calibration area


%---------------------------------------%
% Open eyelink edf file %
%---------------------------------------%

i = Eyelink('OpenFile', el.eyefilename);		% open data file on operater PC
if i~=0
    fprintf('Cannot create EDF file ''%s'' ', el.eyefilename);
    Eyelink( 'Shutdown');
    return;
end
Eyelink('Command', 'clear_screen 0');		% initialize screen on operater PC

%---------------------------------------%
% Print to file information on the experiment %
%---------------------------------------%
Eyelink('command', sprintf('add_file_preamble_text ''Recorded with %s by Alex White''',task.codeFilename));

%--------------------------------------------------------%
% write descriptions of the experiment into the edf-file %
%--------------------------------------------------------%
Eyelink('message', 'BEGIN OF DESCRIPTIONS');
Eyelink('message', 'Subject code: %s', el.eyefilename);
Eyelink('message', 'END OF DESCRIPTIONS');

%---------------------------------------%
% test mode of eyelink connection
%---------------------------------------%

status = Eyelink('isconnected');
switch status
    case -1
        fprintf(1, 'Eyelink in dummymode.\n\n');
    case  0
        fprintf(1, 'Eyelink not connected.\n\n');
    case  1
        fprintf(1, 'Eyelink connected.\n\n');
end



%% Commands from JPs ELSetEyelinkDefaultsAW
%% commented out by AW 3/12/15 because I'm not sure what they do: 
%Eyelink('Command', 'saccade_velocity_threshold = 35');
%Eyelink('Command', 'saccade_acceleration_threshold = 9500');
%Eyelink('Command', ...
%	'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');	
%Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,BUTTON');
%Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,AREA');
%Eyelink('Command','file_sample_data = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS');

%Eyelink('Command', 'analog_out_data_type = OFF');		% YES default




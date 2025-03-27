%% function [scr, task] = prepScreen(task)
% This function opens a Psychtoolbox window and records some of its
% properties.

function [scr, task] = prepScreen(task)

if ~isfield(task,'openSecondWindow')
    task.openSecondWindow = true;
end

% Default startup check and setup:
PsychDefaultSetup(1);


%% set up parameters
% general information on task computer
scr.computer = Screen('Computer');  % get information about display computers

% If there are multiple displays guess that one without the menu bar is the
% best choice.  Dislay 0 has the menu bar.
scr.allScreens = Screen('Screens');
scr.nScreens   = length(scr.allScreens);
scr.expScreen  = max(scr.allScreens);

% get rid of PsychtoolBox Welcome screen
Screen('Preference', 'VisualDebugLevel',3);

scr.drawTextureFilterMode = [];%default filter mode for texture drawing

scr.nBits = 8;
scr.nLums = 2^scr.nBits;

%whether luminance levels should be expressed in the usual 0-256 range, or
%be normalized to 0-1
scr.normalizedLums = false;
if scr.normalizedLums
    PsychImaging('PrepareConfiguration');                                       %copied from M16 Demo
    PsychImaging('AddTask', 'General', 'NormalizedHighresColorRange');
    task.bgColor = task.bgLum;
else
    task.bgColor = floor(task.bgLum*((2^scr.nBits)-1));
end


%% load monitor information stored for this display
% There must be on the current path of this computer a file called 'display_[displayName].mat'
% This should contain a structure display that has the screen's physical size in cm, the subject distance,
% and the normalized gamma table if the display has been calibrated.

[displayParams, status] = getDisplayParameters(task.displayName);

if status==0
    fprintf(1,'\n\n(prepScreen)\t No display params for this setup! Using default!!!\n\n');
end

scr = catstruct(scr, displayParams);

%Skip sync tests? Should only do that when necessary
if scr.skipSyncTests
    Screen('Preference', 'SkipSyncTests',1);
end

if scr.useRetinaDisplay
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'UseRetinaResolution');
end
%% Set resolution of screen
if isfield(displayParams,'goalResolution') && ~scr.useRetinaDisplay
    scr.oldRes = Screen('Resolution',scr.expScreen);
    scr.changeRes = ~(scr.oldRes.width == displayParams.goalResolution(1) && scr.oldRes.height == displayParams.goalResolution(2) && scr.oldRes.hz == displayParams.goalFPS);
    if scr.changeRes 
        try
            scr.oldRes = SetResolution(scr.expScreen, displayParams.goalResolution(1), displayParams.goalResolution(2), displayParams.goalFPS);
        catch me
            keyboard
            rethrow(me)

        end
    end
else
    scr.changeRes = false;
end

%% % Open a window.
rectToOpen = []; %whole screen
scr.colDept = []; %depth (in bits) of each pixel. just do the default.
scr.numBuffers = 2;
scr.stereoMode = 0;

%"multisample" parameter: , if provided and set to a value greater than zero, enables automatic hardware anti-aliasing of the display:
%For each pixel, 'multisample' color samples are computed and combined into a single output pixel color.
%Higher numbers provide better quality but consume more video memory and lead to a reduction in framerate due to the higher computational demand
%NOTE: on some computers, setting multiSample to anything but [] will cause synchronization failure!
scr.multisample = [];


%Try to get full Retina resolution on macbook?
if exist('kPsychNeedRetinaResolution') && scr.useRetinaDisplay
    retinaParam = kPsychNeedRetinaResolution;
else
    retinaParam = [];
end


[scr.main,scr.rect] = Screen('OpenWindow',scr.expScreen,ones(1,3)*task.bgColor,rectToOpen,scr.colDept,scr.numBuffers,scr.stereoMode,scr.multisample,retinaParam);

%% Check screen paramers:
[scr.xres, scr.yres]    = Screen('WindowSize', scr.main);       % heigth and width of screen [pix]

%compute pixels per degree:
scr.ppd       =  pixelsPerDegree(scr.subDist, scr.width, scr.xres);

%Check if pixels are square:
horizRes=scr.xres/scr.width;
vertRes=scr.yres/scr.height;

% determine the main window's center
[scr.centerX, scr.centerY] = WindowCenter(scr.main);

%Test monitor frame duration
nSampToTest = 50;
goalStdDev = 0.0001;
timeout = 2;
[scr.fd, nsamp, sdev] = Screen('GetFlipInterval',scr.main, nSampToTest, goalStdDev, timeout);

scr.fps = 1/scr.fd;
scr.nominalFPS = Screen('FrameRate',scr.main,1);
%backup in case FrameRate command doesnt work with this screen:
if scr.nominalFPS == 0 && isfield(displayParams,'goalFPS')
    scr.nominalFPS = displayParams.goalFPS;
    fprintf(1,'\n(prepScreen_WTA) Warning: Screen(FrameRate) doesn''t work on this screen. Using requested goalFPS as nominal frame rate\n\n');
else
    if (scr.fps/scr.nominalFPS)>1.02 || (scr.fps/scr.nominalFPS)<0.98
        sca;
        fprintf(1,'\n(prepScreen_WTA) ERROR: Screen synchronization failed: nominal refresh rate = %.2f, actual rate  = %.2f\n\n', scr.nominalFPS, scr.fps);
        keyboard
    end
end
%To precisely control timing, determine when frame flips are asked for
scr.flipTriggerTime = task.flipperTriggerFrames*scr.fd;  %How long before desired time should the screen Flip command be executed
scr.flipLeadTime = task.flipLeadFrames*scr.fd;           %Within the screen Flip command, how long before desired time should flip be asked for


%Alpha blending for good dots:
% They are needed for proper anti-aliasing (smoothing) by Screen('DrawLines'), Screen('DrawDots') and for
% drawing masked stimuli with the Screen('DrawTexture') command.
Screen('BlendFunction', scr.main, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

%Text rendering:
Screen('Preference', 'TextRenderer', 1); %0=fast but no anti-aliasing; 1=high-quality slower, 2=FTGL (whatever that is)
Screen('Preference','TextAntiAliasing',task.textAntialias);


% get max priority of window activities
scr.maxPriorityLevel = MaxPriority(scr.main);

%% fixation check
scr.fixCkRad = round(task.fixCheckRad*scr.ppd);   % fixation check radius
scr.intlFixCkRad = round(task.initlFixCheckRad*scr.ppd);   % fixation check radius, for trial start

%% load calibration file - normalized gamma table
BackupCluts;
if isfield(scr,'normlzdGammaTable')
    ngt = scr.normlzdGammaTable;
else
    ngt = [];
end
if ~isempty(ngt)
    if size(ngt,2)==1
        ngt = repmat(ngt,1,3);
        fprintf(1,'\n(prepScreen) Calibration normalized gamma table has only 1 column. \n Assuming equal for all 3 guns\n.');
    end
    Screen('LoadNormalizedGammaTable',scr.main,ngt);
    fprintf(1,'\n(prepScreen) Loaded calibration file normalized gamma table for: %s\n',displayParams.monName);
    
else %defaults if no calibration file
    fprintf(1,'\n\n(prepScreen) NO CALIBRATED NORMALIZED GAMMA TABLE FOR THIS DISPLAY\n\n');
    %make a perfectly linear table
    %scr.normlzdGammaTable = repmat(linspace(0,1,255)',1,3);
end

%% Colors and contrast levels available

%Colors:
scr.black = BlackIndex(scr.main); %always returns 0
scr.white = WhiteIndex(scr.main); %returns 255 for an 8-bit display, may be higher for higher bits...unless NormalizedHighresColorRange, in which case whiteIndex is 1
scr.bgColor = scr.black+(task.bgLum*(scr.white-scr.black));  % background color
scr.fgColor = scr.white;

if scr.normalizedLums
    contStep = 1/scr.nLums;
else
    contStep = 1;
    scr.bgColor=round(scr.bgColor);
end
scr.deltaColor = min([(scr.white-scr.bgColor) (scr.bgColor-scr.black)]);

%Which nonzero contrasts are really available
cUps=(scr.bgColor+contStep):contStep:scr.white;
cDns=(scr.bgColor-contStep):-contStep:scr.black;

if length(cDns)>length(cUps)
    cDns=cDns(1:length(cUps));
elseif length(cUps)>length(cDns)
    cUps=cUps(1:length(cDns));
end

scr.availableCs=(cUps-cDns)./(cUps+cDns);

%% Open a second window if not in mirror mode on the unused (operator's) monitor
% (recommended by "help MirrorMode")
if scr.nScreens==2 && task.openSecondWindow
    otherScreenNum = scr.allScreens(scr.allScreens~=scr.expScreen);
    otherRes = Screen('Resolution',otherScreenNum);
    
    scr.mirrored = (otherRes.width == scr.xres) && (otherRes.height == scr.yres);
    [scr.otherWin,resn]=Screen('OpenWindow',otherScreenNum,ones(1,3)*task.bgColor);
    scr.otherResolution = resn([3,4]);
    scr.otherCenter = floor(scr.otherResolution/2);
    Screen('Flip',scr.otherWin);
else
    scr.otherWin = scr.main;
    scr.mirrored = 2;
end


%% print output

fprintf(1,'\n\n--------------------------------------------------------------\n');
fprintf(1,'(prepScreen) Loaded parameters for screen %s on computer %s.\n',scr.displayName,task.computerName);
fprintf(1,'(prepScreen) screen height (cm) = %.1f; screen width (cm) = %.1f\n',scr.height, scr.width);
fprintf(1,'(prepScreen) vertical pixels = %i; horizontal pixels = %i\n',scr.yres, scr.xres);
fprintf(1,'(prepScreen) At the specific viewing distance of %.1f cm, pixels/degree = %.2f\n',scr.subDist, scr.ppd);

fprintf(1,'\n(prepScreen) horizontal resolution: %.1f pix/cm; vertical resolution: %.1f pix/cm\n',horizRes,vertRes);
if (horizRes/vertRes)<0.9 || (horizRes/vertRes)> 1.1
    fprintf(1,'\n\n(prepScreen) Warning! Pixels deviate from being square by more than 10%%\n so circles will be ovals, squares will be rectangles!\nAdjust screen size manually.\n\n');
end

%Skip sync tests? Should only do that when necessary
if scr.skipSyncTests
    fprintf(1,'\n(prepScreen):SKIPPING MONITOR SYNC TESTS!!!!\n');
end

fprintf(1,'\n(prepScreen) Nominal refresh rate reported by computer: %.1f Hz\n', scr.nominalFPS);
fprintf(1,'\n(prepScreen) MEASURED REFRESH RATE (scr.fps) = %5f Hz;', scr.fps);
fprintf(1,'\n(prepScreen) FRAME DURATION (scr.fd) = %.5f s',  scr.fd);
fprintf(1,'\n\tStandard devation of %i frame duarations = %.7f',nsamp, sdev);
fprintf(1,'\n\tDifference between expected and measured frame durations: %.2f ms\n', 1000*((1/scr.nominalFPS)-scr.fd));

fprintf(1,'--------------------------------------------------------------\n');

%% Give the display a moment to recover from the change of display mode when
% opening a window. It takes some monitors and LCD scan converters a few seconds to resync.
WaitSecs(1);


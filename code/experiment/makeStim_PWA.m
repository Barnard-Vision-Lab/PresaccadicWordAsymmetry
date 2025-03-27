function task = makeStim_PWA(task, scr)
 
% Prepares stimuli for the FOVB (lexical decision field of view) experiment
% Calculates stimulus positions, prepares text and creates sounds 
% 
% Inputs and oututs: usual task and scr structures 

%% get images
task.imagePath = fullfile(task.paths.images, sprintf('stringImages_%s', task.displayName));
imageParamFile = fullfile(task.imagePath,sprintf('stringImageParams_%s.mat', task.displayName));
if ~exist(imageParamFile,'file')
    error('(%s) No string images made for this display (%s)!', mfilename, task.imagePath);
end

%load word image params
load(imageParamFile,'stringImageParams');
task.stringImageParams = stringImageParams;
if task.stringImageParams.pixelsPerDegree~=scr.ppd
    error('(%s) Pixels per degree for words (%.4f) does not equal ppd for this screen (%.4f)!', mfilename, task.stringImageParams.pixelsPerDegree, scr.ppd);
end

%2. for masks
imageParamFile = fullfile(task.imagePath,sprintf('maskImageParams_%s.mat', task.displayName));
if ~exist(imageParamFile,'file')
    error('(%s) No mask images made for this display (%s)!',mfilename, imageFolder);
end

load(imageParamFile,'maskImageParams');
task.maskImageParams = maskImageParams;
if task.maskImageParams.pixelsPerDegree~=scr.ppd
    error('(%s) Pixels per degree for masks (%.4f) does not equal ppd for this screen (%.4f)!',mfilename, task.maskImageParams.pixelsPerDegree, scr.ppd);
end

%% stimulus center positions
task.strings.centerX = round(scr.centerX+scr.ppd*task.strings.centerEcc.*cosd(task.strings.posPolarAngles));
task.strings.centerY = round(scr.centerY-scr.ppd*task.strings.centerEcc.*sind(task.strings.posPolarAngles));


%% Fixation point:
scr.fixCkRad = round(task.fixCheckRad*scr.ppd);   % fixation check radius
scr.intlFixCkRad = round(task.initlFixCheckRad*scr.ppd);   % fixation check radius, for trial start

task.fixation.posX  = round(scr.centerX+scr.ppd*task.fixation.ecc.*cosd(task.fixation.posPolarAngles));
task.fixation.posY  = round(scr.centerY-scr.ppd*task.fixation.ecc.*sind(task.fixation.posPolarAngles));

%Fixation mark is a dot on top of a cross on top of a disc. The cross
%dimming is the target in the localizer fixation task. 
%1. Disc
discDiameterPix = round(scr.ppd*task.fixation.discDiameter);
rad = round(discDiameterPix/2); 
%rect: left top right bottom
task.fixation.discRect = [-1 -1 1 1]*rad;

%2. Cross 
angles = [0 90];
allxy = [];
for ai = 1:2
    startx = -scr.ppd*0.5*task.fixation.crossLength*cosd(angles(ai));
    endx = scr.ppd*0.5*task.fixation.crossLength*cosd(angles(ai));
    starty = -scr.ppd*0.5*task.fixation.crossLength*sind(angles(ai));
    endy =  scr.ppd*0.5*task.fixation.crossLength*sind(angles(ai));
    
    newxy = [startx endx; starty endy];
    
    allxy = [allxy newxy];
end
task.fixation.crossXY = round(allxy);

%3. Dot
task.fixation.dotDiamPix = round(scr.ppd*task.fixation.dotDiameter);

%% Spatial cue coordinates
task.cue.x1 = scr.ppd*task.cue.minEcc*cosd(task.cue.posPolarAngles);
task.cue.y1 = -1*scr.ppd*task.cue.minEcc*sind(task.cue.posPolarAngles);
task.cue.x2 = scr.ppd*task.cue.maxEcc*cosd(task.cue.posPolarAngles);
task.cue.y2 = -1*scr.ppd*task.cue.maxEcc*sind(task.cue.posPolarAngles);
%y coords need to be inverted because in PTB, up from the center is a negative change 

%create "allcoords": 2x4 matrix, with x-postns in row 1 and y-postns in row 2
%
for si = 1:length(task.cue.x1)
    i1 = 1+(si-1)*2;
    i2 = i1+1;
    %x-coords
    task.cue.allcoords(1,i1) = task.cue.x1(si);
    task.cue.allcoords(1,i2) = task.cue.x2(si);
    %y-coords
    task.cue.allcoords(2,i1) = task.cue.y1(si);
    task.cue.allcoords(2,i2) = task.cue.y2(si);
end
task.cue.allcoords = round(task.cue.allcoords);

%% saccade endpoint markers
%rows = left, right 
%columns = top, bottom
%3rd dim = startpoint, endpoint 
task.marker.coordX = NaN(2,2,2);
task.marker.coordY = NaN(2,2,2);
mY = [-1 1];
for si=1:2
    task.marker.coordX(si,:,:) = round(scr.centerX+scr.ppd*task.marker.distH*cosd(task.marker.posPolarAngles(si)));
    for tb = 1:2
        task.marker.coordY(si,tb,:) = round(scr.centerY - scr.ppd*task.marker.distY*mY(tb));
    end
end

%% eyetracking 
task.fixCkRad = round(task.fixCheckRad*scr.ppd);   % fixation check radius
task.intlFixCkRad = round(task.initlFixCheckRad*scr.ppd);   % fixation check radius, for trial start


%% Text
Screen('TextFont',scr.main,task.instructTextFont);
Screen('TextSize',scr.main,task.textSize);
Screen('TextStyle',scr.main,0);





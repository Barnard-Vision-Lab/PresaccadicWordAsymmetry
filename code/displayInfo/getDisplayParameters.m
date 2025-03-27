%function [m, status] = getDisplayParameters(displayName)
%
% Returns a structure m with parameters for display monitor for a
% particular computer (with name displayName). For use with the function
% prepScreen that opens a Psychtoolbox window.
%
% fields of m:
% - width: width of active pixels [cm]
% - height: height of active pixels [cm]
% - subDist: distance of subject's eyes from monitor [cm]
% - goalResolution: desired screen resolution, horizontal and vertical [pixels].
%   PTB will try to set this resolution, unless it is left empty.
% - goalFPS: desired screen refresh rate, in frames per second [Hz].
%   PTB will try to set this referesh rate, unless it is left empty.
% - skipSyncTests: whether PTB should skip synchronization tests [boolean]
% - calibFile: the name of a mat file that contains the luminance calibration information,
%   as a table to load into  Screen('LoadNormalizedGammaTable' [character string].
%   Can be left empty.
% - monName: name of this monitor [character string]
%
% Also returns status, which is 1 if input displayName matches one of the
% setups stored in this function, 0 if there was no match and monitor
% parameters resorted to the default.

function [m, status] = getDisplayParameters(displayName)

status = 1;

m.useRetinaDisplay = false;
m.monName = displayName;

switch displayName
    
    
    case 'ViewPixx3D'
        m.width = 53;
        m.height = 30;
        m.goalResolution = [1920 1080];
        m.goalFPS = 120;
        m.subDist = 60;
        
        m.skipSyncTests = 0;
        
        %to use calibration fit to each gun separately 
        m.calibFile = '';
        
        %load(m.calibFile); 
        %%m.calib = calib;
        %m.normlzdGammaTable = calib.normlzdGammaTable;
        m.normlzdGammaTable = [];
   
   
    case 'MacbookPro'
        m.width = 28.5;
        m.height = 18;
        m.subDist = 50;
        m.goalResolution = [1440 900];
        m.skipSyncTests = 1;
        m.normlzdGammaTable = [];
        m.useRetinaDisplay = true;
        
    case 'ASUS' 
        m.width = 40.5;
        m.height = 25.5;
        m.subDist = 60;
        m.goalResolution = [1680 1050];
        m.goalFPS = 60;
        m.skipSyncTests = 1;
        m.normlzdGammaTable = [];
        m.useRetinaDisplay = false;
    otherwise
        m.width = 36;
        m.height = 29;
        m.subDist = 60;
        m.ppd = 100;
        %m.goalResolution = [];
        m.goalFPS = 60;
        m.skipSyncTests = 1;
        m.calibFile = '';
        m.monName = 'default';
        status = 0;
end

m.displayName = displayName;

%% compute pixels per degree
if ~isfield(m, 'ppd')
    m.ppd =  pixelsPerDegree(m.subDist, m.width, m.goalResolution(1));
end

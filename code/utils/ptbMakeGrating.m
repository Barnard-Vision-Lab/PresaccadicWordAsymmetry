% ptbMakeGrating.m
%
%      usage: ptbMakeGrating(width,height,sf,angle,phase,<xDeg2pix>,<yDeg2pix>)
%         by: Alex White (adopted from mglMakeGrating by Justin Gardner)
%       date: 10/23/12
%    purpose: create a 2D grating. You should start a psychtoolbox screen
%             before using, or supply xDeg2pix and yDeg2pix
%
%             width and height are in degrees of visual angle
%             sf is in cycles/degrees
%             angle and phase are in degrees
%
%             xDeg2pix and yDeg2pix are optional arguments that specify the
%             number of pixels per visual angle in the x and y dimension, respectively.
%             If not specified, these values are derived from the open mgl screen (make
%             sure you set mglVisualAngleCoordinates).


function g = ptbMakeGrating(width,height,sf,angle,phase,xDeg2pix,yDeg2pix)

global scr

g = [];
if ~any(nargin == [3 4 5 6 7])
  help ptbMakeGrating
  return
end

if ieNotDefined('sf'),sf = 1;end
if ieNotDefined('angle'),angle = 0;end
if ieNotDefined('phase'),phase = 0;end

% make it so that angle of 0 is horizontal
angle = -90-angle; 


if ~exist('scr','var')
    noScreen=true;
elseif ~isfield(scr,'ppd');
    noScreen=true;
else
    noScreen=false;
end

% defaults for xDeg2pix
if ieNotDefined('xDeg2pix')
  if noScreen
    fprintf(1,'(ptbMakeGrating) Psychtoolbox window is not initialized');
    return
  end
  xDeg2pix = scr.ppd;
end

%Assume square pixels:
% defaults for yDeg2pix
if ieNotDefined('yDeg2pix')
  if noScreen
    frintf(1,'(ptbMakeGrating) Psychtoolbox window is not initialized');
    return
  end
  yDeg2pix = scr.ppd;
end


% get size in pixels
widthPixels = round(width*xDeg2pix);
heightPixels = round(height*yDeg2pix);
widthPixels = widthPixels + mod(widthPixels+1,2);
heightPixels = heightPixels + mod(heightPixels+1,2);

% calculate image parameters
phase = pi*phase/180;

% if height is nan, it means we should calculate a 1 dimensional grating
if isnan(height)
  % 1D grating (note we ignore orientation)
  x = -width/2:width/(widthPixels-1):width/2;
  g = cos(x*sf*2*pi+phase);
else
  % 2D grating
  % calculate orientation
  angle = pi*angle/180;
  a=cos(angle)*sf*2*pi;
  b=sin(angle)*sf*2*pi;

  % get a grid of x and y coordinates that has 
  % the correct number of pixels
  x = -width/2:width/(widthPixels-1):width/2;
  y = -height/2:height/(heightPixels-1):height/2;
  [xMesh,yMesh] = meshgrid(x,y);

  % compute grating
  g = cos(a*xMesh+b*yMesh+phase);
end
% ptbMakeGaussian.m
%
%      usage: ptbMakeGaussian(width,height,sdx,sdy,xCenter,yCenter,<xDeg2pix>,<yDeg2pix>)
%         by: Alex White (adopted from mglMakeGraussian by Justin Gardner
%       date: 10/23/12
%    purpose: make a 2D gaussian, useful for making gabors for
%             instance. 
%             width, height, sdx and sdy are in degrees of visual angle
%
%             xcenter and ycenter are optional arguments in degrees of visual angle
%             and default to 0,0
%
%             xDeg2pix and yDeg2pix are optional arguments that specify the
%             number of pixels per visual angle in the x and y dimension, respectively.
%             If not specified, these values are derived from the open
%             psychotoolbox screen


function g = ptbMakeGaussian(width,height,sdx,sdy,xCenter,yCenter,xDeg2pix,yDeg2pix)

global scr

g = [];
if ~any(nargin == [3 4 5 6 7])
  help ptbMakeGaussian
  return
end

if ieNotDefined('xCenter'),xCenter = 0;end
if ieNotDefined('yCenter'),yCenter = 0;end


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

% get a grid of x and y coordinates that has 
% the correct number of pixels
x = -width/2:width/(widthPixels-1):width/2;
y = -height/2:height/(heightPixels-1):height/2;
[xMesh,yMesh] = meshgrid(x,y);

% compute gaussian window
g = exp(-(((xMesh-xCenter).^2)/(2*(sdx^2))+((yMesh-yCenter).^2)/(2*(sdy^2))));
% clamp small values to 0 so that we fade completely to gray.
g(g(:)<0.01) = 0;
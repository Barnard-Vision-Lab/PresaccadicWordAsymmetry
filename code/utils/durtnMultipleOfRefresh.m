%function [durToSet, roundedDur] = durtnMultipleOfRefresh(goalDur, fps, tolerance)
%by Alex White
%
%Rounds a requested stimulus duration (goalDur) to be in multiple of the
%frame duration of a computer display with given refresh rate (fps) in Hz. 
%Allows some tolerance, given that fps may be from a
%noisy estimate of true frame rate, causing for instance a rounding down by
%1 frame of a requested duration of 1 second on a 100 Hz display if
%measured fps is 99.999. 
% 
% Inputs:
% - goalDur: the duration you want, in seconds.
% - fps: the estimate refresh rate (frames per second, Hz) of the screen
% - tolerance: a duration in seconds. If rounding up would create an error
%  this large or larger, then round down. 
% 
% Outputs: 
% - durToSet: the duration you should ask psychtoolbox for, in seconds. 
% - roundedDur: the actual duration you're likely to get, in mulitiples of
% the video frame duration. If you need to round down, then durToSet =
% roundedDur. If you dont need to round down, then durToSet = goalDur, and
% roundedDur = duration you'll probably get by rounding up to the nearest
% duration that is a multiple of the frame duration. 

function [durToSet, roundedDur] = durtnMultipleOfRefresh(goalDur, fps, tolerance)

%If true refresh rate really is fps, and we were to round UP the number of frames, 
%duration would be this: 
roundUpDur = ceil(goalDur*fps)/fps;
%how much longer is this than the requested duration:
roundUpError = roundUpDur-goalDur;

%If that error is very small, then we should not do any rounding, rather than
%rounding down and losing a whole frame (or rounding up and getting too
%much)
if roundUpError<tolerance
    durToSet = goalDur;
    roundedDur = roundUpDur;
else %round down number of frames
    durToSet=floor(goalDur*fps)/fps;
    roundedDur = durToSet;
end

% ptbDrawFormattedText(str,posxy,c,centerH,centerV,flipH,flipV)
% Alex White, 2015
% 
%Using psychtoolbox and an open screen "win", draw text "str" centered on "[x,y]" (in units of pixels relative
%to screen rect), with color "c". Options ot center horizontally (centerH),
%vertically (centerV) and flip text horizontally or vertically. 

function [drawnBounds] = ptbDrawFormattedText(win,str,posxy,c,centerH,centerV,flipH,flipV)

bounds = Screen(win,'TextBounds',str);
%to center all words on the same vertical position, choose a standard string that has both an ascending and descending character stroke 
boundsStandard = Screen(win,'TextBounds','gad'); 

if centerH
    x  = posxy(1)-bounds(3)/2;     % x position
else
    x = posxy(1);
end
if centerV
    y  = posxy(2)-boundsStandard(4)/2; %1.75;     % y position
else
    y = posxy(2); 
end

[~,~,drawnBounds]=DrawFormattedText(win,str,x,y,c,[],flipH,flipV);
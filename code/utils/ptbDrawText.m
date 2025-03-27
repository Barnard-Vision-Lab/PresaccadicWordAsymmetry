%ptbDrawText(str,posxy,c)
% Alex White, 2012

%Using psychtoolbox, draw text str centered on [x,y] (in units of pixels relative
%to screen rect), with color c

function [] = ptbDrawText(scr,str,posxy,c)


bounds = Screen(scr.main,'TextBounds',str);
x  = posxy(1)-bounds(3)/2;     % x position
y  = posxy(2)-bounds(4)/2;     % y position

Screen(scr.main,'Drawtext',str,x,y,c);
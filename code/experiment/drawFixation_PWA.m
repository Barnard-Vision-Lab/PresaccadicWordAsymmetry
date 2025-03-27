function drawFixation_PWA(task, scr, posI)

% Draws a dot on top of a cross on top of a disc 
% 
% Inputs: 
% - task and scr: standard structures 
% - posI: index of fixation position, from which to pull out  coordinates 
%  from task.fixation.posX and task.fixation.posY

xy = [task.fixation.posX(posI); task.fixation.posY(posI)];

%1. Draw disc
discRect = task.fixation.discRect+[xy' xy'];
Screen('FrameOval',scr.main, task.fixation.discColor, discRect);

%2. Draw cross
Screen('DrawLines',scr.main, task.fixation.crossXY, task.fixation.crossWidth, task.fixation.crossColor, xy',2);

%3. Draw dot
Screen('DrawDots', scr.main, xy, task.fixation.dotDiamPix, task.fixation.dotColor, [], task.fixation.dotType);

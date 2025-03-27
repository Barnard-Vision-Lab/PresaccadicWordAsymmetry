%TELL THE SUBJECT THAT WE NEED TO RECALIBRATE
%ALSO, PRESSING "q" INSTEAD OF SPACE BAR WILL END THE EXPERIMENT

function userQuit = instructRecalibrate(scr,task)

buttons = [KbName('space') KbName('q')];
quitButton = length(buttons);


c=task.textColor;

rubber(scr,[]);

recalibText='Let''s recalibrate.';
continueButtonText='the space bar';
continueText=sprintf('Press %s.', continueButtonText);
quitText = 'If you are totally stuck, press q to terminate the experiment.';


ptbDrawText(scr, recalibText, dva2scrPx(scr, 0, 1),c);
ptbDrawText(scr, continueText, dva2scrPx(scr, 0, -1),c);
Screen('TextStyle',scr.main,2); %italic
ptbDrawText(scr, quitText, dva2scrPx(scr, 0, -6),c);
Screen('TextStyle',scr.main,0); 

Screen(scr.main,'Flip');

keyPress = 0;
while keyPress==0
   [keyPress, ~] = checkTarPress(buttons);
end

rubber(scr,[]);
Screen(scr.main,'Flip');
userQuit = keyPress==quitButton;




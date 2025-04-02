function userDone = concludeBlock_PWA(task,scr,blockNum)

WaitSecs(0.5);

% clear keyboard buffer
FlushEvents('KeyDown');

%clear screen to background color
rubber(scr,[]);

Screen('TextSize',scr.main,task.instructTextSize);
Screen('TextFont',scr.main,task.instructTextFont);

c=task.textColor;
textSep=1.25;

%compute accuracy in this block 
blockPC = mean(task.trials.respCorrect,'omitnan');

if blockNum < task.numBlocks
    doneText = sprintf('All done with block %i of %i!', blockNum, task.numBlocks); 
    continueText = 'Press any of your response buttons to continue.';
    quitText = '(or press ''q'' if you must quit early)';
        
    %print out accuracy on all single-task trials done this run so far
    if task.ntrialsDone>0    
        accText = sprintf('Percent correct = %.1f%% (%i trials)', task.pcSoFar*100, task.ntrialsDone);
    else
        accText = '  ';
    end
    
else
    doneText = 'All done, thank you!';
    continueText = '(Press any of your response buttons to exit)';
    quitText = ' ';
    accText = ' ';
end
continueButton = [task.buttons.resp KbName('space') KbName('Return')];
quitButton = task.buttons.quit;
%%%%%
%% Now  draw  the text

%to both screens if there are 2 non-mirrored screens open
if scr.nScreens==2 && ~scr.mirrored
    sIs = [scr.main, scr.otherWin];
else
    sIs = scr.main;
end

for sI = sIs
    
    vertPos = 2;
    ptbDrawFormattedText(sI,doneText, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);

    vertPos=vertPos-textSep;
    Screen('TextStyle',sI,2); %italic
    ptbDrawFormattedText(sI,continueText, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);
    Screen('TextStyle',sI,0); %normal
    vertPos = vertPos - textSep*4;
    ptbDrawFormattedText(sI,quitText, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);
    
    vertPos = vertPos - textSep*4;
    ptbDrawFormattedText(sI,accText, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);
    
    Screen(sI,'Flip');
end

keyPress = 0;
while ~keyPress
    [keyPress] = checkTarPress(continueButton);
end

userDone = keyPress == quitButton;

WaitSecs(0.25);
% clear keyboard buffer
FlushEvents('KeyDown');

%% if the subject really wants to quit, they have to press the escape button twice 
if userDone
    keyPress = 0;
    while ~keyPress
        [keyPress] = checkTarPress(continueButton);
    end
    
    userDone = keyPress == quitButton;
end
%% clear screen 
rubber(scr,[]);
for sI = sIs
    Screen(sI,'Flip');
end


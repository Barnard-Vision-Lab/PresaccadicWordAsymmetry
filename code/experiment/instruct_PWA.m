function instruct_PWA(task,scr,blockNum)

% clear keyboard buffer
FlushEvents('KeyDown');

%clear screen to background color
rubber(scr,[]);

Screen('TextSize',scr.main,task.instructTextSize);
Screen('TextFont',scr.main,task.instructTextFont);

c=task.textColor;
textSep=1.25;


if task.practice
    blockText = 'PRACTICE Block';
else
    blockText=sprintf('Block %i of %i', blockNum, task.numBlocks);
end


instructText{1} = 'Report whether you think the post-cued letter string was a living thing, with a rating from "sure no" to "sure yes."';
instructText{2} = 'Use your left hand (keys 0, 1, 4, and 7) for the left position, and your right hand (keys ., 3, 6, and 9) for the right position.';

instructText{3} = ' ';
instructText{4} = 'Always fixate your gaze on the central cross.';

continueText = 'Press any of your response keys to continue';
continueButton = [task.buttons.resp KbName('space')];
finalText = continueText;
startScanButton = task.buttons.resp;

%% Draw a blank texture, to initalize all that functionality
blankTex = Screen('MakeTexture',scr.main,ones(10,10)*scr.bgColor);
Screen('DrawTexture', scr.main, blankTex, [], [10 10 20 20],[],scr.drawTextureFilterMode);

%%%%%
%% Now actually draw all the text

%to both screens if there are 2 non-mirrored screens open
if scr.nScreens==2 && ~scr.mirrored
    sIs = [scr.main, scr.otherWin];
else
    sIs = scr.main;
end

for sI = sIs
    Screen('TextStyle',sI,2); %italic

    vertPos = 6.5;
    ptbDrawFormattedText(sI,blockText, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);
    
    
    Screen('TextStyle',sI,0); %normal
    vertPos = 2.5;
    for ii=1:length(instructText)
        vertPos = vertPos-textSep;
        ptbDrawFormattedText(sI,instructText{ii}, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);
    end
    
    vertPos=vertPos-textSep*2;
    Screen('TextStyle',sI,2); %italic
    ptbDrawFormattedText(sI,continueText, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);
    Screen('TextStyle',sI,0); %normal
    
    Screen(sI,'Flip');
    
end

keyPress = 0;
while ~keyPress
    [keyPress] = checkTarPress(continueButton);
end

WaitSecs(0.2);
% clear keyboard buffer
FlushEvents('KeyDown');


%% if in the MRI, wait for trigger to start
if task.MRI
    for sI = sIs
        vertPos = 0;
        ptbDrawFormattedText(sI,finalText, dva2scrPx(scr, 0, vertPos),c,true,true,false,false);
        Screen('Flip',sI);
    end
    
    WaitSecs(0.5);
    FlushEvents('KeyDown');
    keyPress = 0;
    while ~keyPress
        [keyPress] = checkTarPress(startScanButton);
    end
end

%% clear screen and button s
rubber(scr,[]);
for sI = sIs
    Screen(sI,'Flip');
end

Screen('Close',blankTex);
FlushEvents('keyDown');

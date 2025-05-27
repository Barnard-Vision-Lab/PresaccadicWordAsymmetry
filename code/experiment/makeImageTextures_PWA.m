function task = makeImageTextures_PWA(task,scr)
%at start of run creates a texture and rect for each image 
%texture is a psychtoolbox tool where before the start of the trials all
%images are loaded in and turned into texture so matlab has it ready to go
%and gives back a handle - a single number that indexes that image
ntrials = size(task.runTrials,1);
nSides = 2;

task.stringTextures = NaN(task.numBlocks,task.trialsPerBlock, nSides);
task.stringRects    = NaN(task.numBlocks,task.trialsPerBlock, nSides, 4);
task.maskTextures   = NaN(task.numBlocks,task.trialsPerBlock, nSides);
task.maskRects      = NaN(task.numBlocks,task.trialsPerBlock, nSides, 4);

rectExpansionPx = round(task.cue.postCueRectExpansionDeg*scr.ppd);
%loops through all trials and then loops through side (left/right) and
%pulls out the image that we have decided will be presented in that side on
%that trial and loads in that image
for ti = 1:ntrials %trial number within run (including all blocks)
    
    td = task.runTrials(ti,:);
    
    clear stringImage maskImage
    
    for side=1:2
        %% letter string
        eval(sprintf('indx = td.side%iStringIndex;', side));
        
        imgName = sprintf('stringImg_%i.mat', indx);
        load(fullfile(task.imagePath,imgName), 'stringImage');
        
        task.stringTextures(td.blockNum, td.trialNum, side) = Screen('MakeTexture', scr.main, stringImage);
        
        %2. Save its rect:
        %rectangle defines bounds that image will occupy on the screen
        wid = size(stringImage,2);
        hei = size(stringImage,1);
        
        %center of word
        wordPos = [task.strings.centerX(side) task.strings.centerY(side)];
         startX = wordPos(1) - floor(wid/2);
        endX = startX + wid - 1;
        
        startY = wordPos(2) - floor(hei/2);
        endY = startY + hei -1;
        
        task.stringRects(td.blockNum, td.trialNum, side, :) = round([startX startY endX endY]);
        
        %save rect for post-cue around target position, dilated by a little
        %bit
        if side==td.targetSide
            task.postCueRect(td.blockNum, td.trialNum, :) = round([startX startY endX endY]) + [-1 -1 1 1]*rectExpansionPx;
        end
          
        %% mask
        eval(sprintf('indx = td.side%iMaskIndex;', side));
        
        imgName = sprintf('maskImg_%i.mat', indx);
        load(fullfile(task.imagePath,imgName), 'maskImage');
        
     
        
        task.maskTextures(td.blockNum, td.trialNum, side) = Screen('MakeTexture', scr.main, maskImage);
        
        %2. Save its rect:
       wid = size(maskImage,2);
        hei = size(maskImage,1);
        
         %center of word
        wordPos = [task.strings.centerX(side) task.strings.centerY(side)];
        
        startX = wordPos(1) - floor(wid/2);
        endX = startX + wid - 1;
        
        startY = wordPos(2) - floor(hei/2);
        endY = startY + hei -1;
        
        task.maskRects(td.blockNum, td.trialNum, side, :) = round([startX startY endX endY]);
        
    end
end




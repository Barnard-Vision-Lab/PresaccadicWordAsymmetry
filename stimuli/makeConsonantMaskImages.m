function maskImageParams = makeConsonantMaskImages(displayName)	
%% make the consonant string mask images
%also creates consonant strings. The same number as their are real words in
%the lexicon, with the same distribution of lengths. 


%% set paths
codePath = SCLRCons_Base();
addpath(genpath(codePath));
projPath = fileparts(fileparts(codePath));
imagePath = fullfile(projPath, 'SCImages', sprintf('stringImages_%s', displayName));
if ~isfolder(imagePath), mkdir(imagePath); end

drawEachLetter  = false;

%% load paramers for this experiment and create random consonant strings
params = SCLRCons_Params;
consonants = 'bcdfghjklmnpqrstvwxz';
nConsonants = length(consonants);

%real word lexicon: 
L = params.strings.lexicon;

%consonant string lexicon for masks: 
C = cell(size(L.word));

%same distribution of mask lengths as real word lengths 
uLens = unique(L.length);
for li = 1:length(uLens)
    stringLength = uLens(li);
    lengthIs = find(L.length==stringLength);
    nStr = length(lengthIs);
    nCreate = nStr*2;
    %draw random consontants
    letterIndices = randi(nConsonants, [nCreate stringLength]);
    
    %filter unique ones: 
    letterIndices = unique(letterIndices, 'rows');
    
    %pick random ones to include 
    includeIs = randsample(size(letterIndices,1), nStr);
    for si=1:nStr
       C{lengthIs(si)} = consonants(letterIndices(includeIs(si), :)); 
    end
end
   
nWords = size(C,1);

 
%% set up screen
%set pixels per degree for the screen to be used
targetScr = getDisplayParameters(displayName); %this is called targetScr because may differ from the scren being used right now
pixPerDeg = targetScr.ppd;


scr.white = [255 255 255];
scr.black = [0 0 0];

bgColor = scr.white*params.bgLum;

rectToOpen = [];
numBuffers = 2;
stereoMode = 0;
multiSample = 4;
colDept = []; %default

if targetScr.useRetinaDisplay
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'UseRetinaResolution');
    retinaParam = kPsychNeedRetinaResolution;
else
    retinaParam = [];
end

% get rid of PsychtoolBox Welcome screen
Screen('Preference', 'VisualDebugLevel',3);

scr.allScreens = Screen('Screens');
scr.expScreen  = max(scr.allScreens);

%Skip sync tests? Should only do that when necessary
if targetScr.skipSyncTests
    Screen('Preference', 'SkipSyncTests',1);
end

[scr.main,scr.rect] = Screen('OpenWindow',scr.expScreen,bgColor,rectToOpen,colDept,numBuffers,stereoMode,multiSample,retinaParam);

Screen('Preference', 'TextRenderer', 1); %0=fast but no anti-aliasing; 1=high-quality slower, 2=FTGL (whatever that is)

Screen('Preference','TextAntiAliasing',params.strings.antiAlias);
Screen('Preference', 'TextAlphaBlending', 1)


%ttext style: 0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend.
Screen('TextStyle',scr.main,0);

[scr.xres, scr.yres]    = Screen('WindowSize', scr.main);
[scr.centerX, scr.centerY] = WindowCenter(scr.main);

%% load calibration file - normalized gamma table
BackupCluts;
if isfield(targetScr,'normlzdGammaTable')
    ngt = targetScr.normlzdGammaTable;
else
    ngt = [];
end
if ~isempty(ngt)
    if size(ngt,2)==1
        ngt = repmat(ngt,1,3);
        fprintf(1,'\n(prepScreen) Calibration normalized gamma table has only 1 column. \n Assuming equal for all 3 guns\n.');
    end
    Screen('LoadNormalizedGammaTable',scr.main,ngt);
    fprintf(1,'\n(prepScreen) Loaded calibration file normalized gamma table for: %s\n',targetScr.monName);
    
else %defaults if no calibration file
    fprintf(1,'\n\n(prepScreen) NO CALIBRATED NORMALIZED GAMMA TABLE FOR THIS DISPLAY\n\n');
    %make a perfectly linear table
    %scr.normlzdGammaTable = repmat(linspace(0,1,255)',1,3);
end
%% parameters for createLetterTextures


%2 font sizes
%2 spacings
o.alphabet = consonants;
nLetters = length(o.alphabet);
o.borderLetter = '';
o.readAlphabetFromDisk=0;
o.targetSizeIsHeight = 1;
o.targetHeightOverWidth = 1;
o.targetFontHeightOverNominalPtSize=1;
o.targetFontNumber=[];
o.printSizeAndSpacing = true;
o.showLineOfLetters = true;
o.contrast = 1;


%variables to save
xHeightDeg = params.strings.xHeightDeg;


wordSizePx      = NaN(nWords,  2);

o.targetFont = params.maskFont;


oldFontName = Screen('TextFont',scr.main,o.targetFont);
actualFontName = Screen('TextFont',scr.main,o.targetFont);

%% adjust font size to get x-height in deg
tooSmall = true;
fontSize = 1;
while tooSmall
    fontSize = fontSize+1;
    Screen('TextSize',scr.main,fontSize);
    bounds = Screen(scr.main,'TextBounds','x');
    heightPix = bounds(4);
    heightDeg = heightPix/pixPerDeg;
    tooSmall = heightDeg < xHeightDeg;
end

fprintf(1,'\nUsing font size %i to get x-height to %.2f deg\n', fontSize, xHeightDeg);

fontSizePoints = fontSize;
%make letters
o.targetPix = fontSize;
letterStruct = CreateLetterTextures_AW(1,o,scr.main);

%Pull out the images, and their sizes, and blank pixels on either side
letterImgs = cell(1,nLetters);
letterImgSizes = NaN(nLetters,2);
letterTightSizes = NaN(nLetters,2);
nBlankSidePx = NaN(nLetters,2);
usedFontSizes = NaN(nLetters,1);
for li=1:nLetters
    letterImgs{li} = letterStruct(li).image;
    letterImgSizes(li,:) = [size(letterImgs{li},1) size(letterImgs{li},2)];
    
    letterBounds = ImageBoundsAW(letterImgs{li} , bgColor(1));
    letterWidthPx = letterBounds(3)-letterBounds(1) + 1;
    letterHeightPx = letterBounds(4)-letterBounds(2) + 1;
    letterTightSizes(li,:) = [letterHeightPx letterWidthPx];
    
    leftBlankPx = letterBounds(1)-1;
    rightBlankPx = size(letterImgs{li},2) - letterBounds(3);
    nBlankSidePx(li,:) = [leftBlankPx rightBlankPx];
    
    usedFontSizes(li) = letterStruct(li).sizePix;
end

% Draw each letter for testing:
if drawEachLetter
    for li=1:nLetters
        Screen('DrawTexture',scr.main,letterStruct(li).texture);
        Screen('DrawingFinished',scr.main); Screen('Flip',scr.main);
        WaitSecs(0.1);
    end
end

%How much center-to-center spacing would there be if we don't trim the letter images at all?
%just the wid
letterImgWidth = unique(letterImgSizes(:,2));
if length(letterImgWidth)~=1
    keyboard
end

actualXHeightPx = letterTightSizes(o.alphabet=='x',1);
actualXWidthPx = letterTightSizes(o.alphabet=='x',2);

actualXImageSizePx = letterImgSizes(o.alphabet=='x',:);

xImages = letterStruct(o.alphabet=='x').image;
cImages = letterStruct(o.alphabet=='c').image;


%According to Yu, Cheung, Legge & Chung, 2007: ?the spacing used in normal Courier text is 1.16 times the width of the lowercase x
%standardSpacingPx(sizeI) = ceil(actualXWidthPx*1.16);

%default center-center spacing is if we just concatenate the letter images, which
%should all have the same width:
defaultSpacingPx = letterImgWidth;
%and that's what we'll use
spacingPx = defaultSpacingPx;

pixelsToAdd = defaultSpacingPx - letterImgWidth;

trimParams.tightWidth = false; %whether to do do any trimming
trimParams.minBlankOnLeftForCut = inf; %min number of blank pixels on left side to trigger a cut
trimParams.blankOnLeftToCut = 0; %      number of blank pixels on left to cut (if any)
trimParams.minBlankOnRightForCut = inf; %don't cut
trimParams.blankOnRightToCut = 0;

padParams.right = pixelsToAdd;
padParams.left  = 0;

for wi=1:nWords
    word = C{wi};
    letterColrs = repmat(params.strings.color,[length(word) 1]);
    
    %assemble word image from pixels
    stringImage = assembleWordImage(word, o.alphabet, letterImgs, letterColrs, bgColor(1), trimParams, padParams);
    
    %Crop the word image as tightly as possible... but only
    %HORIZONTALLY. Leave space on the top and bottom, so the
    %baseline stays in the same vertical position for all words
    wordBounds = ImageBoundsAW(stringImage, bgColor(1));
    stringImage = stringImage(:, wordBounds(RectLeft):wordBounds(RectRight), :);
    
    wordSizePx(wi, :) = [size(stringImage,1) size(stringImage,2)];
    
    %save as a mat file

    maskImage = stringImage;
    fileName = sprintf('consonantMaskImg_%i.mat', wi);
    save(fullfile(imagePath,fileName), 'maskImage');
    
end


maskImageParams.consonantStrings = C;
maskImageParams.stringLengths = L.length; %length of each consonant string was matched to a real word in the lexicon 
maskImageParams.fontSizePoints = fontSizePoints;
maskImageParams.actualXHeightPx = actualXHeightPx;
maskImageParams.actualXWidthPx = actualXWidthPx;
maskImageParams.actualXHeightDeg = actualXHeightPx./pixPerDeg;
maskImageParams.actualXWidthDeg = actualXWidthPx./pixPerDeg;
maskImageParams.actualXImageSizePx = actualXImageSizePx;
maskImageParams.spacingPx = spacingPx;
maskImageParams.letterImgSizes = letterImgSizes;
maskImageParams.letterTightSizes = letterTightSizes;
maskImageParams.letters = o.alphabet;
maskImageParams.spacingDeg = spacingPx./pixPerDeg;
maskImageParams.wordSizeDeg = wordSizePx./pixPerDeg;
maskImageParams.pixelsPerDegree = pixPerDeg;
maskImageParams.displayName = displayName;
maskImageParams.exptParams  = params;
maskImageParams.xImages = xImages;
maskImageParams.cImages = cImages;
maskImageParams.actualFontName = actualFontName;
maskImageParams.oldFontName = oldFontName;


%% save

paramName = fullfile(imagePath, sprintf('consonantMaskImageParams_%s.mat', displayName));
save(paramName, 'maskImageParams');

sca

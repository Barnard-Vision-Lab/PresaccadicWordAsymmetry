%% task = makeTrials_PWA(task)
%

% Adds to "task" a structure "runTrials", which is a table with a BxT rows
% where B is the number of blocks and T is the number of
% trials per block. Each row contains columns for different
% parameters on each trial.
%
% runTrials.duration uses durations in task.time: the originally requested
% durations. Doesn't use the duration after rounded to screen frame
% durations, in case there's some error in that.

function task = makeTrials_PWA(task)

% different number of trials in practice
if task.practice
    task.trialsPerBlock = task.practiceTrialsPerBlock;
end

%% first initialize a table with info about each trial in each block
blockInfo = table;

for bi = 1:task.numBlocks
    ts = table;
    
    ts.blockNum = ones(task.trialsPerBlock,1)*bi;
    ts.originalBlockTrialNum  = (1:task.trialsPerBlock)';
    
    %cueCond: 0=neutral/fixation; 1=cued/saccade
    ts.cueCond = ones(task.trialsPerBlock, 1)*task.cueBlocks(bi);

    blockInfo = [blockInfo; ts];
end

%% then counterbalance key variables

 cLengs = task.strings.lexicon.length;
 lens = unique(cLengs)';
  
design.parameters.targetSide              = 1:2;
design.parameters.targetCategory          = task.strings.realWordCatgs;
design.parameters.stringLength            = lens;

task.runTrials = table;
for cueType = unique(blockInfo.cueCond)'
    cueTs = blockInfo.cueCond==cueType;
    theseBlocks = blockInfo(cueTs,:);
    if cueType==0
        design.parameters.cueValidity = 0;
    elseif cueType==1
        design.parameters.cueValidity  = task.cueValidityDistribution; %-1=invalid;  1=valid; later neutral cues are set to 0

    end

    [trls, minCounterbalanceTs] = makeTrialOrder(design, sum(cueTs));
    
    task.runTrials = [task.runTrials;  [theseBlocks trls]];
end
    
%re-sort by block number
task.runTrials = sortrows(task.runTrials, {'blockNum','originalBlockTrialNum'});
    
%create the runTrials table from blockInfo and this new table trls
totalTrials = size(task.runTrials,1);

%add cuedSide: 0 for neutral, 1 for left, 2 for right. Depends on
%cueValidity. 
task.runTrials.cuedSide = task.runTrials.targetSide; %start with cue on same side as target word 
task.runTrials.cuedSide(task.runTrials.cueValidity==0) = 0; %neutral trials its 0
task.runTrials.cuedSide(task.runTrials.cueValidity==-1) = 3-task.runTrials.targetSide(task.runTrials.cueValidity==-1); %invalid trials its opposite of targetSide (1 for 2 and 2 for 1).  

%add category of each word
task.runTrials.side1Category = ones(size(task.runTrials.targetSide))*task.strings.pseudowordCatg;
task.runTrials.side1Category(task.runTrials.targetSide==1)  = task.runTrials.targetCategory(task.runTrials.targetSide==1);

task.runTrials.side2Category = ones(size(task.runTrials.targetSide))*task.strings.pseudowordCatg;
task.runTrials.side2Category(task.runTrials.targetSide==2)  = task.runTrials.targetCategory(task.runTrials.targetSide==2);


%add preCue duration
task.runTrials.preCueDur = task.time.preCueMin + (task.time.preCueMax-task.time.preCueMin)*rand(totalTrials,1);
task.runTrials.preCueDur = durtnMultipleOfRefresh(task.runTrials.preCueDur, task.fps, task.durationRoundTolerance); 


%% add trial numbers
%override the "trialNum" variable, which was set by makeTrialOrder
%including all trials of each stimulus type. Let's reset it so it
%corresponds to the trial number in each block:
task.runTrials.trialNum = task.runTrials.originalBlockTrialNum;
task.runTrials.overallTrialNum = (1:totalTrials)';



%% pick strings for each trial 
categoryNames = task.strings.categories;
task.runTrials.side1StringIndex = zeros(size(task.runTrials.trialNum));
task.runTrials.side2StringIndex = zeros(size(task.runTrials.trialNum));
task.runTrials.side1String = cell(size(task.runTrials.trialNum));
task.runTrials.side2String = cell(size(task.runTrials.trialNum));

L = task.strings.lexicon;
[~, L.categoryI] = ismember(L.category, task.strings.categories);
nWords = size(L,1);

%structure to keep track of how often a word can appear and when it has appeared
wordStats.nPlannedAppearances = zeros(nWords, 1);
wordStats.nAppearances = zeros(nWords,1);
wordStats.appearedWith = cell(nWords,1);
wordsWithExtraRep = cell(1,3);
%for each category, how many times the full set of words appears
nFullRepeats = zeros(1,3);
%and for each category, the number of words that need to appear 1
%extra time
nWordsExtraRep = zeros(1,3);
for ci=1:3
    catIs = find(L.categoryI==ci);
    nWordsPerCat = length(catIs);
    catCount = sum(task.runTrials.side1Category==ci) + sum(task.runTrials.side2Category==ci);
    nRepeatsNeeded = catCount/nWordsPerCat;
    nFullRepeats(ci) = floor(nRepeatsNeeded);  %min number of times each word will have to repeat
    nWordsExtraRep(ci) = ceil((nRepeatsNeeded-nFullRepeats(ci))*nWordsPerCat); %number of words that will have to repeat 1x more
    
    wordStats.nPlannedAppearances(catIs) = ones(length(catIs),1)*nFullRepeats(ci);
    if nWordsExtraRep(ci)>0
        wordsExtraRep = randsample(catIs, nWordsExtraRep(ci), 'false');
        wordStats.nPlannedAppearances(wordsExtraRep) = nFullRepeats(ci)+1;
        %save the words that got an extra repetition
        wordsWithExtraRep{ci} = wordsExtraRep;
    end
end


%now loop through trials and pick the words 
for ti=1:totalTrials
    wordCatgs = [task.runTrials.side1Category(ti) task.runTrials.side2Category(ti)];
    trialWords = NaN(1,2);

    for side = 1:2 %left, right 
        %availablewords are those of the chosen category and chosen length
        %for this trial. Both words should be the same length. 
        availableWords = find(wordStats.nAppearances<wordStats.nPlannedAppearances & L.categoryI==wordCatgs(side) & L.length==task.runTrials.stringLength(ti));
        if side==2
            %set word 2: a word that word 1 hasnt appeared with
            %and hasn't been fully used yet. Also can't be word 1.
            availableWords = setdiff(availableWords, [trialWords(1) wordStats.appearedWith{trialWords(1)}]);
        end
        
        if ~isempty(availableWords)
            if length(availableWords)>1
                wordi = randsample(availableWords, 1);
            else %if theres only 1 available word, just use it 
                wordi = availableWords;
            end
                
        else
            try
            availableWords = find(L.categoryI==wordCatgs(side) & L.length==task.runTrials.stringLength(ti));
            availableWords = availableWords(wordStats.nPlannedAppearances(availableWords)==min(wordStats.nPlannedAppearances(availableWords)));
            if side==2
                availableWords = setdiff(availableWords, [trialWords(1) wordStats.appearedWith{trialWords(1)}]);
            end
            catch
                esca
                keyboard
            end
            wordi = randsample(availableWords, 1);
            fprintf(1,'\nTrial %i, word %i: Got stuck, had to use a word 1 more time than planned\n', ti, side);
            
        end
        %increment the counter for this chosen word
        wordStats.nAppearances(wordi) = wordStats.nAppearances(wordi) + 1;
        trialWords(side) = wordi;
        
        %save this word choice for this side to task.runTrials, along with
        %its length and frequency
        eval(sprintf('task.runTrials.side%iStringIndex(ti) = L.stringNum(wordi);', side))
        eval(sprintf('task.runTrials.side%iString(ti) = L.word(wordi);', side));

        eval(sprintf('task.runTrials.side%iStringLength(ti) = L.length(wordi);', side))
        eval(sprintf('task.runTrials.side%iStringFreq(ti) = L.Freq_SUBTLEXUS_Zipf(wordi);', side))
    end
    %for both words selected for this trial, save to "appearedWith" the
    %other word, to avoid repetitions of this same pair in subsequent
    %trials
    wordStats.appearedWith{trialWords(1)} = [wordStats.appearedWith{trialWords(1)} trialWords(2)];
    wordStats.appearedWith{trialWords(2)} = [wordStats.appearedWith{trialWords(2)} trialWords(1)];
    
    %catch errors
    if task.runTrials.side1StringLength(ti)~=task.runTrials.side2StringLength(ti)
        esca
        keyboard
    end
        
end

wordStats.nFullCategorySetRepeats = nFullRepeats;
wordStats.nCategoryWordsExtraRepeat = nWordsExtraRep;
task.wordStats = wordStats;


%% pick pre-masks for each trial (from same set of strings, but shown in BACS-2 font)
 %restrict masks to be strings of a certain length


for len = lens
    availableIs = find(cLengs==len);
    for side=1:2
        %find the trials when the word on this side has length "len"
        eval(sprintf('theseTs = task.runTrials.side%iStringLength == len;', side));
        nts = sum(theseTs);
        %sample from the masks not used yet with that length
        if length(availableIs)>=nts
            theseIs = sampleWithoutReplacement(availableIs, nts);
        else
            theseIs = sampleWithReplacement(availableIs, nts);
        end
        eval(sprintf('task.runTrials.side%iMaskIndex(theseTs) = theseIs;', side))
        eval(sprintf('task.runTrials.side%iMask(theseTs) = task.strings.lexicon.word(theseIs);', side));
        eval(sprintf('task.runTrials.side%iMaskLength(theseTs) = cLengs(theseIs);', side, side));
        availableIs = setdiff(availableIs, theseIs);
    end
end

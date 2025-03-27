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
    
    blockInfo = [blockInfo; ts];
end

%% then counterbalance key variables 
design.parameters.targSide              = 1:2;
design.parameters.cueFocused            = [1 1 1 0 0];
design.parameters.cueValidity           = [-1 1 1];
design.parameters.side1Category         = 1:2; %1=nonliving; 2 = living;
design.parameters.side2Category         = 1:2; 


[trls, minCounterbalanceTs] = makeTrialOrder(design,task.numBlocks*task.trialsPerBlock);

%create the runTrials table from blockInfo and this new table trls
task.runTrials = [blockInfo trls];


totalTrials = size(task.runTrials,1);

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
wordsWithExtraRep = cell(1,2);
%for each category, how many times the full set of words appears
nFullRepeats = zeros(1,2);
%and for each category, the number of words that need to appear 1
%extra time
nWordsExtraRep = zeros(1,2);
for ci=1:2
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

    for side = 1:2 %top, bottom
        availableWords = find(wordStats.nAppearances<wordStats.nPlannedAppearances & L.categoryI==wordCatgs(side));
        if side==2
            %set word 2: a word that word 1 hasnt appeared with
            %and hasn't been fully used yet. Also can't be word 1.
            availableWords = setdiff(availableWords, [trialWords(1) wordStats.appearedWith{trialWords(1)}]);
        end
        if ~isempty(availableWords)
            wordi = randsample(availableWords, 1);
        else  
            availableWords = find(L.categoryI==wordCatgs(side));
            availableWords = availableWords(wordStats.nPlannedAppearances(availableWords)==min(wordStats.nPlannedAppearances(availableWords)));
            availableWords = setdiff(availableWords, [trialWords(1) wordStats.appearedWith{trialWords(1)}]);
            
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
        eval(sprintf('task.runTrials.side%iStringFreq(ti) = L.freq(wordi);', side))
    end
    %for both words selected for this trial, save to "appearedWith" the
    %other word, to avoid repetitions of this same pair in subsequent
    %trials
    wordStats.appearedWith{trialWords(1)} = [wordStats.appearedWith{trialWords(1)} trialWords(2)];
    wordStats.appearedWith{trialWords(2)} = [wordStats.appearedWith{trialWords(2)} trialWords(1)];
end

wordStats.nFullCategorySetRepeats = nFullRepeats;
wordStats.nCategoryWordsExtraRepeat = nWordsExtraRep;
task.wordStats = wordStats;


%% pick pre-masks for each trial (from same set of strings, but shown in BACS-2 font)
 %restrict masks to be strings of a certain length
 cLengs = task.strings.lexicon.length;
  lens = unique(cLengs)';

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

%concatenate eye and behavioral data across blocks for 1 participant

function D = PWA_GatherData(subjDir)

exptCodeName = 'PWA_Block.m'; %name of code file that generated data files


%find names of all .mat data files
[matFs, dirs, dirIs] = getFilesByType(subjDir,'mat');
edfFiles = getFilesByType(subjDir, 'edf');

%check which ones are actual data files produced by each block of
%experiment, and excluding practice
nf = numel(matFs);
nBlocks = 0;
blockFs = {}; dateNums = [];
blockDirs = {};
blockBlockNums = [];
accuracies = [];

blockEDFs = {};
hasEDFFile = [];


for fi=1:nf
    clear task scr stairRes stair
    load(matFs{fi});
    if exist('task','var')
        if ~task.practice %exclude practice
            if strcmp(task.codeFilename, exptCodeName)
                nBlocks = nBlocks+1;
                blockFs{nBlocks} = matFs{fi};
                dateNums(nBlocks) = round(datenum(task.startTime(1:3))); %only count year, month, day
                blockDirs{nBlocks} = dirs{dirIs(fi)};
                blockBlockNums(nBlocks) = task.trials.blockNum(1);
                accuracies(nBlocks) = nanmean([task.trials.respCorrect]);
                
                taskSubj = task.subj;
                
                %find EDF files
                fnm = matFs{fi}(1:(end-4));
                matchEDF = [fnm '.edf'];
                ei = find(strcmp(edfFiles,matchEDF));
                
                if length(ei)==1
                    blockEDFs{nBlocks} = edfFiles{ei};
                    hasEDFFile(nBlocks) = true;
                elseif length(ei)>1
                    error('\n(%s) More than 1 edf file matches mat file %s.edf\n', mfilename, fnm);
                elseif isempty(ei)
                    if task.EYE==-1
                        fprintf(1,'\n(%s) WARNING: no eyetracking during recording of mat file \n%s.mat\n\tType dbcont to continue and pretend there were no fixation breaks\n', mfilename, fnm);
                        keyboard
                        
                        hasEDFFile(nBlocks) = false;
                    else
                        fprintf(1,'\n(%s) WARNING: missing edf file for mat file \n%s\n\tType dbcont to continue\n', mfilename, fnm);
                        keyboard
                        hasEDFFile(nBlocks) = false;
                    end
                end
            end
        end
    end
end

%assign each data file to a testing day
[uDates,~,dateIs] = unique(dateNums);


%load in blocks sorted by date
[~,blockLoadOrder]=sort(dateIs);


D = [];
nBlocksIncluded = 0;
for fni=1:length(blockLoadOrder)
    fi=blockLoadOrder(fni);
    
    %% Gather behavioral data from mat files
    fprintf(1,'\n(%s) processing file: ...%s\n',mfilename, blockFs{fi}((end-26):end));
    clear task scr
    load(blockFs{fi});
    B = task.trials;
    datSz = size(B.trialNum);

    B.dateNum = ones(datSz)*dateIs(fi); %add index of this testing day
    B.thisBlockAccuracy = ones(datSz)*accuracies(fi);
    B.subj = repmat(task.subj, datSz);

    B.trialDone(isnan(B.trialDone)) = false;
    
     %add the year, month and day
    B.year  = ones(datSz)*task.startTime(1);
    B.month = ones(datSz)*task.startTime(2);
    B.day   = ones(datSz)*task.startTime(3);

    %add category name 
    B.targetCategoryName = task.strings.categories(B.targetCategory);

    %The category we denote 'signal present' for SDT analysis is Natural
    targCatI = find(strcmp(task.strings.categories,'Natural'));
    %target present 
    B.targPres = strcmp(B.targetCategoryName, 'Natural');

    %whehther the subject reported seeing a 'target' (natural word)
    B.reportedPresence = NaN(size(B.chosenRes));

    B.reportedPresence(B.trialDone==1) = task.buttons.reportedCategory(B.chosenRes(B.trialDone==1))==targCatI;

    B.targetSideName = task.strings.posLabels(B.targetSide)';
    B.cuedSideName = repmat({'Neutral'}, size(B.blockNum));
    if any(B.cueCond>0)
        B.cuedSideName(B.cueCond>0) = task.strings.posLabels(B.cuedSide(B.cueCond>0))';
    end



    scr.scrDims  = scr.rect(3:4); %[h v] number of pixels
    scr.scrCen   = [scr.centerX scr.centerY];
    scr.DPP      = pix2deg(scr.xres,scr.width,scr.subDist,1); % degrees per pixel
    scr.PPD      = deg2pix(scr.xres,scr.width,scr.subDist,1); % pixels per degree

    %stop after we have a certian number of good blocks... no
    excludeBlockByCount =  false;
    B.excludeBlock_TooManyBlocks = ones(size(B.chosenRes))*excludeBlockByCount;
    
    if ~excludeBlockByCount
        nBlocksIncluded = nBlocksIncluded+1;
    end
    
    %check that nothing vital changed across blcoks
    if fni==1
        oldscr = scr;
        oldSubj = task.subj;
        buttons = task.buttons;
    else
        if scr.subDist~=oldscr.subDist || scr.goalResolution(1)~=oldscr.goalResolution(1)
            fprintf(1,'\n\n(%s) Warning! Screen setup changed across blocks.\n\n', mfilename);
        end
        if ~strcmp(oldSubj, task.subj) && ~(str2num(oldSubj) == str2num(task.subj))
            fprintf(1,'\n\n(%s) Warning! Subject changed across blocks!!\n\n', mfilename);
            keyboard
        end
    end
    %% Gather eyelink data
    if ~hasEDFFile(fi)
        fprintf(1,'\n(gatherData) MISSING EDF FILE FOR %s. Pretending no fixation breaks\n',blockFs{fi}((end-26):end));
        
    else
        fprintf(1,'\n(gatherData) processing *edf* file: %s\n',blockEDFs{fi}((end-26):end));
        B = PWA_ComputeEyeData(B,blockEDFs{fi},scr, task);
    end
        
    %% Concatenate data across blocks
    try
        D = [D; B];
    catch
        keyboard
    end
end

%% add some variables
%Compute RT relative to stimulus onset 
D.RT = D.tRes - D.tstimuliOns;

%whether there seemed to be one good sacade
D.offlineGoodSac = D.nTargetSaccades==1;

%lead time of word onset vs saccade onset
D.wordOnset_SaccStart = D.edfTStimOn - D.saccStartTime;
D.wordOffset_SaccEnd = D.edfTStimOff - D.saccLandTime;

%% how much each word overlapped with saccade 
D.propWordDuringSacc = NaN(size(D.blockNum));

noOverlap = (D.wordOnset_SaccStart<0 & D.wordOffset_SaccEnd<0) | (D.wordOnset_SaccStart>0 & D.wordOffset_SaccEnd>0);
D.propWordDuringSacc(noOverlap) = 0;
overlap = ~noOverlap;

wordDurs = D.edfTStimOff - D.edfTStimOn;

%saccade started and finished totally during the word
sacDuring = D.wordOnset_SaccStart<0 & D.wordOffset_SaccEnd>0;
D.propWordDuringSacc(sacDuring) = D.saccDur(sacDuring)./wordDurs(sacDuring);

sacAfter = D.wordOnset_SaccStart<0 & overlap & ~sacDuring;
D.propWordDuringSacc(sacAfter) = (D.edfTStimOff(sacAfter) - D.saccStartTime(sacAfter))./wordDurs(sacAfter);

sacBefore = D.wordOnset_SaccStart>=0 & overlap & ~sacDuring;
D.propWordDuringSacc(sacBefore) = (D.saccLandTime(sacBefore) - D.edfTStimOn(sacBefore))./wordDurs(sacBefore);

% tt = 1450;
% figure; hold on;
% plot([D.edfTStimOn(tt) D.edfTStimOff(tt)], [0 0],'b.-');
% plot([D.saccStartTime(tt) D.saccLandTime(tt)], [1 1],'r.-');
% ylim([-0.5 2])


%%
figure;
t1s = D.wordOnset_SaccStart(D.cueCond>0 & D.trialDone==1 & D.offlineGoodSac==1);
subplot(1,2,1); histogram(t1s); title('Word onset - sacc start'); 

t2s = D.wordOffset_SaccEnd(D.cueCond>0 & D.trialDone==1 & D.offlineGoodSac==1);
subplot(1,2,2); histogram(t2s); title('Word offset - sacc landing');
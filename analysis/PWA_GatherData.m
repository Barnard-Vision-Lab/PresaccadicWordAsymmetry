%concatenate eye and behavioral data across blocks for 1 participant

function allDat = PWA_GatherData(subjDir)

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


allDat = [];
nBlocksIncluded = 0;
for fni=1:length(blockLoadOrder)
    fi=blockLoadOrder(fni);
    
    %% Gather behavioral data from mat files
    fprintf(1,'\n(%s) processing file: ...%s\n',mfilename, blockFs{fi}((end-26):end));
    clear task scr
    load(blockFs{fi});
    blockDat = task.trials;
    blockDat.dateNum = ones(size(blockDat.chosenRes))*dateIs(fi); %add index of this testing day
    blockDat.thisBlockAccuracy = ones(size(blockDat.blockNum))*accuracies(fi);
    
    
    %stop after we have a certian number of good blocks... no
    excludeBlockByCount =  false;
    blockDat.excludeBlock_TooManyBlocks = ones(size(blockDat.chosenRes))*excludeBlockByCount;
    
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
        %NOT DONE YET
        %         fprintf(1,'\n(gatherData) processing *edf* file: %s\n',blockEDFs{fi}((end-26):end));
        %
        %     blockEyeDat = SCA_ComputeEyeData(blockDat,blockEDFs{fi},ipS);
        %
        %     blockDat = catstruct(blockDat,blockEyeDat);
    end
    
    %KLUGE WHILE WE AWAIT EYE ANALYSIS 
    blockDat.offlineFixBreak = false(size(blockDat.chosenRes));
    
    %% Concatenate data across blocks
    try
        allDat = [allDat; blockDat];
    catch
        keyboard
    end
end

%Compute RT relative to stimulus onset 
allDat.RT = allDat.tRes - allDat.tstimuliOns;



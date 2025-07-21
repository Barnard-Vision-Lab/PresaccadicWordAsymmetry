function [subjs, hasNewData] = PWA_FindSubjects(dataDir, resDir)

subjsToExclude = {}; 

minBlocks = 5; %min blocks to analyze

exptName = 'PWA';
exptCodeName = sprintf('%s_Block.m', exptName); %name of code file that generated data files

dfs = getFileNames(dataDir);
dfs = setdiff(dfs, subjsToExclude);

isAFolder = false(size(dfs));
for fi = 1:numel(dfs)
    isAFolder(fi) = isfolder(fullfile(dataDir, dfs{fi}));
end

subjs = dfs(isAFolder);
hasNewData = false(size(subjs));
hasData = true(size(subjs));
for si=1:numel(subjs)
    
    sDir = fullfile(dataDir, subjs{si});
    
    %find names of all .mat data files
    matFs = getFilesByType(sDir,'mat');
    
    %check which ones are actual data files produced by each block of
    %experiment, and excluding practice
    nf = numel(matFs);
    nGoodF = 0;
    totalNTs = 0;
    for fi=1:nf
        clear task scr
        load(matFs{fi});
        if exist('task','var')
            if ~task.practice && strcmp(exptCodeName, task.codeFilename)
                nGoodF = nGoodF+1;
                
                %Exclude trials that were planned but not reached because user quit
                if any(task.trials.userQuit)
                    thisNTs = find(task.trials.userQuit==1)-1;
                else
                    thisNTs = size(task.trials,1);
                end
                totalNTs = totalNTs+thisNTs;
            end
        end
    end
    
    %are there anough blocks to analyze? 
    if nGoodF<minBlocks
        hasData(si)=false;
    else %is there an existing allDat file from previous sessions? 
        allDatF = fullfile(resDir, sprintf('%sAllDat.csv', subjs{si}));
        if ~exist(allDatF, 'file') %if no, then this is all new data
            hasNewData(si) = true; 
        else %if yes, check if any of this data is new:
            clear allDat;
            allDat = readtable(allDatF);
            nAnalyzedTrials = size(allDat, 1);
            hasNewData(si) = nAnalyzedTrials<totalNTs;
        end
    end
end

subjs = subjs(hasData);
hasNewData = hasNewData(hasData);

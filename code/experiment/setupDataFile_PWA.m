function [fullFileName, eyelinkFileName, task] = setupDataFile_PWA(blockNum, task)


% Decide what this data file should be called
theDate = [datestr(now,'yy') datestr(now,'mm') datestr(now,'dd')];
fileName = sprintf('%s_%s',task.subj,theDate);

if task.practice
    fileName = sprintf('%s_prac',fileName);
    task.datadir = task.pracDataFolder;
else
    task.datadir = task.subjDataFolder;
end

% make sure we don't have an existing file in the directory
% that would get overwritten

startFileName = fullfile(task.datadir, sprintf('%s_b%02i',fileName, blockNum));
goodName = ~(exist(sprintf('%s.mat',startFileName),'file') || exist(sprintf('%s.txt',startFileName),'file') || exist(sprintf('%s.edf',startFileName),'file'));

%count of existing files with same name 
bn = 1*~goodName;

if goodName
    fullFileName = startFileName;
else
    while ~goodName
        bn = bn+1;
        fullFileName = sprintf('%s_%02i', startFileName, bn);
        goodName = ~(exist(sprintf('%s.mat',fullFileName),'file') || exist(sprintf('%s.txt',fullFileName),'file') || exist(sprintf('%s.edf',fullFileName),'file'));
    end
end

task.dataFileName = fullFileName;

fprintf(1,'\n\nSaving data file as %s\n\n',fullFileName);

%eyelink file name - must be less than 9 characters long (excluding the .edf)
if task.practice
    extraLet='p';
    eyelinkFileName = sprintf('%s%s_%i%s', task.subj, datestr(now,'dd'), blockNum, extraLet);
else
    if bn==0 %if no prior files exist
        eyelinkFileName = sprintf('%s%s_%i', task.subj, datestr(now,'dd'), blockNum);
    else
        eyelinkFileName = sprintf('%s%s_%i%i', task.subj, datestr(now,'dd'), blockNum,bn);
    end
end

if length(eyelinkFileName)>8 && length(eyelinkFileName)<11
    fprintf(1,'\n(setupDataFile) WARNING eyelinkFileName %s is longer than 8 characters and will cause a crash!\n', eyelinkFileName);
    if bn==0 %if no prior files exist
        eyelinkFileName = sprintf('%s_%i', task.subj, blockNum);
    else
        eyelinkFileName = sprintf('%s_%i%i', task.subj, blockNum,bn);
    end
    fprintf(1,'\n(setupDataFile) So we are deviating from the typical format and removing the date so it is: %s\n', eyelinkFileName);
elseif length(eyelinkFileName)>10
    fprintf(1,'\n(setupDataFile) WARNING eyelinkFileName %s is longer than 10 characters and will cause a crash!\n', eyelinkFileName);
end

task.eyelinkFileName=eyelinkFileName;

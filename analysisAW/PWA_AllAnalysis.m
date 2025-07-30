%% Presaccadic Word Asymmetry Analysis script
%
% This script analyzes each subject's trial-level data in the PWA experiment.
%
% by Alex L. White, Barnard College 2025
%
%
% To Do 
% - compare to edf's auto-detected saccades
% - for each condition compute number of timeouts, number of  good-saccade trials, etc. 
% - consider also further filtering trials by saccade accuracy 

clear; close all;

%% Pathing!
% set paths
paths.proj = fileparts(fileparts(which('PWA_AllAnalysis.m')));
paths.analysis = fullfile(paths.proj,'analysis');
paths.data = fullfile(paths.proj,'data');
paths.results = fullfile(paths.proj,'results');
paths.indivRes = fullfile(paths.results,'indiv');
paths.meanRes = fullfile(paths.results, 'mean');

%checking for correct pathing
fprintf('Project Directory: %s\n', paths.proj);
fprintf('Looking for data in: %s\n', paths.data);


if ~exist(paths.indivRes, 'dir'), mkdir(paths.indivRes); end
if ~exist(paths.meanRes, 'dir'), mkdir(paths.meanRes); end

addpath(genpath(paths.analysis));

%% list of subjects
[subjs, hasNewData] = PWA_FindSubjects(paths.data, paths.indivRes);

N = numel(subjs);

%% choices 
%whether mat files should be gathered together into 1 "allDat" table
doGatherData = 1; %0 = no; 1=for subjects with new data not already in allDat table; 2=for everyone;

%whether each subject's data needs to be analyzed (false if res files already exist)
analyzeEach = 2; %0 = no; 1=for subjects with new data not already in allDat table; 2=for everyone;

%whether each subject's behavioral results should be individually plotted
plotEach = 2; %0 = no; 1=for subjects with new data not already in allDat table; 2=for everyone;

indivFiles = cell(1,N);

%% Main analyses of performance in each condition
for si=1:N
    sDir = fullfile(paths.data,subjs{si});

    allDatName = fullfile(paths.indivRes,sprintf('%sAllDat.csv',subjs{si}));
    resName = fullfile(paths.indivRes, sprintf('%sRes.mat',subjs{si}));
    indivFiles{si} = resName;

    %load this subject's table of trial data:
    if doGatherData==2 || (doGatherData==1 && hasNewData(si))
        d = PWA_GatherData(sDir);
        writetable(d, allDatName);
    else
        d = readtable(allDatName);
    end

    % Analyze the data if required
    if analyzeEach == 2 || (analyzeEach == 1 && hasNewData(si))
        % Perform analysis on the gathered data
       [r, valsByIndex, labelsByIndex] = PWA_AnalyzeSubject(d, resName);
    end

    %for Subject 1, initialize the matrices in allR
    vars = setdiff(fieldnames(r), {'subj'});
    if si==1
        ndimens = zeros(1,numel(vars));
        for vi=1:numel(vars)
            eval(sprintf('vsz = size(r.%s);', vars{vi}));
            %exclude singleton dimensions
            vsz = vsz(vsz>1);
            if isempty(vsz), vsz = 1; end
            matSz = [vsz N];
            ndimens(vi) = length(vsz);
            eval(sprintf('allR.%s = NaN(matSz);', vars{vi}));
        end
    end

    %save these results in a big maxtrix with all subjects
    for vi=1:numel(vars)
        colons = repmat(':,', 1, ndimens(vi));
        eval(sprintf('allR.%s(%s %i) = r.%s;', vars{vi}, colons, si, vars{vi}));
    end
end


%average over subjects
vars = fieldnames(allR);
for vi=1:numel(vars)
    eval(sprintf('rAvg.%s = nanmean(allR.%s, ndims(allR.%s));', vars{vi}, vars{vi}, vars{vi}));
    eval(sprintf('rAvg.SEM.%s = standardError(allR.%s, ndims(allR.%s));', vars{vi}, vars{vi}, vars{vi}));
end
rAvg.valsByIndex = valsByIndex;
rAvg.labelsByIndex = labelsByIndex;
rAvg.subj = 'Mean';

%Save the structure containing all subject results:
allR.subj = subjs;
allR.valsByIndex = valsByIndex;
allR.labelsByIndex = labelsByIndex;

resFileName = 'PWA_MainRes.mat';
resFile = fullfile(paths.meanRes,resFileName);
save(resFile, 'allR','rAvg');

%% 
PWA_PlotScript;
%PWA_IndividualPlotScript;


%% Presaccadic Word Asymmetry Analysis script
%
% This script analyzes each subject's trial-level data in the PWA experiment.
%
% by Alex L. White, Barnard College 2025

% To Do 
%  
clear; close all;

%% set paths
paths.proj = fileparts(fileparts(which('PWA_AllAnalysis.m')));
paths.analysis = fullfile(paths.proj,'analysis');
paths.data = fullfile(paths.proj,'data');

%checking for correct pathing
fprintf('Project Directory: %s\n', paths.proj);
fprintf('Looking for data in: %s\n', paths.data);

paths.res = fullfile(paths.proj,'results');

paths.indivRes = fullfile(paths.res,'indiv');
paths.meanRes = fullfile(paths.res, 'mean');

if ~exist(paths.indivRes, 'dir'), mkdir(paths.indivRes); end
if ~exist(paths.meanRes, 'dir'), mkdir(paths.meanRes); end

addpath(genpath(paths.analysis));

%% list of subjects
[subjs, hasNewData] = PWA_FindSubjects(paths.data, paths.indivRes);

N = numel(subjs);

%% choices 
%whether mat files should be gathered together into 1 "allDat" table
doGatherData = 2; %0 = no; 1=for subjects with new data not already in allDat table; 2=for everyone;

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
     
    
     %Analyze trials: NEEDS TO BE WRITTEN
%      if analyzeEach==2 || (analyzeEach==1 && hasNewData(si))
%          [r, valsByIndex, labelsByIndex] = PWA_AnalyzeSubject(d);
%          r.subj = subjs{si};
%          
%          save(resName, 'r', 'valsByIndex', 'labelsByIndex');
%      else
%          load(resName);
%      end
%     %for Subject 1, initialize the matrices in allR
%     vars = fieldnames(r);
%     vars = setdiff(vars, {'subj','analysisParams','psychometric'});
%     if si==1
%         nDimensions = zeros(1,numel(vars));
%         for vi=1:numel(vars)
%             eval(sprintf('vsz = size(r.%s);', vars{vi}));
%             %exclude singleton dimensions
%             vsz = vsz(vsz>1);
%             if isempty(vsz), vsz = 1; end
%             matSz = [vsz N];
%             nDimensions(vi) = length(vsz);
%             eval(sprintf('allR.%s = NaN(matSz);', vars{vi}));
%         end
%     end
%     
%     %save these results in a big maxtrix with all subjects
%     for vi=1:numel(vars)
%         colons = repmat(':,', 1, nDimensions(vi));
%         eval(sprintf('allR.%s(%s %i) = r.%s;', vars{vi}, colons, si, vars{vi}));
%     end
%     
%     if plotEach==2 || (plotEach==1 && hasNewData(si))
%          %ADD CODE TO PLOT
%     end
end

%% average over subjects
% vars = fieldnames(allR);
% for vi=1:numel(vars)
%     eval(sprintf('rAvg.%s = nanmean(allR.%s, ndims(allR.%s));', vars{vi}, vars{vi}, vars{vi}));
%     eval(sprintf('rAvg.SEM.%s = standardError(allR.%s, ndims(allR.%s));', vars{vi}, vars{vi}, vars{vi}));
% end
% 
% %Save the structure containing all subject results:
% allR.valsByIndex = valsByIndex;
% allR.valsByIndex.subject = subjs;
% 
% allR.labelsByIndex = labelsByIndex';
% 
% rAvg.valsByIndex = valsByIndex;
% rAvg.labelsByIndex = labelsByIndex';
% rAvg.analysisParams = r.analysisParams;
% rAvg.subj = 'Mean';
% 
% resFileName = 'PWA_MainRes.mat';
% resFile = fullfile(paths.meanRes,resFileName);
% save(resFile, 'allR', 'rAvg');

%% make plots of average


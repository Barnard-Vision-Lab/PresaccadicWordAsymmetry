%% Presaccadic Word Asymmetry Analysis script
%
% This script analyzes each subject's trial-level data in the PWA experiment.
%
% by Alex L. White, Barnard College 2025
%
% It also calculates accuracy and generates some rough plots (in progress)
% 
% Mariam Latif

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

%% Looping through all participants & determining accuracy scores
%% Definitions and Paths
file_names = arrayfun(@(id) sprintf('%dAllDat', id), str2double(subjs), 'UniformOutput', false);
 
%define attention conditions (depending on cue)
cueCond = {'Neutral';'Valid';'Invalid'};
nAttns = length(cueCond);

%define target sides (which side was post-cued) 
sides = {'left';'right'};
nSides = length(sides);

N = length(str2double(subjs)); %how many subjects;

%pre-define a 3-dimensional matrix that will hold the results (proportion correct in each condition) 
PCs = NaN(nAttns, nSides, N); % subjects are in the last dimension 

%% Creating one figure for overlayed histograms
figure; 
hold on;
colors = lines(N);

%% Looping through subjects
for i = 1:N
    % Creating the full file name
    all_data = fullfile(paths.indivRes, [file_names{i} '.csv']);
    % Reading the CSV file into a variable
    d = readtable(all_data);

    %Filter out trials that were not completed
    goodTrials = d.trialDone==1; % only includes completed trials 

    d = d(goodTrials,:);

    %add a variable for the difference between the time of word offset relative to the time of saccade onset
    d.wordSaccOffOn = cell(size(d.tLanded));
    d.wordSaccOffOn = d.tLanded-d.tstimDotsISIOns

    %make a histogram of the time of word offset relative to the time of
    %saccade onset (overlays participants over each other)
    histogram(d.wordSaccOffOn, ...
              'FaceColor', colors(i,:), ...
              'EdgeColor', 'none', ...
              'FaceAlpha', 0.3); % transparency

    %add a variable to this table that says whether each trial was valid,
    %invalid, or neutral 

    % NOTE: for the cued condition this is when tLanded is after tstimDotsISIOns 
    d.attnCond = cell(size(d.cueValidity));
    d.attnCond(d.cueValidity==0) = {'Neutral'}; %cueCond 0 is Neutral
    d.attnCond(d.cueValidity==1 & d.tLanded > d.tstimDotsISIOns) = {'Valid'}; %cue cond is Valid and when tLanded is after tstimDotsISIOns 
    d.attnCond(d.cueValidity==-1 & d.tLanded > d.tstimDotsISIOns ) = {'Invalid'}; %cue cond is Invalid when tLanded is after tstimDotsISIOns 

    %add target sides
    d.side = sides(d.targetSide); %targetSide a single number, 1 or 2 

    %loop through attention conditions 
    for a = 1:nAttns
        %define a boolean vector that's true for each trial of this
        %attention condition 
        attnTrials = strcmp(d.attnCond, cueCond{a});

            %loop through cue target sides 
            for s = 1:nSides
               % taking trials on the left or right side
                    sideTrials = strcmp(d.side, sides{s});
                %end

                %theseTrials is a Boolean vector that is true only for
                %trials that are at the intersection of all three types of
                %conditions
                theseTrials = attnTrials & sideTrials;

                %now analyze accuracy for each sub-set of trials
                PCs(a, s, i) = mean(d.respCorrect(theseTrials));

            end
       end
 end

%% Figure Edits
xline(0, 'r-', 'Word Disappears', 'LabelHorizontalAlignment', 'left');
xlabel('Difference: tLanded - tstimDotsISIOns');
ylabel('Count');
title('Overlayed Histograms of Word Offset Relative to Saccade Onset');
legend(subjs, 'Location', 'Best');
hold off;
 
%% Averaging over subjects, and calculating the SEM. 
% (Note that you can now do this afor all conditions at the same time, 
% rather than a separate command for each condition)

%meanPCS = mean(PCs, ndims(PCs),'omitnan'); %take the mean over the last dimension 
%semPCs = standardError(PCs, ndims(PCs));
% a (very) rough visualization
figure; 
hold on;
plot(PCs); % note that it will be at meanPCS when the next participant is included
           % right now there is only one participant so it will average
           % over side (left & right)
hold on;
xlabel('Cue Validity');
xticks([1 2 3])
xticklabels(cueCond)
ylabel('Mean Accuracy');
legend('left','right')
sgtitle('Mean Accuracy per Cue Validity Condition')
hold off;

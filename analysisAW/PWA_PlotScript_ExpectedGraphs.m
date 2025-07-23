%% Plot mean performance in the PWA experiment 
clear; close all;

%find paths
paths.proj = fileparts(fileparts(which('PWA_AllAnalysis.m')));
paths.analysis = fullfile(paths.proj,'analysis');
paths.data = fullfile(paths.proj,'data');
paths.results = fullfile(paths.proj,'results');
paths.indivRes = fullfile(paths.results,'indiv');
paths.meanRes = fullfile(paths.results, 'mean');

% Load the results file for analysis
resFile = fullfile(paths.meanRes,'PWA_MainRes.mat');
load(resFile, 'allR','rAvg');

sf = 1; %where to print stats to (1=command window)

%% plot 1 - bar plot of accuracy for left word, right word in each cue condition (neutral, cue left, cue right)

% % define which conditions to pull out of the "rAvg" structure 
conds.cue = 2:4; %neutral, left, right
conds.side = 2:3; %left, right 
conds.length = 1; %not dividing by word length
conds.timeBin = 1; %not diviving by time bin relative to saccade
conds.half = 1; %not splitting data into 1st or 2nd half 

%labels for each of these conditions 
cueLabs = rAvg.labelsByIndex.cuedSide(conds.cue);
sideLabs = rAvg.labelsByIndex.targetSide(conds.side);

nCue = length(conds.cue);
nSide = length(conds.side);

%% extract mean dprime in each condition
ms = [0.9 2.4; 1.5 0.85; 0.5 2.6];
%ms = [0.9 2.4; 0.9 2.4; 0.9 2.4];
%extract standard errors of dprime in each condition 
es = zeros(3,2);

% To make prediction graphs: replace "ms" with your own 3x2 matrix, where
% the rows are neutral, cue left, right right. The colums are left word, right word. 
% Then "es" could be set to zeros(3,2) 



%% plot parameters 
% % set the colors for left word, right word
hues = [0 0.573];
sats = [0.62 1];
vals = [0.9 0.5];

edgeColrs = hsv2rgb([hues' sats' vals']);

opt = struct;
opt.edgeColors = NaN(3,2,3);
opt.fillColors = NaN(3,2,3);

for cs = 1:nCue
    for si = 1:nSide
        opt.edgeColors(cs, si, :) = edgeColrs(si,:);
        opt.fillColors(cs, si, :) =  edgeColrs(si,:);
    end
end
opt.errorBarColors = opt.edgeColors*0.33;


opt.xTickLabs = cueLabs;
opt.xLab = 'Cued side';
opt.doLegend = false;
opt.legendLabs = sideLabs;
opt.legendTitle = 'Word side';
opt.legendLoc = 'North';
opt.ylims = [0 4];
opt.yticks = 0:1:4;
opt.yLab = 'd''';

%Figure size (in cm) and font size 
figSize = [14 19]; %wid, height
fontSize = 25;


nRows = 2; nCols = 1;
figure; 

subplot(nRows, nCols, 1); hold on;

%% Panel A: Plot the means in each condition
barPlot_AW(ms, es, opt);
set(gca,'FontSize', fontSize)


%% Panel B: plot magnitude of asymmetry

AsE = zeros(3,1);
AsM = diff(ms,1,2);

subplot(nRows,nCols,2); hold on;
asymColr = hsv2rgb(0.7,0.4, 0.85);
%plot(xlims, [0 0],'k-');

opt.xTickLabs = cueLabs;
opt.xLab = 'Cued side';
opt.doLegend = false;
opt.ylims = [-1 3];
opt.yticks = opt.ylims (1):opt.ylims (2);
opt.yLab = '\Deltad''';
opt.edgeColors = 0.7*repmat(asymColr, nCue, 1);
opt.fillColors = repmat(asymColr, nCue, 1);
opt.errorBarColors = 0.5*opt.fillColors;
opt.barWidth = 0.14;

barPlot_AW(AsM, AsE, opt)

title('Hemifield asymmetry (R-L)');
set(gca,'FontSize', fontSize);

%% Save this figure 
set(findall(gcf, 'Type', 'Text'),'FontWeight', 'Normal','FontSize',fontSize);
set(gcf,'color','w','units','centimeters','pos',[5 5 figSize]);
figTitle = fullfile(paths.meanRes,"PWA_dprime_barsPred2.pdf");
exportgraphics(gcf, figTitle, 'Padding','tight','PreserveAspectRatio','on');



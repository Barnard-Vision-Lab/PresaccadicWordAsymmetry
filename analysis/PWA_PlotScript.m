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

sf = fopen(fullfile(paths.meanRes, 'PWAStats.txt'),'w'); %where to print stats to (1=command window)

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
N = length(allR.subj);

%% extract mean dprime in each condition
ms = squeeze(rAvg.dprime(conds.cue, conds.side, conds.length, conds.timeBin, conds.half));

%extract standard errors of dprime in each condition 
es = squeeze(rAvg.SEM.dprime(conds.cue, conds.side, conds.length, conds.timeBin, conds.half));


%calculate asymmetries in each cue condition: 
AsM = NaN(nCue, 1); %means of asymmetries
AsE = NaN(nCue, 1, 2); %error bars: 95% CIs of asymmetries
indivAs = NaN(nCue, N);
for cv = 1:nCue
    is = squeeze(allR.dprime(conds.cue(cv), conds.side, conds.length, conds.timeBin, conds.half,:));
    as = diff(is);

    fprintf(sf, '\nHemifield asymmetry (R-L dprime) for %s cue condition:\n', cueLabs{cv});
    [tStat, bayesFactor, CI, sigStars, sampleMean, sampleSEM] = diffStats(as, sf);
    
    AsM(cv) = sampleMean;
    AsE(cv,1,:) = CI;
    indivAs(cv,:) = as;
end

%stats comparing asymmetry across cue conditions
cueComps = [1 2; 1 3; 2 3];
for cc = 1:size(cueComps,1)
    cvs = cueComps(cc,:);
    compAs = indivAs(cvs,:);
    fprintf(sf, '\nComparing the hemifield asymmetry across %s and %s cue conditions:\n', cueLabs{cvs(1)}, cueLabs{cvs(2)});
    [tStat, bayesFactor, CI, sigStars, sampleMean, sampleSEM] = diffStats(diff(compAs), sf);

end

%cue benefits and costs for each position 
neutI = find(strcmp(cueLabs, 'Neutral'));
for si = 1:2 %left word, right word
    fprintf(sf,'\n\nCue effects for words on the %s:\n', sideLabs{si});
    for bc = 1:2 %benefit, cost
        if bc==1
            compI = find(strcmp(cueLabs, sideLabs{si}));
            fprintf(sf,'\nCue benefit (%s cue - %s cue):\n\t', cueLabs{compI}, cueLabs{neutI});

        else
            compI = find(strcmp(cueLabs, sideLabs{3-si}));
            fprintf(sf,'\nCue cost (%s cue - %s cue):\n\t', cueLabs{compI}, cueLabs{neutI});
            
        end
            
        is = squeeze(allR.dprime(conds.cue([neutI compI]), conds.side(si), conds.length, conds.timeBin, conds.half,:));
        [tStat, bayesFactor, CI, sigStars, sampleMean, sampleSEM] = diffStats(diff(is), sf);

    end
end


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
opt.legendLabs = sideLabs;
opt.legendTitle = 'Word side';
opt.legendLoc = 'North';
opt.ylims = [0 3.5];
opt.yticks = 0:1:4;
opt.yLab = 'd''';

%Figure size (in cm) and font size 
figSize = [15 19]; %wid, height
fontSize = 20;


nRows = 2; nCols = 1;
figure; 

subplot(nRows, nCols, 1); hold on;

%% Panel A: Plot the means in each condition
barPlot_AW(ms, es, opt);
set(gca,'FontSize', fontSize)


%% Panel B: plot magnitude of asymmetry
subplot(nRows,nCols,2); hold on;
asymColr = hsv2rgb(0.7,0.4, 0.85);
%plot(xlims, [0 0],'k-');

opt.xTickLabs = cueLabs;
opt.xLab = 'Cued side';
opt.doLegend = false;
opt.ylims = [0 3.5];
opt.yticks = opt.ylims(1):opt.ylims(2);
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
figTitle = fullfile(paths.meanRes,"PWA_dprime_bars.pdf");
exportgraphics(gcf, figTitle); %, 'Padding','tight','PreserveAspectRatio','on');


%% Plot 2: accuracy vs time (of word onset relative to saccade onset)

%figure size, in cm (width, height)
figSize = [15 13];

%plot parameters
neutSats = [0.3 0.3];
neutVals = [0.8 0.7];
neutColrs =  hsv2rgb([hues' neutSats' neutVals']);

neut = find(strcmp(rAvg.labelsByIndex.cuedSide,'Neutral'));
neutDs = rAvg.dprime(neut, conds.side, conds.length, 1, conds.half);
neutEs = rAvg.SEM.dprime(neut, conds.side, conds.length, 1, conds.half);

% which conditions to pull out
cueSs = {'Left','Right'};
conds.cue = find(ismember(rAvg.labelsByIndex.cuedSide,cueSs));
cueSs = rAvg.labelsByIndex.cuedSide(conds.cue);
targSs = rAvg.labelsByIndex.targetSide(conds.side);
conds.timeBin = find(~isnan(rAvg.valsByIndex.wordOnsetReSaccTimeBin));

edgeIs = rAvg.valsByIndex.wordOnsetReSaccTimeBin(conds.timeBin);
edgeIs = [edgeIs edgeIs(end)+1]; %get the right edge of last bin 
edges = rAvg.wordOnsetTimeBinEdges(edgeIs);
xvals = cell2mat(rAvg.labelsByIndex.wordOnsetReSaccTimeBin(conds.timeBin));

neutX = -285;
xlims = [neutX-40 20];
ylims = [0 4.2];
xticks = [neutX -200:50:0];
yticks = 0:1:4;

marks = {'s-','o-'};
markSz = 10;

%% Extract data
ms = squeeze(rAvg.dprime(conds.cue, conds.side, conds.length, conds.timeBin, conds.half));
es = squeeze(rAvg.SEM.dprime(conds.cue, conds.side, conds.length, conds.timeBin, conds.half));
xs = squeeze(rAvg.meanWordOnset_SaccStart(conds.cue, conds.side, conds.length, conds.timeBin, conds.half));

%% Plot
figure; hold on;


%plot borders of bins... or not 
% for tb=1:length(edges)
%     plot(edges([tb tb]), ylims, ':', 'Color', [0.7 0.7 0.7]);
% end
plot([0 0],ylims, 'k-');
%plot neutrals
for si=1:2
    faceColr = neutColrs(si,:);
    plot(xlims, neutDs([si si]),'-', 'Color',neutColrs(si,:));
    plot([neutX neutX], neutDs(si)+[-1 1]*neutEs(si), '-','Color', edgeColrs(si,:),'LineWidth',1);
    plot(neutX, neutDs(si),  marks{si}, 'Color', edgeColrs(si,:), 'MarkerFaceColor',faceColr,'MarkerEdgeColor', edgeColrs(si,:),'markerSize', markSz,'LineWidth',2);
end

%plot cued trials
cc = 0; %condition counter
hs = zeros(1,4);
legLabs = cell(1,4);

for si=[2 1]
    for cv=[2 1]
        cc = cc+1;

        % if strcmp(cueSs{cv},'Left'), faceColr = 'w';
        % else, faceColr = edgeColrs(si,:);
        % end

        %congruent trials are filled
        if strcmp(cueSs{cv}, targSs{si})
            faceColr = edgeColrs(si,:);
        else %incongruent (invalid) trials are open 
            faceColr = 'w';
        end
        xvals = squeeze(xs(cv, si,:));
        for tb=1:length(conds.timeBin)
            plot(xvals([tb tb]), ms(cv,si,tb)+[-1 1]*es(cv,si,tb), '-','Color', edgeColrs(si,:),'LineWidth',1);
        end
        hs(cc)=plot(xvals, squeeze(ms(cv, si, :)), marks{si}, 'Color', edgeColrs(si,:), 'MarkerFaceColor',faceColr,'MarkerEdgeColor', edgeColrs(si,:),'markerSize', markSz,'LineWidth',1);
        legLabs{cc} = sprintf('%s word, %s cue', sideLabs{si}(1),cueSs{cv}(1));

    end
end


set(gca, 'xtick', xticks,'ytick',yticks);
xlabs = get(gca,'XTickLabel');
xlabs{1} = 'Neutral';
xlabs{3} = '';
xlabs{5} = '';
set(gca,'XTickLabel', xlabs,'FontSize', fontSize);
xtickangle(0);
xlabel('Time btwn. saccade and word onset (ms)');
ylabel('d''')
title('Accuracy as time approaches the saccade');
legend(hs, legLabs,'Location','NorthWest');
xlim(xlims);
ylim(ylims);

% % Save Figure 2

set(findall(gcf, 'Type', 'Text'),'FontWeight', 'Normal','FontSize',fontSize);
set(gcf,'color','w','units','centimeters','pos',[5 5 figSize]);
figTitle = fullfile(paths.meanRes,"PWA_timecourse.pdf");
exportgraphics(gcf, figTitle); %, 'Padding','tight','PreserveAspectRatio','on');
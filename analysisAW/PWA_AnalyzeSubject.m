% function [r] = PWA_AnalyzeSubject(d)
% Analyze 1 subject's data.
% 
% Inputs: 
% d: table with information about each trial
% fileName: directly for where this all shoudl be save  
%
% Outputs: 
% - r: one big results structure, with various matrices (e.g., PC for
%    proportion correct). 
% - valsByIndex: a structure with one field that labels the parameter that corresponds to each dimension the
%    results matrices in "r".  Each field is a vector, and each value i in the vector
%    labels the value of the parameter for the ith level of that dimension
%    in the data matrix. 
% - AOCIndices: like valsByIndex, but just for the AOC parameters stored in
%    r (r.pProcessBoth, etc)
%
% by Alex L. White, Barnard College, 2021

function [r, valsByIndex, labelsByIndex] = PWA_AnalyzeSubject(d, fileName)

finishedTrials = find(d.trialDone==1);

%% trials to be analyzed: when the word did not get fixated and didn't overlap with saccade too much 
d.goodSacTrial = true(size(d.trialDone));
d.goodSacTrial(~d.trialDone==1) = false;
d.goodSacTrial(finishedTrials) = d.offlineGoodSac(finishedTrials) & d.wordOnset_SaccStart(finishedTrials)<=0 & d.wordOffset_SaccEnd(finishedTrials)<0 & d.propWordDuringSacc(finishedTrials)<0.5;
%but for neutral trials, saccade stuff doesnt matter
d.goodSacTrial(d.cueCond==0) = d.trialDone(d.cueCond==0) == 1;


goodTrials = find(d.goodSacTrial);


%add half. "total trial num" covers all trials in the table
d.totalTrialNum = NaN(size(d.trialDone));
d.totalTrialNum(finishedTrials) = (1:length(finishedTrials))';
d.half = NaN(size(d.cueCond));
d.half(finishedTrials)=1;
d.half(d.totalTrialNum>(max(d.totalTrialNum)/2)) = 2;

%Add the length of the string that was post-cued for each response 
d.targetLength = d.side1StringLength;
d.targetLength(d.targetSide==2) = d.side2StringLength(d.targetSide==2);

%% 
%time bins by word onset re. saccade onset 
timeTs = d.cueCond>0 & d.trialDone==1 & d.offlineGoodSac==1;
ts = d.wordOnset_SaccStart(timeTs);

timeBins = [-500 -250 -100 0 500];
[N,edges,binI] = histcounts(ts,timeBins);

%exclude binI=0 which means trials outside of nay time bin 
binI(binI==0) = NaN;

d.wordOnsetReSaccTimeBin = NaN(size(d.blockNum));
d.wordOnsetReSaccTimeBin(timeTs) = binI;
r.wordOnsetTimeBinEdges = edges;

%% 

%Parameters by which to divide up the data:
splitParams = {'cuedSide','targetSide','targetLength','wordOnsetReSaccTimeBin','half'}; 

%Construct splitTrials, which stores lists of trials that match each
%condition; and valsByIndex, a structure that serves as a guide to the
%resulting data matrices (label each dimension and each value within the
%dimensions). 
nLevsPerParam = NaN(1,numel(splitParams)); 

for bpi=1:numel(splitParams)
    bp=splitParams{bpi};
    
    eval(sprintf('ulevs=unique(d.%s(goodTrials));',bp));
    ulevs = ulevs(~isnan(ulevs));
    
    nlevs=length(ulevs);
    if length(ulevs)>1
        eval(sprintf('splitTrials.%s{1}=1:numel(d.respCorrect);',bp));
        eval(sprintf('valsByIndex.%s(1)=NaN;',bp));
        nextra=1;
    else
        nextra=0;
    end
    nLevsPerParam(bpi)=nlevs+nextra;
    
    for li=1:nlevs
        eval(sprintf('splitTrials.%s{li+%i}=find(d.%s==ulevs(li));',bp,nextra,bp));
        eval(sprintf('valsByIndex.%s(li+%i)=ulevs(li);',bp,nextra));
    end    
end
    
if bpi == 1, dSz=[1 nLevsPerParam]; 
else dSz = nLevsPerParam; end


%% add text labels for each condition
for bpi=1:numel(splitParams)
    bp=splitParams{bpi};
    eval(sprintf('vals = valsByIndex.%s;', bp));
    labls = cell(1,nLevsPerParam(bpi));
    for li=1:nLevsPerParam(bpi)
        if isnan(vals(li))
            labl = 'All';
        else
            switch bp
                case 'cuedSide'
                    labl = unique(d.cuedSideName(d.cuedSide==vals(li)));
                    labl = labl{1};
                case 'targetSide'
                    labl = unique(d.targetSideName(d.targetSide==vals(li)));
                    labl = labl{1};
                case {'targetLength','half'}
                    labl = vals(li);
                case 'wordOnsetReSaccTimeBin'
                    labl = mean([r.wordOnsetTimeBinEdges(vals(li):(vals(li)+1))]);
            end
        end
        labls{li} = labl;
    end
    eval(sprintf('labelsByIndex.%s = labls;',bp));
end

%% initialize the big matrices in the "r" structure that will store each variable 
testr = PWA_AnalyzeTrials(d(goodTrials,:));  %find out what the output variables are by analyzing the whole data set together
vars = fieldnames(testr);
%initialize each matrix in r;
for vi=1:numel(vars)
    eval(sprintf('r.%s = NaN(dSz);', vars{vi}));
end

%% Create a huge command (called "cmd") to then execute with "eval"
% That command divides up trials according to each combination of all the parameters 
% in splitParams and analyzes each subset of trials

%First, set up nested "for" loops to go through each condition; 
trials0=1:numel(d.respCorrect);
cmd=''; itext='('; 
for pni=1:numel(splitParams)
    pn=splitParams{pni};
    
    cmd=sprintf('%s \n%s',cmd,sprintf('for %sI=1:numel(splitTrials.%s)',pn,pn));
    cmd=sprintf('%s \n%s',cmd,sprintf('\ttrials%i=intersect(trials%i,splitTrials.%s{%sI});',pni,pni-1,pn,pn));
    itext=sprintf('%s%sI,',itext,pn);  
end

itext=sprintf('%s)',itext(1:(end-1)));

%theseTrials: the list of trials that match this *combination( of conditions
cmd=sprintf('%s\n\t%s',cmd,sprintf('theseTrials=intersect(trials%i,goodTrials);',pni));

%CALL THE FUNCTION TO ANALYZE THIS SET OF TRIALS
cmd=sprintf('%s\n%s',cmd,'subRes = PWA_AnalyzeTrials(d(theseTrials,:));');

%Then store the data in the matrices in "r"
for vi=1:numel(vars)
    thisVar = vars{vi};
    cmd=sprintf('%s\n\t%s',cmd,sprintf('r.%s%s=subRes.%s;',thisVar,itext,thisVar));
end


%Analyze fixation breaks without filtering out trials with fixation breaks
cmd=sprintf('%s\n\t%s',cmd,sprintf('theseTrialsEye=trials%i;',pni));
cmd=sprintf('%s\n\t%s',cmd,sprintf('r.pFixBreak%s = nanmean(d.fixBreak(theseTrialsEye)==1);',itext));


for pni=1:numel(splitParams)
    cmd=sprintf('%s\nend',cmd);
end

%Now use "eval" to execute cmd
try
    eval(cmd)
catch me
    display(cmd);
    keyboard
end

%save 
save(fileName, 'r','valsByIndex','labelsByIndex');
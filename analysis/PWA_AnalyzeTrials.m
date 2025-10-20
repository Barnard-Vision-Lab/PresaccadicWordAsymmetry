function r = PWA_AnalyzeTrials(d)

presTrials = find(d.targPres);
abstTrials = find(~d.targPres);
correctTrials = find(d.respCorrect);


%compute percent correct
r.PC=mean(d.respCorrect);

%mean report presence 
r.pReportPres = mean(d.reportedPresence);

%Hit rate
r.hitR = mean(d.reportedPresence(presTrials));
npres = length(presTrials);

%false alarm rate
r.FAR = mean(d.reportedPresence(abstTrials));
nabst = length(abstTrials);

%Compute dprime
[r.dprime, r.crit, r.crit2, r.beta, r.usedHitR, r.usedFAR, r.dCorrected] = computeDCFromRates(r.hitR,r.FAR,npres,nabst);

%Geometric mean of RTs - mean of log10(rts), then antilogged
r.meanRTs=10.^mean(log10(d.RT));
r.meanCorrRTs=10.^mean(log10(d.RT(correctTrials)));

%compute number of trials, only icluding the rows for the 1st response on
%each trial
r.ntrials = size(d,1); 

%stim timing variables 
r.meanWordOnset_SaccStart = mean(d.wordOnset_SaccStart);
r.meanPropWordDuringSacc = mean(d.propWordDuringSacc);

%saccade latencies:
r.meanSaccLat = mean(d.saccLatency);

%saccade errors: 
r.meanSaccError = mean(d.saccError);
r.meanSaccError_horiz = mean(d.saccErrorX);
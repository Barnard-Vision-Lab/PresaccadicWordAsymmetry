function plotStaircaseRes(task)

figure;
for ti=1:task.stair.nTypes
    for si=1:task.stair.nPerType
        sbpi = (ti-1)*task.stair.nPerType+si;
        subplot(task.stair.nTypes,task.stair.nPerType,sbpi); hold on;
        if task.stairType==3
            plotSIAM(task.stair.ss{ti,si},task.stair.threshType);
        elseif task.stairType==2
            if task.stair.inLog10
                inputThresh = log10(task.stair.threshEstimates(ti,si));
            else
                inputThresh = task.stair.threshEstimates(ti,si);
            end
            plotUDStair(task.stair.q{ti,si},task.stair.inLog10,inputThresh);
        end
        title(sprintf('Staircase [%i, %i], thresh %.3f',ti,si,task.stair.threshEstimates(ti,si)));
    end
    
    fprintf(1,'\n\nStaircase threshold estimate for type %i: %.3f\n',ti,task.stair.meanThreshs(ti));
end

fprintf(1,'\nMean staircase averaging across types: %.4f\n\n',mean(task.stair.meanThreshs));

%Save: 
stairRes.subj = task.subj;
stairRes.date = date;
stairRes.whichTask = task.whichTask;
stairRes.wordContrast = task.words.contrast;
stairRes.maskType = task.words.maskType; 
stairRes.leftThreshold = task.stair.meanThreshs(1); 
stairRes.rightThreshold = task.stair.meanThreshs(2);
stairRes.meanThreshold = mean(task.stair.meanThreshs);

bn=0; 
goodname = false;
while ~goodname
    bn = bn+1;
    aname = sprintf('StairRes_%s_%s_%i.mat',task.subj,date,bn);
    fname = fullfile(task.subjDataFolder,aname);
    goodname = ~exist(fname,'file');
end
save(fname,'stairRes');
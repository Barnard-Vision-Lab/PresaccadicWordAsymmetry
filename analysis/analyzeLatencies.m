function [df,t,p, BF] = analyzeLatencies(allR)
    sacLats = squeeze(allR.meanSaccLat(3:4,1,1,1,1,:));
    meanLats = mean(sacLats,2);
    fprintf('Mean Left Latency: %.2f ms\n', meanLats(1));
    fprintf('Mean Right Latency: %.2f ms\n', meanLats(2));
    
    %Compute paired differences
    diffs = sacLats(1,:) - sacLats(2,:);
    
    %Run diffStats
    statsF = 1;

    disp("Running diffStats now...");

    [tStat, bayesFactor] = diffStats(diffs, statsF); %BCFlag, CIRange, nReps, compVal, weights);
 
    disp("Finished diffStats call!");

    df = tStat.df;
    t = tStat.tstat;
    p = tStat.pval;
    BF = bayesFactor;
end

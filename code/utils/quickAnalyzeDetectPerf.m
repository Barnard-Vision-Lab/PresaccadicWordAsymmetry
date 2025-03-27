function res = quickAnalyzeDetectPerf(task)

goodTrials=find(task.data.trialDone & ~task.data.pressedQuit);
presTrials=find(task.data.targPres); 
absTrials = find(~task.data.targPres); 

res.overallPC  = mean(task.data.respCorrect(goodTrials)); 
res.overallFAR = 1-mean(task.data.respCorrect(intersect(absTrials,goodTrials)));
res.overallHR  = mean(task.data.respCorrect(intersect(presTrials,goodTrials)));
res.overallD   = norminvFree(res.overallHR)-norminvFree(res.overallFAR); 


D = readtable("294AllDat.csv");

D.word = cell(size(D.targetSide));
D.word(D.targetSide==1) = D.side1String(D.targetSide==1);
D.word(D.targetSide==2) = D.side2String(D.targetSide==2);

D = D(D.trialDone==1 & D.cueCond==0, :);

lme = fitglme(D, 'respCorrect ~ targetSideName + (1| word)','Link', 'logit','Distribution','Binomial');
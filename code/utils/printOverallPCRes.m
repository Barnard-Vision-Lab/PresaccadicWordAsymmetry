%save simple file to check overall PC

global scr;
     
scanPCs = scanPCs(1:nScansDone);
overall = mean(scanPCs);

cueBlocksDone = cueBlocks(1:nScansDone,:);

%pick a name for this results text file
goodName = false; bn = 0;

while ~goodName
    bn = bn+1;
    txtFName = sprintf('%s_%s_%i_PC%i_%i.txt',subj,date,scanNumber,round(100*overall),bn);
    fullFileName = fullfile(scr.datadir,txtFName);
    goodName = ~exist(fullFileName,'file');
end

fid = fopen(fullFileName,'w');

fprintf(fid,'Overall PC res for %i scans for subject %s on date %s\n\n',nScansDone, subj, date);
nDual = sum(cueBlocksDone(:) == 0);
nST = sum(cueBlocksDone(:) > 0); 
nSS = sum(cueBlocksDone(:) < 0); 

fprintf(fid,'%i blocks, of which %i were dual-task, %i were single task, and %i single stimulus\n\n',numel(cueBlocksDone),nDual,nST,nSS);
fprintf(fid,'Cue block order, by scan:\n');
for scani = 1:nScansDone
    fprintf(fid,'%i\t',cueBlocksDone(scani,:));
    fprintf(fid,'\n');
end

fprintf(fid,'\nGabor contrast: %.3f\n',gaborContrast);

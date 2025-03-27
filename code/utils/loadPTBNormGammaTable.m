function calib = loadPTBNormGammaTable(calibFile)

global scr task

BackupCluts;
if numel(calibFile)>0 
    load(calibFile);
    if task.doDataPixx
        PsychColorCorrection('SetLookupTable',scr.main,calib.table);
    else
        if size(calib.table,2)==1
            calib.table = repmat(calib.table,1,3);
            fprintf(1,'\n(loadPTBNormGammaTable) Calibration normalized gamma table has only 1 column. \n Assuming equal for all 3 guns\n.');
        end
        Screen('LoadNormalizedGammaTable',scr.main,calib.table);
    end
    fprintf('\n(loadPTBNormGammaTable) Loaded calibration file normalized gamma table: %s\n',calibFile);
    if ~isfield(scr,'calibrationFile')
        scr.calibrationFile = calibFile;
    end
else %defaults if no calibration file
    calib.table = repmat(linspace(0,1,256)',1,3);
    calib.white = 1;
    calib.black = 0;
    calib.gunMaxs = ones(1,3)*1/3; 
end

function drawCues(task, scr, cuedLocI)

if cuedLocI == 0 %neutral
    colrs = [task.cue.neutralColor; task.cue.neutralColor]'; 
    colrs = colrs(:, [1 1 2 2]); %colors must be organized in columns with one column for each line start AND end 
    coords = task.cue.allcoords;
else
    colrs = task.cue.color';
    coords = task.cue.allcoords(:, [1 2]+(cuedLocI-1)*2);
end


    
Screen('DrawLines',scr.main,coords,task.cue.thick,colrs,[scr.centerX scr.centerY],2);
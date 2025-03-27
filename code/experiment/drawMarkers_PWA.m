function drawMarkers_PWA(task, scr, sides, colorIs)

for si = 1:length(sides)
    side = sides(si);
    if side == 0 %neutral
        coords = task.marker.allcoords;
    else
        coords = task.marker.allcoords(:, task.marker.colsBySides(side,:));
    end
    
    Screen('DrawLines',scr.main,coords,task.marker.thick,task.marker.colors(colorIs(si),:)',[scr.centerX scr.centerY],2);
end
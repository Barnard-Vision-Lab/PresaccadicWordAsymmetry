function drawSaccTargDots_PWA(task, scr, sides, colorIs)

for sd=1:length(sides)
    si = sides(sd);
    Screen('DrawDots', scr.main, task.marker.dotCoords(:,si), task.marker.dotDiam_px, task.marker.colors(colorIs(si),:));
end
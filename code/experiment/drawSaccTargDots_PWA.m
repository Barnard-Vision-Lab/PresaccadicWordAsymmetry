function drawSaccTargDots_PWA(task, scr, sides, colorIs)

dotType = 1; %0=square, 1,2,3 are cirlces

for sd=1:length(sides)
    si = sides(sd);
    Screen('DrawDots', scr.main, task.marker.dotCoords(:,si), task.marker.dotDiam_px, task.marker.colors(colorIs(si),:), [], dotType);
end
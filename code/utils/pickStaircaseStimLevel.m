function newLevel = pickStaircaseStimLevel(task,td)


if td.trialNum>task.stair.trialsStairIgnores
    switch task.stairType
        case 1
            newLevel = QuestQuantile(task.stair.q{td.stairNumber,td.subStaircaseNum});
        case 2
            newLevel = task.stair.q{td.stairNumber,td.subStaircaseNum}.xCurrent;
        case 3
            newLevel = task.stair.ss{td.stairNumber,td.subStaircaseNum}.intensity;
    end
    if task.stair.inLog10, newLevel = 10^newLevel; end
else
    newLevel = task.stair.threshStartGuess(1);
end
newLevel(newLevel>task.stair.maxIntensity) = task.stair.maxIntensity;
newLevel(newLevel<task.stair.minIntensity) = task.stair.minIntensity;

fprintf(1,'Staircase [%i,%i], setting intensity to %.4f\n',td.stairNumber,td.subStaircaseNum,newLevel);

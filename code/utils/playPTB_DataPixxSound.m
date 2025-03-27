function [t] = playPTB_DataPixxSound(si, task)

if task.doDataPixx
    Datapixx('RegWrRd');    % Synchronize Datapixx registers to local register cache
    Datapixx('SetAudioSchedule',0,task.sounds(si).freq, task.sounds(si).nfs, task.sounds(si).lrMode,task.sounds(si).buffer,task.sounds(si).nfs);  
    Datapixx('StartAudioSchedule');
    Datapixx('RegWrRd');    % Synchronize Datapixx registers to local register cache
    
    t = GetSecs;
elseif task.usePortAudio
    PsychPortAudio('FillBuffer', task.soundHandle, task.sounds(si).buffer);
    t = PsychPortAudio('Start', task.soundHandle, 1, 0, 1);
else
    t = GetSecs;
    Snd('Play',task.sounds(si).signal,task.sounds(si).freq);
end
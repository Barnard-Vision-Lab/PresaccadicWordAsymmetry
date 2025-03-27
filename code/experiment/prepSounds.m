function task = prepSounds(task)

%always try to use PsychPortAudio... except with Eyelink. Trying to use
%PsychPortAudio with Eyelink raises hell, even if pass the PsychPortAudio
%opened device handle to Snd('open', pahandle); 

task.usePortAudio = task.EYE==0;  

if task.usePortAudio
    InitializePsychSound(1);
end

%% open audio device
    %see PsychPortAudio('GetDevices')

if strcmp(task.displayName,'ILABSTestingLG')
    devNum = 7; %'8=sysdefault'
elseif strcmp(task.displayName,'ViewPixx3D')
    devNum = []; %24 causes crash %0 works in SimpleSoundScheduleDemo  - check that
    task.soundsOutFreq = 44100; 
else
    devNum = [];
end
    
soundMode = 1; %playback only 
latClass = 1; % 1 is reasonably fast latency, but doesn't take over all sound functionality 

nrchannels = 2;

if task.usePortAudio
    task.soundHandle = PsychPortAudio('Open', devNum, soundMode, latClass, task.soundsOutFreq, nrchannels);
    
    %According to the help text for Snd, It is possible to use PsychPortAudio
    %and still allow Eyelink to do it's thing with Snd. 
    %But that doesn't actually seem to work, or at least it didn't in September 2019 in
    %Linux. So, commenting it out. 
    %if task.EYE==1
    %    Snd('Open',task.soundHandle);
    %    fprintf(1,'\n(prepSounds) passing psychPortAudio open device handle to Snd\n');
    %end
end
%% create sounds
nblank = round(task.soundsOutFreq*task.soundsBlankDur);

for si=1:4
    nsignl = round(task.soundsOutFreq*task.sounds(si).toneDur); 
    t = (0:(nsignl-1))/task.soundsOutFreq;
    
    task.sounds(si).signal = [zeros(1,nblank) linspace(0.5,0,nsignl)].*[zeros(1,nblank) sin(2*pi*t*task.sounds(si).toneFreq)];
    task.sounds(si).signal = repmat(task.sounds(si).signal,nrchannels,1);
    task.sounds(si).freq = task.soundsOutFreq;
    task.sounds(si).nrchannels = nrchannels;
end

% Timeout/FixBreak feedback
%Just two repetitions of incorrect sound
task.sounds(5).signal = repmat(task.sounds(3).signal,1,2);
task.sounds(5).freq = task.soundsOutFreq;
task.sounds(5).nrchannels = nrchannels;

if task.usePortAudio
    %Make buffers
    for si=1:length(task.sounds)
        task.sounds(si).buffer = PsychPortAudio('CreateBuffer', task.soundHandle, task.sounds(si).signal);
    end
else 
    Snd('Open');
end
%Play a sound to load up the sound engine (avoid delay on first feedback
%beep)
playPTB_DataPixxSound(2, task);

%% Start eyelink recording and ensure fixation before trial starts
function [el, task, userQuit, didRecalib] =  preTrialEyetrackerSetup(el,task,scr)


didRecalib = false;
userQuit = false;
ncheck = 0; maxcheck = 3;
fix    = task.EYE == 0; %if no eye checking (not even dummy mode)
record = task.eyelinkIsRecording;
if task.EYE>0
    while fix~=1 || ~record
        if ~record
            Eyelink('startrecording');	% start recording
            % You should always start recording 50-100 msec before required otherwise you may lose a few msec of data
            WaitSecs(task.durations.startRecordingTime);
            
            key = 1;
            while key~= 0
                key = EyelinkGetKey(el);		% dump any pending local keys
            end
            
            err = Eyelink('checkrecording'); 	% check recording status
            if err==0
                record = 1;
                Eyelink('message', 'RECORD_START');
            else
                record = 0;	% results in repetition of fixation check
                Eyelink('message', 'RECORD_FAILURE');
                fprintf(1,'\n\nRECORD_FAILURE !!!!!!!\n\n');
            end
        end
        
        if fix~=1 && record
            Eyelink('command','clear_screen 0');
            
            %Check fixation and determine new fixation point
            [fix, newFixPos, task, scr] = establishFixation(scr, task);
            ncheck=ncheck+1;
            
            if fix~=1
                % calibration, if fixation not detected in maxFixCheckTime
                if ncheck<maxcheck %ask subject to fixate
                    %Play error tone
                    playPTB_DataPixxSound(5,task);
                    
                    WaitSecs(0.4);
                    
                else
                    %recalibrate (or drift correct)
                    Eyelink('stoprecording');
                    userQuit = instructRecalibrate(scr,task);
                    if ~userQuit
                        calibrateEyelink(el,task,scr);
                        didRecalib = true;
                        record = 0;
                        ncheck = 0;
                        
                        %then draw fixation and wait a bit
                        fixPos = 1;
                        drawFixation_SCLRCS(task, scr, fixPos);
                        Screen(scr.main,'DrawingFinished'); Screen('Flip', scr.main);
                        
                        WaitSecs(1);
                        
                    else %user pressed q to end trial after propmted to recalibrate
                        record = 1;
                        fix = 1;
                        ncheck = 0;
                    end
                    
                end
            else
                %store new fixation position for this trial
                task.fixation.newX = round(newFixPos(1));
                task.fixation.newY = round(newFixPos(2));
            end
        end
    end
else %if no eye-tracking, keep fixation position the same
    task.fixation.newX = task.fixation.posX(1);
    task.fixation.newY = task.fixation.posY(1);
end
task.eyelinkIsRecording = record;
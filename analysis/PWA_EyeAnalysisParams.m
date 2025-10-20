function ip = PWA_EyeAnalysisParams

%saccade parameters
ip.minSaccDur    = 10;          % Minimum duration parameter for saccade detection [ms]
ip.VELTYPE       = 1;          % velocity type for saccade detection [1 = averages over 2 samples.  2=more smoothing ]
ip.minSaccAmp    = 0.5;       % minimum saccade amplitude for inclusion [deg] % 0.36 is x-width in deg
ip.maxSaccAmp    = 12;         % maximum saccade amplitude for inclusion [deg] %24 is width of the text box
ip.maxSacVel     = 500;        % maximum saccade velocity for inclusion [deg/s]
ip.saccMergeInt  = 20;         % merge interval for consecutive saccadic events [ms]
ip.velThreshSDs  = 6;

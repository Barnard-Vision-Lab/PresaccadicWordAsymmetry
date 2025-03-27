function paths = PWA_Paths
% Return a structure with paths to various folders for this experiment 


paths.code    = fileparts(which(mfilename));
paths.proj    = fileparts(paths.code);
paths.stimuli = fullfile(paths.proj, 'stimuli');
paths.images  = fullfile(paths.proj, 'images');
paths.data    = fullfile(paths.proj, 'data');
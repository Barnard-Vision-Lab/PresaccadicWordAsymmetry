%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function loops through all edf files and does not include practice
% folders 
%
% Made for PWA analysis code June 2025
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function noPracticeEdf = edfFilesNoPractice(participantPath)

%% NOTE: Does not use getFilesByType (but can - maybe implement later)
    % Recursively finds all .edf files under participantPath excluding 'practice' folders
    allDirs = dir(fullfile(participantPath, '**', '*.edf'));
    noPracticeEdf = {};
    
    for i = 1:length(allDirs)
        thisPath = fullfile(allDirs(i).folder, allDirs(i).name);
        if ~contains(thisPath, [filesep 'practice' filesep]) && ...
           ~contains(thisPath, [filesep 'practice'])
            noPracticeEdf{end+1} = thisPath;
        end
    end
end

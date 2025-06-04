%% Make a histogram of the time of word offset relative to the time of saccade onset
%
% 06.04.2025 
% 
% Current Participant Pool: Mariam and Devon (NOTE: Mariam has more blocks)
%
%% Definitions and Paths
participantIDs = {'dlAllDat', 'mlAllDat'};

% The paths - Mariam's Laptop [change as necessary]
expDir='/Users/mariamlatif/Desktop/Vision Lab/PWA';
path_csv = fullfile(expDir,'Pilot Study Data (ml + dl)');

N = length(participantIDs); %how many subjects;

%% Creating one figure for overlayed histograms
figure; 
hold on;
colors = lines(N);

%% Looping thru subjects
for i = 1:N
    % Creating the full file name
    all_data = fullfile(path_csv, [participantIDs{i} '.csv']);
    
    % Reading the CSV file into a variable
    d = readtable(all_data);

    %Filter out trials that were not completed
    goodTrials = d.trialDone==1; % only includes completed trials 

    d = d(goodTrials,:);
    
    %add a variable for the difference between the time of word offset relative to the time of saccade onset
    d.wordSaccOffOn = cell(size(d.tLanded));
    d.wordSaccOffOn = d.tLanded-d.tstimDotsISIOns

    histogram(d.wordSaccOffOn, ...
              'FaceColor', colors(i,:), ...
              'EdgeColor', 'none', ...
              'FaceAlpha', 0.3); % transparency
end
%% Figure Edits
xline(0, 'r-', 'Word Disappears', 'LabelHorizontalAlignment', 'left');
xlabel('Difference: tLanded - tstimDotsISIOns');
ylabel('Count');
title('Overlayed Histograms of Word Offset Relative to Saccade Onset');
legend(participantIDs, 'Location', 'Best');
hold off;

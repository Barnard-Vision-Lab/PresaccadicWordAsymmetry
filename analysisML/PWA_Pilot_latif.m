% 
% INITIAL ANALYSIS CODE FOR PILOT STUDY
% 06.03.2025 
% 
% Current Participant Pool: Mariam and Devon (NOTE: Mariam has more blocks)

% Definitions and Paths
participantIDs = {'dlAllDat', 'mlAllDat'};

% The paths - Mariam's Laptop [change as necessary]
expDir='/Users/mariamlatif/Desktop/Vision Lab/PWA';
path_csv = fullfile(expDir,'Pilot Study Data (ml + dl)');

%%
%define attention conditions (depending on cue)
cueCond = {'Neutral';'Valid';'Invalid'};
nAttns = length(cueCond);

%define target sides (which side was post-cued) 
sides = {'left';'right'};
nSides = length(sides);

N = length(participantIDs); %how many subjects;

%pre-define a 3-dimensional matrix that will hold the results (proportion correct in each condition) 
PCs = NaN(nAttns, nSides, N); % subjects are in the last dimension 

%loop thru subjects
for i = 1:N
    % Creating the full file name
    all_data = fullfile(path_csv, [participantIDs{i} '.csv']);
    
    % Reading the CSV file into a variable
    d = readtable(all_data);

    %Filter out trials that were not completed
    goodTrials = d.trialDone==1; % only includes completed trials 

    d = d(goodTrials,:);

    %add a variable to this table that says whether each trial was valid,
    %invalid, or neutral 

    % NOTE: for the cued condition this is when tLanded is after tstimDotsISIOns 
    d.attnCond = cell(size(d.cueValidity));
    d.attnCond(d.cueValidity==0) = {'Neutral'}; %cueCond 0 is Neutral
    d.attnCond(d.cueValidity==1 & d.tLanded > d.tstimDotsISIOns) = {'Valid'}; %cue cond is Valid and when tLanded is after tstimDotsISIOns 
    d.attnCond(d.cueValidity==-1 & d.tLanded > d.tstimDotsISIOns ) = {'Invalid'}; %cue cond is Invalid when tLanded is after tstimDotsISIOns 

    %add target sides
    d.side = sides(d.targetSide); %targetSide a single number, 1 or 2 

    %loop through attention conditions 
    for a = 1:nAttns
        %define a boolean vector that's true for each trial of this
        %attention condition 
        attnTrials = strcmp(d.attnCond, cueCond{a});

            %loop through cue target sides 
            for s = 1:nSides
               % taking trials on the left or right side
                    sideTrials = strcmp(d.side, sides{s});
                %end

                %theseTrials is a Boolean vector that is true only for
                %trials that are at teh intersection of all three types of
                %conditions
                theseTrials = attnTrials & sideTrials;

                %now analyze accuracy for each sub-set of trials
                PCs(a, s, i) = mean(d.respCorrect(theseTrials));

            end
       end
 end

% Averaging over subjects, and calculating the SEM. (Note that you can now do
% this afor all conditions at the same time, rather than a separate command
% for each condition)

meanPCS = mean(PCs, ndims(PCs),'omitnan'); %take the mean over the last dimension 
semPCs = standardError(PCs, ndims(PCs));

%% a (very) rough visualization
plot(meanPCS);
hold on;
xlabel('Cue Validity');
xticks([1 2 3])
xticklabels(cueCond)
ylabel('Mean Accuracy');
legend('left','right')
sgtitle('Mean Accuracy')
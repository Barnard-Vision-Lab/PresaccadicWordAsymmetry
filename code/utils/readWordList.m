%function [words,catgLabels,numTokens,wordLengs] = readWordList(filename) 
%
% by Alex White, 2015
% Reads a stimulus list from an excel file
% 
% Input: 
% - filename, name or address of the excel file 
% The excel file should have n columns, one for each of n categories 
% The category labels should be the the first row
% 
% Outputs: 
% - words: a cell array of the word stimuli 
% - catgLabels: an array the n category labels
% - numTokens: a 1xn vector of the number of words in each category, 
% - wordLengs: a numToxens x n matrix, containing the lengths of each word

function [words,catgLabels,numTokens,wordLengs] = readWordList(filename) 

[~,t] = xlsread(filename); 

%first row is category name 
ncat = size(t,2); 
nrow = size(t,1); 

catgLabels = cell(1,ncat); 
numTokens  = zeros(1,ncat); 
words = cell(nrow-1,ncat);
wordLengs = zeros(nrow-1,ncat);

for c = 1:ncat
    i = 0;
    for r = 1:nrow
        if r==1
            catgLabels{c} = t{r,c};
        elseif ~isempty(t{r,c})
            i = i+1;
            words{i,c} = t{r,c};
            wordLengs(i,c)  = length(words{i,c});
        end
    end
    numTokens(c) = i; 
end
              
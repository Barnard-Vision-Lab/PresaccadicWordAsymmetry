%% function wordImg = assembleWordImage(word, alphabet, letterImgs, letterColrs, bgColor, trimParams)
% 
% Put together the image of a word from individual letter images 
% 
% Inputs: 
% - word: character string to make, length L
% - alphabet: character string, length A,  of all letters in letterImgs
% - letterImgs: cell array, length A, of images of each letter
% - letterColrs: a Lx3 vector of RGB colors for each letter in word
% - bgColor: 1 value, of background color in range 0-255
% - trimParams: structure with parameters for whether and by how much to
%   crop each letter image horizontally. 
%   tightWidth : whether to crop at all
%   minBlankOnLeftForCut: min number of blank pixels on left side to trigger a cut
%   blankOnLeftToCut:     number of blank pixels on left to cut (if any)
%   minBlankOnRightForCut: same for right 
%   blankOnRightToCut:    same for right
% - padParams: structure with parameters for how many blank pixels to ADD
%   to the left and right sides: 
%     padParams.left: number of blank pixels to padd the left side with 
%     padParams.right: number of blank pixels to padd the right side with



function wordImg = assembleWordImage(word, alphabet, letterImgs, letterColrs, bgColor, trimParams, padParams)

black=0;
white=255;

wordImg = [];
for li=1:length(word)
    ai = word(li)==alphabet;
    %set colors 
    letMask = letterImgs{ai};
    maskWid = size(letMask,2);
    
    if trimParams.tightWidth
        tightRect=ImageBoundsAW(letMask,white);
        if tightRect(RectLeft)>(trimParams.minBlankOnLeftForCut)
           letMask = letMask(:, trimParams.blankOnLeftToCut:end, :);
        end
        if tightRect(RectRight)<(maskWid-trimParams.minBlankOnRightForCut+1)
           letMask = letMask(:, 1:(maskWid-trimParams.blankOnRightToCut), :);
        end
    end
    
    if padParams.right>0
        padPx = ones(size(letMask,1), padParams.right, 3)*bgColor;
        letMask = cat(2, letMask, padPx);
    end
    if padParams.left>0
        padPx = ones(size(letMask,1), padParams.left, 3)*bgColor;
        letMask = cat(2,padPx, letMask);
    end
    
    letImg = NaN(size(letMask));
    for gi=1:3
        gunImg = letMask(:,:,gi); 
        gunImg(gunImg==white) = bgColor; 
        gunImg(gunImg==black) = letterColrs(li,gi);
        letImg(:,:,gi) = gunImg;
    end
        
    wordImg = cat(2,wordImg,letImg);
end

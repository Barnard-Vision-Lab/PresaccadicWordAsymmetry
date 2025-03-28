%% script to add pseudowords to stimulus set
R = readtable("LivingNonliving5to6Length.csv");
P = readtable("ConstrainedBigramPseudowords.csv");

P.category = repmat({"Pseudoword"}, size(P,1), 1);

%select pseudowords with same lengths & initial letters as real words

abcs = 'abcdefghijklmnopqrstuvwxyz';

W = table;

rCats = unique(R.category);
rLens = unique(R.length);

rStarts = [];
for wi=1:size(R,1)
    rStarts(wi) = R.word{wi}(1);
end
rStarts = rStarts';

pStarts = [];
for wi=1:size(P,1)
    pStarts(wi) = P.STRING{wi}(1);
end
pStarts = pStarts';

rCounts = zeros(length(rLens), length(abcs));
pCounts = rCounts;

for li = 1:length(rLens)
    len = rLens(li);
    for ai = 1:length(abcs)
        l1 = abcs(ai);

        rIs = R.length==len & rStarts==l1;

        nR = sum(rIs);

        rCounts(li, ai) = nR;

        if nR>0

            pIs = find(P.LEN==len & pStarts==l1);

            w = table;
            w.category = repmat({'Pseudoword'}, nR,1);
            w.length = ones(nR,1)*len;
            w.freq = zeros(nR,1);
           

            if length(pIs)>0
                subPIs = randsample(pIs, nR, false);
                pCounts(li, ai) = length(subPIs);

                if length(subPIs)~=nR, keyboard; end

                w.word = P.STRING(subPIs);


            else
                fprintf(1,'\nNo matching pseudowords for these real words:\n');
                R.word(rIs)
                fakeWords = cell(nR,1);
                for ii=1:nR
                    query = sprintf('Enter a fake pseudoword to match real word %s\n', R.word{rIs(ii)});
                    newWord = input(query,'s');
                    fakeWords{ii} = newWord;
                    w.word = fakeWords;
                end

            end
            W = [W; w];

        end
    end
end

S = [R; W];

writetable(S,"PWA_StimSet.csv")
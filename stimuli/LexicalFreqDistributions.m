p=PWA_Params;
L=p.strings.lexicon;
figure;
histogram(L.Freq_SUBTLEXUS_Zipf(string(L.category)=='Natural')); 
hold on; 
histogram(L.Freq_SUBTLEXUS_Zipf(string(L.category)=='Artificial'));

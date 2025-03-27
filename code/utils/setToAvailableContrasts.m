function cs = setToAvailableContrasts(levs,availableCs) 

% set desired contrasts to some that are available 
cs = zeros(size(levs));

for ci=1:length(levs)
    diffs = abs(levs(ci)-availableCs);
    bestC = availableCs(diffs == min(diffs));
    cs(ci) = bestC(1);
end

nbadreps = sum(diff(cs)==0); 
if nbadreps>0
    fprintf(1,'\n\n\nWARNING: %i OF REQUESTED CONTRASTS CANNOT BE PRESENTED DUE TO SCREEN DEPTH',nbadreps); 
    cs=unique(cs); 
end
fprintf(1,'\n     Used contrasts: '); fprintf(1,'%.3f\t',cs); fprintf(1,'\n\n');

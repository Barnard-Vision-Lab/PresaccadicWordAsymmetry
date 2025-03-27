function [] = plotQuest(q,inlog)

hold on;

nts=q.ntrials;

is=q.intensity(1:nts);
thresh = QuestMean(q);

if inlog
    is=10.^is;
    thresh=10^thresh;
end

plot(1:nts,is,'b-');

corrTrls = find(q.response(1:nts));
crH=plot(corrTrls, is(corrTrls), 'g.','MarkerSize',10);

incTrls = find(~q.response(1:nts));
inH=plot(incTrls, is(incTrls), 'r.','MarkerSize',10);

plot([0 nts],[thresh thresh],'r-');

%title('Staircase','FontSize',15);
xlabel('Trial');
ylabel('Intensity');

if ~isempty(corrTrls) && ~isempty(incTrls)
    legend([crH inH],'Correct','Incorrect','Location','NorthEast');
end

set(gca,'FontSize',12);
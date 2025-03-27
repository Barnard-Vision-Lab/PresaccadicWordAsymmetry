function [] = plotUDStair(q,inlog,thresh)

hold on;

goodTs = ~isnan(q.response); 
resp = q.response(goodTs); 
reversals = q.reversal(goodTs);
is = q.x(goodTs);

nts=length(resp);


if inlog
    is=10.^is;
end

revTrls = find(reversals>0);
plot(revTrls,is(revTrls),'y.','MarkerSize',18);

plot(1:nts,is,'b-');

corrTrls = find(resp(1:nts));
crH=plot(corrTrls, is(corrTrls), 'g.','MarkerSize',10);

incTrls = find(~resp(1:nts));
inH=plot(incTrls, is(incTrls), 'r.','MarkerSize',10);

plot([0 nts],[thresh thresh],'r-');

%title('Staircase','FontSize',15);
xlabel('Trial');
ylabel('Intensity');

%legend([crH inH],'Correct','Incorrect','Location','NorthEast');

set(gca,'FontSize',12);
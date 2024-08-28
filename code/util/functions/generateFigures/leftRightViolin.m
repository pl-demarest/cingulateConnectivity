function [vp1,vp2] = leftRightViolin(dataToPlot,groups,left,right,colors,offset)

% to plot group-lefel data in a violin plot, where comparisons are made
% between the left and right distribution of each violin

%data to plot: matrix where eachcolumn is a distribution, contains all data
%groups: labels for each group of data from 1 to number of groups. Offsets
%can be added to the input groups
%left: indexes of groups to be plotted as left distributions
%right: indexes of groups to be plotted as right distributions
%offset: indicates the offset from the center for each violin distribution

%first plot the left stimulation groups
vp = violinplot(dataToPlot(:,left),groups(left),'ViolinColor',colors,'ShowData',false,'HalfViolin','left','ShowMedian',false,'EdgeColor',[0,0,0],'ShowBox',false,'Width',0.3,'ViolinAlpha',0.2);
hold on
%nex tplot the right sitmulation groups
vp2 = violinplot(dataToPlot(:,right),groups(right),'ViolinColor',colors,'ShowData',false,'HalfViolin','right','ShowMedian',false,'EdgeColor',[0,0,0],'ShowBox',false,'Width',0.3,'ViolinAlpha',0.2);
hold on

%offset data and adjust appearance using object fields 
for v = 1:length(vp2)
vp(1,v).ViolinPlot.XData = vp(1,v).ViolinPlot.XData-offset;
vp2(1,v).ViolinPlot.XData = vp2(1,v).ViolinPlot.XData+0.05;

vp(1,v).ViolinPlot.EdgeAlpha = 0;
vp2(1,v).ViolinPlot.EdgeAlpha = 0;

vp(1,v).ShowWhiskers = 0;
vp2(1,v).ShowWhiskers = 0;
end

colors2 = repelem(colors,2,1);

for i = 1:length(groups)
curColor = colors2(i,:);
curMedian = nanmedian(dataToPlot(:,i));

swarmchart(groups(i),dataToPlot(:,i)',[],curColor,'filled','MarkerFaceAlpha',0.3);
hold on
%Adjust placement of swarmcharts
if rem(i,2) == 1
    l = groups(i) - 0.1;
else
    l = groups(i) + 0.1;
end
plot([l groups(i)],[curMedian curMedian],'Linewidth',2,'Color',curColor)
end

end
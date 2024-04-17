figure;
vp = violinplot(dataToPlot(:,1),1,'ViolinColor',[0,0,0],'ShowData',false,'HalfViolin','left','ShowMedian',false,'EdgeColor',[0,0,0],'ShowBox',false,'Width',0.3,'ViolinAlpha',0.2);
hold on

vp.ViolinPlot.XData = vp.ViolinPlot.XData-0.05;
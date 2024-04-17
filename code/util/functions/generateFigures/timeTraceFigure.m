function figureOut = timeTraceFigure(inputStruct,stimOnIndex,stimOffIndex,yAxisLabel)

%input should be a struct containing a 3D matrix chans x signal x trial

fns = fieldnames(inputStruct);

for ii = 1:length(fns)
currData = inputStruct.(fns{ii});

[rows,columns,numChans] = getSubplotDimensions(size(currData,1));
screenSize = get(0,'screensize');
screenSize(3:4) = screenSize(3:4)*0.9;



figureOut = figure('Position',screenSize);
for i = 1:numChans


meanTrace = squeeze(mean(currData(i,:,:),3));

seTrace = std(currData(i,:,:),0,3)/sqrt(size(currData,3));

x=1:length(meanTrace);

subP(i) = subplot(rows,columns,i);

plot(x,meanTrace,'Color','k')
hold on

jbfill(x, meanTrace+seTrace,meanTrace-seTrace, 'k','k', 1, 0.2);
hold on

low = min(ylim);
high = max(ylim);

plot([stimOnIndex stimOnIndex],[low high],'color','r')
plot([stimOffIndex stimOffIndex],[low high],'color','r')
ylabel(yAxisLabel)
box off

end

linkaxes(subP,'y')

end




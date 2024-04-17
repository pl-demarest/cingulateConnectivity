function envelopeFigure(inputStruct,stimOnIndex,stimOffIndex)

%input should be a struct containing a 3D matrix chans x signal x trial

fns = fieldnames(inputStruct);

for ii = 1:length(fns)
currData = inputStruct.(fns{ii});

[rows,columns,numChans] = getSubplotDimensions(size(currData,1));
screenSize = get(0,'screensize');



figure('Position',screenSize);
for i = 1:numChans


meanTrace = squeeze(mean(currData(i,:,:),3));

seTrace = std(currData(i,:,:),0,3)/sqrt(size(currData,3));

x=1:length(meanTrace);

subplot(rows,columns,i)

plot(x,meanTrace)
hold on

jbfill(x, meanTrace+seTrace,meanTrace-seTrace, 'k','k', 1, 0.2);
hold on


plot([stimOnIndex stimOnIndex],[min(ylim) max(ylim)],'color','r')
plot([stimOffIndex stimOffIndex],[min(ylim) max(ylim)],'color','r')
ylabel('Envelope uV (5-7Hz)')
box off

end

end
end



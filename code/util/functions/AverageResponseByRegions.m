function [meanTrace] = AverageResponseByRegions(signal,uniqueRegions,allChannels)
%input is struct with field dimensions chans x signal
%This function will generate a struct of nuqiue regions, where each struct
%field contains the name of each unique region. Each one of these unqiue
%regions will contain a cell, which contains a matrix of trialsxsignal and
%a channel number label.

meanTrace = zeros(size(uniqueRegions,1),size(signal,2));

for i = 1:length(uniqueRegions)

currentRegion = uniqueRegions{i};
idx = find(contains(allChannels,currentRegion));

a = nanmean(signal(idx,:),1);
meanTrace(i,:) = a;

end


end
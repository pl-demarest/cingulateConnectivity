function [structByRegion] = organizeDataByRegions(signal,uniqueRegions,allChannels)
%input is struct with field dimensions chans x signal x trial
%This function will generate a struct of nuqiue regions, where each struct
%field contains the name of each unique region. Each one of these unqiue
%regions will contain a cell, which contains a matrix of trialsxsignal and
%a channel number label.

for i = 1:length(uniqueRegions)

currentRegion = uniqueRegions{i};
idx = find(contains(allChannels,currentRegion));

tempCell = cell(length(idx),2);
for ch = 1:length(idx)
    
    
    tempCell{ch,1} = idx(ch);
    tempCell{ch,2} = squeeze(signal(idx(ch),:,:));


end
fieldname = erase(currentRegion,'-');
structByRegion.(fieldname) = tempCell;

end


end
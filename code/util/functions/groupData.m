function [groupedData, fns] = groupData(data,indexes)
%use this function to return a matrix of data by groups given an index
%struct where each field is the indexes of data to include in each group
%from a main data struct

%CAN ONLY BE USED WHEN DATA IS A VECTOR

fns = fieldnames(indexes);
lengthG = nan(length(fns),1);


for i=1:length(fns)
    lengthG(i) = length(indexes.(fns{i}));
end

groupedData = nan(max(lengthG),length(fns));

for i = 1:length(fns)
    currentData = data(indexes.(fns{i}));
    groupedData(1:length(currentData),i) = currentData;
end

end
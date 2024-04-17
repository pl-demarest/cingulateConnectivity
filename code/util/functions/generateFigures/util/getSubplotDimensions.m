function [rows,columns,channelNumber] = getSubplotDimensions(channelNumber)

rows = floor(sqrt(channelNumber));
columns = ceil(channelNumber/rows);

end
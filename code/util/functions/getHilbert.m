function [h] = getHilbert(data)

h = nan(size(data));

for ch = 1:size(data,1)
    h(ch,:) = hilbert(data(ch,:));
end


end

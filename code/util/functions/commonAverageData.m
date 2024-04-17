function [carData] = commonAverageData(signal)

if size(signal,1) > size(signal,2)
    carData = signal - mean(signal,2);
else
    carData = signal - mean(signal,1);
end

end

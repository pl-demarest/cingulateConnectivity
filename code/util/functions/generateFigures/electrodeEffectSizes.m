function [normalized, radiusSizes, rgbArray] = electrodeEffectSizes(effect,colorMap,minRadius,maxRadius,nanColor) 

normalized = (effect- min(effect)) / (max(effect) - min(effect));
storeZeros = find(normalized == 0);
normalized = 1-normalized;
normalized(storeZeros) = 0;
numColors = size(colorMap, 1);
colorIndices = ceil(normalized * numColors);
colorIndices(colorIndices < 1) = 1;  % Ensure indices are within the valid range
storeNan = isnan(colorIndices);
colorIndices(storeNan) = 1;
rgbArray = colorMap(colorIndices, :);

for i = 1:length(rgbArray)
    if storeNan(i)
rgbArray(i,:) = nanColor;
    end
end

radiusSizes = (normalized*(maxRadius-1))+1;
radiusSizes(storeZeros) = minRadius;
end
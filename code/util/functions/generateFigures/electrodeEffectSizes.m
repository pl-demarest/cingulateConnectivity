function [normalized, radiusSizes, rgbArray] = electrodeEffectSizes(effect,colorMap,minRadius,maxRadius,nanColor) 

% Normalize effect sizes to [0,1] range
normalized = (effect - min(effect)) / (max(effect) - min(effect));
storeZeros = find(normalized == 0);

% Map normalized values to colormap indices
% No inversion here - larger effects will map to larger indices
numColors = size(colorMap, 1);
colorIndices = ceil(normalized * numColors);
colorIndices(colorIndices < 1) = 1;  % Ensure indices are within the valid range
storeNan = isnan(colorIndices);
colorIndices(storeNan) = 1;
rgbArray = colorMap(colorIndices, :);

% Set NaN colors
for i = 1:length(rgbArray)
    if storeNan(i)
        rgbArray(i,:) = nanColor;
    end
end

% Set radius sizes - larger effects get larger radii
radiusSizes = (normalized*(maxRadius-minRadius))+minRadius;
radiusSizes(storeZeros) = minRadius;
end


function Colors = mapEffectSizesToColors(effectData, cmap)
% mapEffectSizesToColors maps effect size values to an RGB color matrix
% based on the provided colormap.
%
%   aColors = mapEffectSizesToColors(effectData, cmap)
%
% INPUTS:
%   effectData - A vector of effect sizes (can be negative, zero, or positive).
%                (If any values are NaN, they are mapped to the neutral color.)
%   cmap       - An N x 3 colormap matrix (e.g., a blue-to-white-to-red gradient).
%
% OUTPUT:
%   aColors    - An M x 3 matrix of RGB values corresponding to each effect size.
%
% The mapping is symmetric about zero. For valid (non-NaN) values, the
% maximum absolute effect size is used to normalize the mapping. NaN values
% are assigned the neutral (center) color of the colormap.
%
% Example:
%   cmap = getColors('modern blue to muted brick gradient');
%   aColors = mapEffectSizesToColors(effectSizes(:,1), cmap);
%
%   % Later, you can override special cases:
%   aColors(isnan(effectSizes(:,1)), :) = repmat([0.8, 0.8, 0.8], sum(isnan(effectSizes(:,1))), 1);
%   aColors(storeZeros, :) = repmat([0.4, 0.4, 0.4], sum(storeZeros), 1);
%   aColors(noCover, :) = repmat([0.4, 0.4, 0.4], sum(noCover), 1);

% Ensure effectData is a column vector.
effectData = effectData(:);

% Number of colors in the colormap.
nColors = size(cmap, 1);

% Identify valid (non-NaN) values to determine the normalization limits.
validIdx = ~isnan(effectData);
if any(validIdx)
    clim = max(abs(effectData(validIdx)));
else
    clim = 1; % Fallback to avoid division by zero if all values are NaN.
end

% Pre-allocate an index array.
colorIdx = zeros(size(effectData));

% Map valid effect sizes to colormap indices.
colorIdx(validIdx) = round(((effectData(validIdx) + clim) / (2 * clim)) * (nColors - 1)) + 1;

% For any NaN values, assign the neutral index (center of the colormap).
neutralIdx = round(nColors / 2);
colorIdx(~validIdx) = neutralIdx;

% Convert the indices into RGB values using the colormap.
Colors = cmap(colorIdx, :);
end

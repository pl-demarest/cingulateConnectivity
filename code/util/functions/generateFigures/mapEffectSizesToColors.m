function Colors = mapEffectSizesToColors(effectData, cmap, mode, customRange)
% mapEffectSizesToColors maps effect size values to an RGB color matrix
% based on the provided colormap.
%
%   Colors = mapEffectSizesToColors(effectData, cmap)
%   Colors = mapEffectSizesToColors(effectData, cmap, mode)
%   Colors = mapEffectSizesToColors(effectData, cmap, mode, customRange)
%
% INPUTS:
%   effectData  - A vector of effect sizes (can be negative, zero, or positive).
%                 (If any values are NaN, they are mapped to the neutral color.)
%   cmap        - An N x 3 colormap matrix (e.g., a blue-to-white-to-red gradient).
%   mode        - (Optional) String specifying the mapping mode:
%                 'relative' (default): Maps based on the min/max of effectData
%                 'to range': Maps to a custom range specified by customRange
%   customRange - (Optional) [min max] array specifying the range for 'to range' mode
%                 Default is [-1 1] if not provided
%
% OUTPUT:
%   Colors      - An M x 3 matrix of RGB values corresponding to each effect size.
%
% The mapping can be either relative to the data or to a fixed range:
% - In 'relative' mode, the maximum absolute effect size is used to normalize.
% - In 'to range' mode, values are mapped to the specified custom range.
% NaN values are assigned the neutral (center) color of the colormap.
%
% Example:
%   % Relative mapping (default behavior)
%   cmap = getColors('modern blue to muted brick gradient');
%   Colors = mapEffectSizesToColors(effectSizes(:,1), cmap);
%
%   % Fixed range mapping from -1 to 1
%   Colors = mapEffectSizesToColors(effectSizes(:,1), cmap, 'to range', [-1 1]);

% Set default parameters if not provided
if nargin < 3 || isempty(mode)
    mode = 'relative';
end

if nargin < 4 || isempty(customRange)
    customRange = [-1 1];
end

% Ensure effectData is a column vector
effectData = effectData(:);

% Number of colors in the colormap
nColors = size(cmap, 1);

% Identify valid (non-NaN) values
validIdx = ~isnan(effectData);

% Pre-allocate an index array
colorIdx = zeros(size(effectData));

if strcmpi(mode, 'relative')
    % Original relative mapping based on data extremes
    if any(validIdx)
        clim = max(abs(effectData(validIdx)));
    else
        clim = 1; % Fallback to avoid division by zero if all values are NaN
    end
    
    % Map valid effect sizes to colormap indices
    colorIdx(validIdx) = round(((effectData(validIdx) + clim) / (2 * clim)) * (nColors - 1)) + 1;
    
elseif strcmpi(mode, 'to range')
    % Map to a custom range
    minVal = customRange(1);
    maxVal = customRange(2);
    range = maxVal - minVal;
    
    % Clip values to the custom range
    clippedData = min(max(effectData(validIdx), minVal), maxVal);
    
    % Map valid effect sizes to colormap indices based on the custom range
    colorIdx(validIdx) = round(((clippedData - minVal) / range) * (nColors - 1)) + 1;
    
else
    error('Invalid mode. Use either ''relative'' or ''to range''.');
end

% For any NaN values, assign the neutral index (center of the colormap)
neutralIdx = round(nColors / 2);
colorIdx(~validIdx) = neutralIdx;

% Convert the indices into RGB values using the colormap
Colors = cmap(colorIdx, :);
end

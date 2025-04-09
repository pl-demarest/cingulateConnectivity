function [fig1,fig2,fig3] = generateNetworkPlotHalfCircle(outerCircleTable,innerCircleTable, dataStruct, dataFieldName, inclusionArray, stimSide,  overlapStyle, varargin)
    % plotCircularNetwork - Creates a circular divergent network figure
    %
    % Inputs:
    %todo- outerwidth, alpha range, linewidth range
    %   innerCircleTable - Table containing inner circle coordinates (x, y)
    %   outerCircleTable - Table containing outer circle coordinates (x, y)
    %                      and convergence point coordinates.
    %   overlapStyle     - String specifying line overlap style. Options:
    %                      'fullOverlap' - All lines overlap fully. (default)
    %                      'jitter'      - Adds random jitter to convergence points.
    %                      'offset'      - Systematic offset for clarity.
    %   Additional Inputs (optional, dependent on overlapStyle):
    %      For 'jitter': 'jitterMagnitude', value (default: 0.02)
    %      For 'offset': 'offsetStep', value (default: 0.02)
    %
    % Example:
    %   plotCircularNetwork(innerCircleTable, outerCircleTable, 'jitter', 'jitterMagnitude', 0.03)
    %   plotCircularNetwork(innerCircleTable, outerCircleTable, 'offset', 'offsetStep', 0.04)

    % Default parameters
    if nargin < 7 || isempty(overlapStyle)
        overlapStyle = 'fullOverlap';
    end

    % Validate overlapStyle
    if ~ismember(overlapStyle, {'fullOverlap', 'jitter', 'offset'})
        error('Invalid overlapStyle. Choose ''fullOverlap'', ''jitter'', or ''offset''.');
    end

    % Parse optional parameters for 'jitter' and 'offset'
    jitterMagnitude = 0.02; % Default jitter magnitude
    offsetStep = 0.02;      % Default offset step size

    if strcmp(overlapStyle, 'jitter')
        p = inputParser;
        addParameter(p, 'jitterMagnitude', jitterMagnitude, @isnumeric);
        parse(p, varargin{:});
        jitterMagnitude = p.Results.jitterMagnitude;
    elseif strcmp(overlapStyle, 'offset')
        p = inputParser;
        addParameter(p, 'offsetStep', offsetStep, @isnumeric);
        parse(p, varargin{:});
        offsetStep = p.Results.offsetStep;
    end

    data = dataStruct.(dataFieldName);
    data(~inclusionArray) = nan;

    fig1 = figure('position',[758          41        1697        1228]);
    % Initialize counters for offset style
    if strcmp(overlapStyle, 'offset')
        numOuterPoints = length(outerCircleTable.Name);
        innerConvergeCount = zeros(numOuterPoints, 1);
        outerConvergeCount = zeros(numOuterPoints, 1);
    end

    % Compute scale for jitter and offset normalization
    xRange = max(outerCircleTable.xCoord) - min(outerCircleTable.xCoord);
    yRange = max(outerCircleTable.yCoord) - min(outerCircleTable.yCoord);
    jitterXScale = jitterMagnitude * xRange;
    jitterYScale = jitterMagnitude * yRange;
    offsetXScale = offsetStep * xRange;
    offsetYScale = offsetStep * yRange;

    % Loop through connections
    stimulated = unique(innerCircleTable.Class);

    %store regions without coverage in one of the stimulation conditions,
    %and black it out when plotting the outer circle
    
storeMissing = [];
    

    for i = 1:length(stimulated)
        
        curStimLoc = stimulated(i);
        

        regions = ismember(innerCircleTable.Class,curStimLoc);
        

            Lside = '_lh_';

            Rside = '_rh_';

        curStimL = contains([dataStruct.stimulatedRegion{:}], innerCircleTable.Name(regions)) & contains([dataStruct.stimulatedRegion{:}],Lside);
        curStimR = contains([dataStruct.stimulatedRegion{:}], innerCircleTable.Name(regions)) & contains([dataStruct.stimulatedRegion{:}],Rside);

        curInnerX = mean(innerCircleTable.xCoord(regions));
        curInnerY = mean(innerCircleTable.yCoord(regions));
        
        for ii = 1:length(outerCircleTable.Name)
        

            curRegion = outerCircleTable.Name(ii);
            
            checkHemL = dataStruct.electrodeCoordinates(1,:) < 0;
            checkHemR = dataStruct.electrodeCoordinates(1,:) > 0;

            if strcmp(stimSide,'ipsi')

           curIDXL = curStimL & contains([dataStruct.electrodeRegionLabel{:}], curRegion) & checkHemL & inclusionArray;
           curIDXR = curStimR & contains([dataStruct.electrodeRegionLabel{:}], curRegion) & checkHemR & inclusionArray;

           if (sum(curIDXL) == 0) || (sum(curIDXR) == 0)

           storeMissing(ii) = 1;
           curLine(i,ii) = nan;
           curAlpha(ii) = nan;
           else 

           storeMissing(ii) = 0;

           curLine(i,ii) = abs(nanmean(data(curIDXR))) - abs(nanmean(data(curIDXL)));
           curAlpha(ii) = abs(nanmean(data(curIDXR))) - abs(nanmean(data(curIDXR)));
           end


            elseif strcmp(stimSide, 'contra')

           curIDXL = curStimL & contains([dataStruct.electrodeRegionLabel{:}], curRegion) & checkHemR & inclusionArray;
           curIDXR = curStimR & contains([dataStruct.electrodeRegionLabel{:}], curRegion) & checkHemL & inclusionArray;


            
           if (sum(curIDXL) == 0) || (sum(curIDXR) == 0)
           storeMissing(ii) = 1;
           curLine(i,ii) = nan;
           curAlpha(ii) = nan;
           else 
           storeMissing(ii) = 0;
           curLine(i,ii) = abs(nanmean(data(curIDXR))) - abs(nanmean(data(curIDXL)));
           curAlpha(ii) = abs(nanmean(data(curIDXR))) - abs(nanmean(data(curIDXL)));
           end


            end
            %Red means Right dominant, Blue means left dominant
        end

        %normalize curLine and curAlpha values
% Normalize the absolute differences for plotting:
% (These functions should map the input range to the desired output range)
normLineWidth = normalizeToRange(abs(curLine(i,:)), .75, 2);
normAlpha = normalizeToRange(abs(curAlpha), 0.3, 0.6);


        %now iterate through again and plot
for ii = 1:length(outerCircleTable.Name)
    % Determine line color based on the sign of dataLine
    if curLine(i,ii) > 0 
        baseColor = getColors('muted brick');  % e.g., red-ish
    elseif curLine(i,ii) < 0
        baseColor = getColors('modern blue');   % e.g., blue-ish
    else
        baseColor = [0, 0, 0];  % default to black if zero
    end

    % Append the normalized alpha value to form an RGBA color vector
    rgbaColor = [baseColor, normAlpha(ii)];

    % Retrieve convergence points from the outerCircleTable
    innerX = outerCircleTable.innerCovergeXCoord(ii);
    innerY = outerCircleTable.innerCovergeYCoord(ii);
    outerX = outerCircleTable.outterCovergeXCoord(ii);
    outerY = outerCircleTable.outterCovergeYCoord(ii);

    % Apply jitter or offset based on overlapStyle
    switch overlapStyle
        case 'jitter'
            innerX = innerX + jitterXScale * (rand - 0.5);
            innerY = innerY + jitterYScale * (rand - 0.5);
            outerX = outerX + jitterXScale * (rand - 0.5);
            outerY = outerY + jitterYScale * (rand - 0.5);
        case 'offset'
            innerConvergeCount(ii) = innerConvergeCount(ii) + 1;
            outerConvergeCount(ii) = outerConvergeCount(ii) + 1;

            innerOffsetX = (innerConvergeCount(ii) - 1) * offsetXScale * (-1)^innerConvergeCount(ii);
            innerOffsetY = (innerConvergeCount(ii) - 1) * offsetYScale * (-1)^innerConvergeCount(ii);
            outerOffsetX = (outerConvergeCount(ii) - 1) * offsetXScale * (-1)^outerConvergeCount(ii);
            outerOffsetY = (outerConvergeCount(ii) - 1) * offsetYScale * (-1)^outerConvergeCount(ii);

            innerX = innerX + innerOffsetX;
            innerY = innerY + innerOffsetY;
            outerX = outerX + outerOffsetX;
            outerY = outerY + outerOffsetY;
    end

    % Define the points for the curve (line)
    x = [curInnerX, innerX, outerX, outerCircleTable.xCoord(ii)];
    y = [curInnerY, innerY, outerY, outerCircleTable.yCoord(ii)];
    
    % Parameterize and interpolate for a smooth curve
    t = 1:length(x);
    tt = linspace(min(t), max(t), 200);
    xx = pchip(t, x, tt);
    yy = pchip(t, y, tt);
    
    % Plot if data is available
    if storeMissing(ii) == 0
        plot(xx, yy, 'LineWidth', normLineWidth(ii), 'Color', rgbaColor);
    end
    hold on;
end


        
    end


    %% plot the outter circle
% Adjust colormap and extract coordinates
colormap = getColors('vivid greyscale');
regionOrdered = unique(outerCircleTable.Class, 'stable');
colormap = colormap(1:length(regionOrdered), :); % Adjust colormap size to match regions
xOuter = outerCircleTable.xCoord;
yOuter = outerCircleTable.yCoord;

currentColormap = colormap;
% Initialize variables to store the last endpoint
xLast = [];
yLast = [];

for i = 1:length(regionOrdered)
    currentColor = currentColormap(i, :);
    
    % Select data points for the current region
    currentClass = ismember(outerCircleTable.Class, regionOrdered(i));
    curX = xOuter(currentClass);
    curY = yOuter(currentClass);
    
    if i == 1
        % For the first segment, plot as-is
        plot(curX, curY, '-', 'Color', currentColor, 'LineWidth', 15);
        hold on;
        % Set the last point as the endpoint of the first segment
        xLast = curX(end);
        yLast = curY(end);
    else
        % Ensure continuity by starting the current segment at the last endpoint
        if ~isequal(xLast, curX(1)) || ~isequal(yLast, curY(1))
            curX = [xLast; curX];
            curY = [yLast; curY];
        end
        plot(curX, curY, '-', 'Color', currentColor, 'LineWidth', 15);
        hold on;
        % Update the last point for the next segment
        xLast = curX(end);
        yLast = curY(end);
    end
end


    %% plot the inner points

    stimulated = unique(innerCircleTable.Class);
    for h = [0,1]

        if h == 0
            stimulated = unique(innerCircleTable.Class);
        elseif h == 1
            stimulated = flip(unique(innerCircleTable.Class));
        end
    for i = 1:length(stimulated)
        
        curStimLoc = stimulated(i);
        
        if strcmp(curStimLoc,'ACC')
            curColor = getColors('lush lilac');
        elseif strcmp(curStimLoc,'MCC')
            curColor = getColors('celadon porcelain');
        elseif strcmp(curStimLoc,'PCC')
            curColor = getColors('lago blue');
        end

        regions = ismember(innerCircleTable.Class,curStimLoc) & (innerCircleTable.rHemisphere == h);
        curInnerX = mean(innerCircleTable.xCoord(regions));
        curInnerY = mean(innerCircleTable.yCoord(regions));

       plot(curInnerX, curInnerY, 'o', 'MarkerFaceColor', curColor,'MarkerEdgeColor','k','MarkerSize',20);

    end
    end
    axis equal
    axis off

%% create legends for linewidth/linwalpha
raw_blue = [0.2, 0.5, 1.0];
raw_alpha_blue = raw_blue;  

curLine = curLine(:);
negValues = curLine(curLine < 0);
posValues = curLine(curLine > 0);

% Compute normalized line width and alpha using the absolute values.
normLineWidth_blue = normalizeToRange(abs(raw_blue), .75, 2);
normAlpha_blue     = normalizeToRange(abs(raw_alpha_blue), 0.3, 0.6);

% Define the base blue color.
baseColor_blue = getColors('modern blue');

fig2 = figure;
hold on;
for i = 1:length(raw_blue)
    y_val = 1 - i*0.2;
    x_line = [0.2, 0.8];
    % Create the RGBA vector for blue.
    rgba_blue = [baseColor_blue, normAlpha_blue(i)];
    % Plot the exemplar blue line.
    plot(x_line, [y_val, y_val], 'LineWidth', normLineWidth_blue(i), 'Color', rgba_blue);
    % Annotate the line: display the raw value as negative.
    text(0.85, y_val, ['max= ' num2str(max(abs(negValues))) newline 'min = ' num2str(min(abs(negValues)))], 'FontSize', 10, 'VerticalAlignment','middle');
end
axis off;
hold off;

% Sample raw positive values for red lines (curLine > 0)
raw_red = [0.2, 0.5, 1.0];   
raw_alpha_red = raw_red;       

% Compute normalized line width and alpha using your normalization function.
normLineWidth_red = normalizeToRange(abs(raw_red), .75,2);
normAlpha_red     = normalizeToRange(abs(raw_alpha_red), 0.3, 0.6);

% Define the base red color.
baseColor_red = getColors('muted brick');

fig3 = figure;
hold on;
for i = 1:length(raw_red)
    y_val = 1 - i*0.2;  % vertical position for each exemplar line
    x_line = [0.2, 0.8];  % horizontal line segment
    % Create a 4-element RGBA vector (if supported) by appending the normalized alpha.
    rgba_red = [baseColor_red, normAlpha_red(i)];
    % Plot the exemplar line with the normalized line width.
    plot(x_line, [y_val, y_val], 'LineWidth', normLineWidth_red(i), 'Color', rgba_red);
    % Annotate: show the raw value and the corresponding normalized line width and alpha.
    text(0.85, y_val, ['max= ' num2str(max(abs(posValues))) newline 'min = ' num2str(min(abs(posValues)))], 'FontSize', 10, 'VerticalAlignment','middle');
end
axis off;
hold off;


end

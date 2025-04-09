function generateNetworkPlot(outerCircleTable,innerCircleTable, dataStruct, dataFieldName, inclusionArray,  overlapStyle, varargin)
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
    if nargin < 6 || isempty(overlapStyle)
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
    dataLine = normalizeToRange(data,1.5, 3.2);
    dataAlpha = normalizeToRange(data,.3,.6);

    figure('position',[758          41        1697        1228]);
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
        
        if h == 0
            side = '_lh_';
        else
            side = '_rh_';
        end

        curStim = contains([dataStruct.stimulatedRegion{:}], innerCircleTable.Name(regions)) & contains([dataStruct.stimulatedRegion{:}],side);
        curInnerX = mean(innerCircleTable.xCoord(regions));
        curInnerY = mean(innerCircleTable.yCoord(regions));
        
        for ii = 1:length(outerCircleTable.Name)
        
            %switch for left and right
            curHem = outerCircleTable.rHemisphere(ii);
            curRegion = outerCircleTable.Name(ii);
            
            if curHem == 0
                checkHem = dataStruct.electrodeCoordinates(1,:) < 0;
            elseif curHem == 1
                checkHem = dataStruct.electrodeCoordinates(1,:) > 0;
            end

           curIDX = curStim & contains([dataStruct.electrodeRegionLabel{:}], curRegion) & checkHem & inclusionArray;
           curLine = nanmean(dataLine(curIDX));
           curAlpha = nanmean(dataAlpha(curIDX));

            % Initialize convergence points
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
                    % Update counters and compute offsets
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

            % Define the points for the line
            x = [curInnerX, innerX, outerX, outerCircleTable.xCoord(ii)];
            y = [curInnerY, innerY, outerY, outerCircleTable.yCoord(ii)];

            % Parameterize with t
            t = 1:length(x); % Auxiliary parameter

            % Interpolate both x and y using t
            tt = linspace(min(t), max(t), 200); % Fine-grained t for smooth curves
            xx = pchip(t, x, tt); % Interpolate x
            yy = pchip(t, y, tt); % Interpolate y

            % Plot the interpolated curve
            if sum(curIDX) > 0
            plot(xx, yy, 'LineWidth', curLine,'Color',[curColor,curAlpha])
            end
            hold on

            %todo- add logical clauses to avoid overlap for the inner
            %circle
        end
    end
    end

    %% plot the outter circle
colormap = getColors('vivid greyscale');
regionOrdered = unique(outerCircleTable.Class, 'stable');
colormap = colormap(1:length(regionOrdered), :); % Adjust colormap size to match regions
xOuter = outerCircleTable.xCoord;
yOuter = outerCircleTable.yCoord;

% Define a symmetry flip index
flipIndex = [0, 1]; % 0 for left hemisphere, 1 for right hemisphere

for h = flipIndex
    % Flip colormap for the right hemisphere
    currentColormap = colormap;
    if h == 1
        currentColormap = flip(colormap, 1);
        regionOrdered = flip(regionOrdered);
    end

    for i = 1:length(regionOrdered)
        currentColor = currentColormap(i, :);

        % Select data points for the current class and hemisphere
        currentClass = ismember(outerCircleTable.Class, regionOrdered(i)) & ...
                       (outerCircleTable.rHemisphere == h);

        curX = xOuter(currentClass);
        curY = yOuter(currentClass);

        
        curX = xOuter(currentClass);
        curY = yOuter(currentClass);
        

        % Plot arcs
        if i ==1 && h == 0
            plot([curX;xOuter(1)], [curY;yOuter(1)], '-', 'Color', currentColor, 'LineWidth', 15); %can fix this later, plotting from counterclockwise
        else
            plot([curX;xLast ], [curY;yLast], '-', 'Color', currentColor, 'LineWidth', 15)
        end
        hold on;
        xLast = curX(1);
        yLast = curY(1);
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


    %% plot the connections between the inner points

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


    % Adjust axis for a better circular view
    axis equal
    axis off
end

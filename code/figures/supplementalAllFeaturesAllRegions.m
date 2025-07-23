%% Supplemental Figure: All Features All Regions
% Creates a comprehensive PDF report showing electrode features across all brain regions
% for each stimulation condition (ACC, MCC, PCC)
clear
close all
addpath(genpath(cd))

% Add PEABrain to handle 3D modeling
addpath(genpath('/Volumes/Samsung_T5/PEABrain'));

% Load required data
pooledData = load('data/pooledData.mat');
load('data/compiledData.mat');
load('code/dependencies/templateBrain.mat');
load('code/dependencies/listHip.mat');
load('code/dependencies/listAmyg.mat');
load('code/dependencies/cingulateNames.mat');

% Load region categorization table
regionSort = readtable('code/dependencies/regionCategories.xlsx');

% Create output directory
saveDir = 'figures/main/';
mkdir(saveDir);

% Calculate significance thresholds
alpha = calculateAlphaThreshold(pooledData.pValue, 0.0001);
significant = (pooledData.pValue < alpha) & (pooledData.cohensD > 0);

% Calculate significance for RMS separately
alphaRMS = calculateAlphaThreshold(pooledData.RMSP, 0.0001);
significantRMS = (pooledData.RMSP < alphaRMS);

% Initialize stimulation conditions
cingulateNamesSimple = {'G_and_S_cingul-Ant'
'G_and_S_cingul-Mid-Ant'
'G_and_S_cingul-Mid-Post'
'G_cingul-Post-dorsal'
'G_cingul-Post-ventral'};

% Create logical arrays for stimulation conditions
condition.AStim = contains([pooledData.stimulatedRegion{:}], cingulateNamesSimple(1));
condition.MStim = contains([pooledData.stimulatedRegion{:}], cingulateNamesSimple(2:3));
condition.PStim = contains([pooledData.stimulatedRegion{:}], cingulateNamesSimple(4:5));

stimConditions = {'AStim', 'MStim', 'PStim'};
stimNames = {'ACC', 'MCC', 'PCC'};

% Prepare region list using same method as figure2.m
regions = unique([pooledData.electrodeRegionLabel{:}]);
brainFieldnames = fieldnames(templateBrain.regions);

% Define feature names and corresponding data fields
featureNames = {'Coherence', 'RMS', 'Rho CCEP'};
featureFields = {'cohensD', 'RMS',  'rhoCCEP'};

% Define views for plotting - matching figure1 views
viewAngles = {[180, 0], [270, 0], [-180, 90]}; % anterior, sagittal, superior
viewNames = {'Anterior', 'Sagittal', 'Superior'};

% Initialize PDF
pdfFileName = [saveDir 'supplementalAllFeaturesAllRegions.pdf'];
if exist(pdfFileName, 'file')
    delete(pdfFileName);
end

% Define colors for stimulation conditions (for brain surfaces)
aColor = getColors('lush lilac');
mColor = getColors('celadon porcelain');
pColor = getColors('lago blue');
stimColors = {aColor, mColor, pColor}; % ACC, MCC, PCC

% Main processing loop - iterate through each stimulation condition first
figureCount = 0;

for stimIdx = 1:length(stimConditions)
    stimCond = stimConditions{stimIdx};
    stimName = stimNames{stimIdx};
    
    % Get logical array for current stimulation condition
    currentStimCondition = condition.(stimCond);
    stimLogical = currentStimCondition;
    
    if sum(stimLogical) == 0
        continue; % Skip if no data for this stimulation condition
    end
    
    % Extract and normalize feature data for current stimulation condition
    featureData = {};
    radiusData = {};
    
    for featIdx = 1:length(featureFields)
        fieldName = featureFields{featIdx};
        if isfield(pooledData, fieldName)
            currentFeatureData = pooledData.(fieldName)(stimLogical);
            
            % Normalize using electrodeEffectSizes
            [~, radius, ~] = electrodeEffectSizes(currentFeatureData, ...
                [0.5, 0.5, 0.5], 1, 3, [0.8, 0.8, 0.8]);
            
            featureData{featIdx} = currentFeatureData;
            radiusData{featIdx} = radius;
        else
            featureData{featIdx} = [];
            radiusData{featIdx} = [];
        end
    end
    
    % Now iterate through each brain region for this stimulation condition
    for i = 1:length(templateBrain.regionList)
        regionName = templateBrain.regionList{i};
        
        % Check if this region has electrode coverage for current stimulation condition
        regionLogical = contains([pooledData.electrodeRegionLabel{:}], regionName);
        regionStimLogical = regionLogical & stimLogical;
        
        if sum(regionStimLogical) == 0
            continue; % Skip regions with no electrodes for this condition
        end
        
        % Create figure for this region and stimulation condition
        figureCount = figureCount + 1;
        fig = figure('Position', [100, 100, 1800, 1200], 'Visible', 'off');
        
        % Get electrode coordinates for this region
        electrodeCoords = pooledData.electrodeCoordinates(:, regionStimLogical)';
        
        % Create indices to map from stimLogical to region-specific
        stimIndices = find(stimLogical);
        regionStimIndices = find(regionStimLogical);
        [~, localIndices] = ismember(regionStimIndices, stimIndices);
        
        % Create subplots: 3 features × 3 views = 12 subplots
        for featIdx = 1:length(featureNames)
            if isempty(featureData{featIdx})
                continue;
            end
            
            % Get feature-specific radii for this region
            regionFeatureRadii = radiusData{featIdx}(localIndices);
            
            for viewIdx = 1:length(viewAngles)
                subplotIdx = (featIdx - 1) * 3 + viewIdx;
                subplot(3, 3, subplotIdx);
                
                % Create brain region structure for plotting - only current region
                clear regionStruct;
                regionStruct.regions.(brainFieldnames{i}) = templateBrain.regions.(brainFieldnames{i});
                
                % Plot brain surface in stimulation condition color
                surfaceColor = stimColors{stimIdx};
                [surf] = plotProjectedRegionsOnly(regionStruct, surfaceColor);
                
                % Set surface transparency
                if ~isempty(surf)
                    surf(1).FaceAlpha = 0.1; % Same as interCingulateConnectivity
                end
                
                hold on;
                
                % Get feature-specific significance
                if featIdx == 2 % RMS feature
                    isSignificant = significantRMS(regionStimLogical);
                else % All other features use Cohen's D p-values
                    isSignificant = significant(regionStimLogical);
                end
                
                % Plot electrodes for this region
                for elecIdx = 1:size(electrodeCoords, 1)
                    elecCoord = electrodeCoords(elecIdx, :);
                    elecRadius = regionFeatureRadii(elecIdx);
                    
                    % Color based on significance
                    if isSignificant(elecIdx)
                        color = [1, 0, 0]; % Red for significant
                    else
                        color = [0, 0, 0]; % Black for non-significant
                    end
                    
                    % Plot electrode
                    plotBallsOnVolume(gca, elecCoord, color, elecRadius);
                end
                
                % Set view
                view(viewAngles{viewIdx});
                axis on    
                set(gca,'XColor', 'k','YColor','k','ZColor','k')
                axis equal;
                
                % Show axis with ticks for scale (in mm)
                set(gca, 'GridLineStyle', '-', 'GridAlpha', 0.1);
                set(gca, 'FontSize', 8);
                set(gca, 'XTickMode', 'auto', 'YTickMode', 'auto', 'ZTickMode', 'auto');
                set(gca, 'XTickLabelMode', 'auto', 'YTickLabelMode', 'auto', 'ZTickLabelMode', 'auto');
                xlabel('X (mm)', 'FontSize', 8);
                ylabel('Y (mm)', 'FontSize', 8);
                zlabel('Z (mm)', 'FontSize', 8);
                
                % Add subplot title
                if viewIdx == 2 % Only add feature name to middle view
                    title(featureNames{featIdx}, 'FontSize', 12, 'FontWeight', 'bold');
                end
                
                % Add view label to bottom row
                if featIdx == 4
                    xlabel(viewNames{viewIdx}, 'FontSize', 10);
                end
            end
        end
        
        % Add main title
        sgtitle(sprintf('%s Stimulation - %s', stimName, strrep(regionName, '_', ' ')), ...
            'FontSize', 16, 'FontWeight', 'bold');
        
        % Save to PDF
        if figureCount == 1
            exportgraphics(fig, pdfFileName, 'Resolution', 300);
        else
            exportgraphics(fig, pdfFileName, 'Resolution', 300, 'Append', true);
        end
        
        % Close figure to save memory
        close(fig);
    end
end

fprintf('Analysis complete. PDF saved to: %s\n', pdfFileName);
fprintf('Total figures created: %d\n', figureCount);

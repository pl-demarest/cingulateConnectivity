%% Supplemental Figure: Brain Region Reference Legends
% This script generates reference brain region figures and legends
% organized by region class from the regionCategories table
% Each brain region gets a unique color within its class

clear
close all
addpath(genpath(cd))

% Load dependencies
load('code/dependencies/templateBrain.mat');
load('code/dependencies/listHip.mat');
load('code/dependencies/listAmyg.mat');
regionSort = readtable('code/dependencies/regionCategories.xlsx');

% Create output directory
saveDir = 'figures/supplemental/regionLegends/';
mkdir(saveDir);

%% Analyze brain template structure
fprintf('Brain Template Structure:\n');
fprintf('Total number of brain regions: %d\n', length(templateBrain.regionList));

% Use all regions from templateBrain.regionList
allRegions = templateBrain.regionList;
nTotalRegions = length(allRegions);

% Debug: Check the structure of allRegions
fprintf('Debug: allRegions is a %s with %d elements\n', class(allRegions), length(allRegions));
if iscell(allRegions)
    fprintf('Debug: First few regions: %s\n', strjoin(allRegions(1:min(3, length(allRegions))), ', '));
end

% Create custom colormap function for all brain regions
regionColors = generateDistinctBrainColors(nTotalRegions);

fprintf('Generated %d unique colors for brain regions\n', nTotalRegions);
fprintf('Debug: regionColors size = [%d, %d]\n', size(regionColors, 1), size(regionColors, 2));

%% Prepare brain models for visualization
brainFieldnames = fieldnames(templateBrain.regions);

% Generate brain model without hippocampus/amygdala for certain views
hipAmyg = [listAmyg, listHip];
hipAmygBool = contains(templateBrain.regionList, hipAmyg);
brainFieldnames2 = brainFieldnames(~hipAmygBool);

templateBrain2 = struct('regions', struct());
for i = 1:length(brainFieldnames2)
    templateBrain2.regions.(brainFieldnames2{i}) = templateBrain.regions.(brainFieldnames2{i});
end

% Create hemisphere models
templateBrainRight = getOneSide(templateBrain2, 'right');
templateBrainRight = isolatePortionOfModel(templateBrainRight, 'x', 'less', 27);

templateBrainLeft = getOneSide(templateBrain, 'left');
templateBrainLeft = isolatePortionOfModel(templateBrainLeft, 'x', 'less', -15);

% Generate hippocampus/amygdala model
hipAmygFieldnames = brainFieldnames(hipAmygBool);
hipAmygTemplate = struct('regions', struct());
for i = 1:length(hipAmygFieldnames)
    hipAmygTemplate.regions.(hipAmygFieldnames{i}) = templateBrain.regions.(hipAmygFieldnames{i});
end
hipAmygTemplate = getOneSide(hipAmygTemplate, 'left');

%% Generate figures organized by anatomical structures
legendData = struct();

% Store all region data for comprehensive legend
legendData.allRegions = allRegions;
legendData.allColors = regionColors;

% Get unique classes from regionSort, excluding hippocampus, amygdala, and insula
uniqueClasses = unique(regionSort.Class);
corticalClasses = uniqueClasses(~contains(uniqueClasses, {'Hippocampus', 'Amygdala', 'Insula'}));
fprintf('Found %d cortical classes to generate figures for:\n', length(corticalClasses));
for i = 1:length(corticalClasses)
    fprintf('  %d. %s\n', i, corticalClasses{i});
end

%% Generate separate cortical figures for each class
for classIdx = 1:length(corticalClasses)
    currentClass = corticalClasses{classIdx};
    fprintf('Creating figure for class: %s\n', currentClass);
    
    % Find regions belonging to this class
    classRegionIdx = strcmp(regionSort.Class, currentClass);
    classRegions = regionSort.Name(classRegionIdx);
    
    % Find which brain regions match this class
    classBrainRegionIdx = false(size(allRegions));
    for i = 1:length(classRegions)
        classBrainRegionIdx = classBrainRegionIdx | contains(allRegions, classRegions{i});
    end
    
    % Create color array: distinct colors for class regions, grey for others
    classColors = repmat([0.7, 0.7, 0.7], nTotalRegions, 1); % Default grey
    
    % Assign distinct colors to regions in this class
    classRegionColors = generateDistinctBrainColors(sum(classBrainRegionIdx));
    classColors(classBrainRegionIdx, :) = classRegionColors;
    
    % Create figure for this class
    figure('Position', [38, 188, 3397, 946]);
    sgtitle(sprintf('Brain Cortex - %s Regions', currentClass), 'FontSize', 16, 'FontWeight', 'bold');
    
    % Standard cortical views (excluding hippocampus/amygdala)
    subplot(1, 5, 1);
    plotProjectedRegionsOnly(templateBrainLeft, classColors);
    view([270, 0]);
    title('Left Sagittal');
    axis off;
    
    subplot(1, 5, 2);
    plotProjectedRegionsOnly(templateBrainRight, classColors);
    view([270, 0]);
    title('Right Sagittal');
    axis off;
    
    subplot(1, 5, 3);
    plotProjectedRegionsOnly(templateBrainLeft, classColors);
    view([180, 0]);
    title('Anterior');
    axis off;
    
    subplot(1, 5, 4);
    plotProjectedRegionsOnly(templateBrainLeft, classColors);
    view([-180, 90]);
    title('Superior');
    axis off;
    
    subplot(1, 5, 5);
    plotProjectedRegionsOnly(templateBrainLeft, classColors);
    view([0, 0]);
    title('Posterior');
    axis off;
    
    % Save class-specific figure
    classFileName = strrep(currentClass, ' ', '_');
    classFileName = strrep(classFileName, '/', '_');
    saveas(gcf, [saveDir 'Cortex_' classFileName '.png']);
    saveas(gcf, [saveDir 'Cortex_' classFileName '.svg']);
    
    % Create legend for this class
    if sum(classBrainRegionIdx) > 0
        figure('Position', [100, 100, 800, 600]);
        sgtitle(sprintf('%s Region Legend', currentClass), 'FontSize', 16, 'FontWeight', 'bold');
        
        % Get regions and colors for this class
        classRegionNames = allRegions(classBrainRegionIdx);
        classRegionColorsLegend = classRegionColors;
        
        % Create color swatches for class regions
        barh(1:length(classRegionNames), ones(length(classRegionNames), 1), 'FaceColor', 'flat', 'CData', classRegionColorsLegend);
        
        % Add region names
        yticks(1:length(classRegionNames));
        yticklabels(classRegionNames);
        set(gca, 'YDir', 'reverse', 'TickLabelInterpreter', 'none');
        
        xlim([0, 1.2]);
        set(gca, 'XTick', []);
        grid off;
        box off;
        
        % Save class legend
        saveas(gcf, [saveDir 'Legend_' classFileName '.png']);
        saveas(gcf, [saveDir 'Legend_' classFileName '.svg']);
        
        % Store legend data for this class
        legendData.(matlab.lang.makeValidName(['class_' classFileName])) = struct();
        legendData.(matlab.lang.makeValidName(['class_' classFileName])).regions = classRegionNames;
        legendData.(matlab.lang.makeValidName(['class_' classFileName])).colors = classRegionColorsLegend;
    else
        fprintf('No regions found for class: %s\n', currentClass);
    end
end

%% 1. OVERALL CORTEX FIGURE - Main brain cortex with all regions colored
fprintf('Creating overall cortex figure...\n');

% Assign colors to all brain regions
Colors = regionColors; % Each region gets its unique color

figure('Position', [38, 188, 3397, 946]);
sgtitle('Brain Cortex - All Regions with Unique Colors', 'FontSize', 16, 'FontWeight', 'bold');

% Standard cortical views
subplot(1, 5, 1);
plotProjectedRegionsOnly(templateBrainLeft, Colors);
view([270, 0]);
title('Left Sagittal');
axis off;

subplot(1, 5, 2);
plotProjectedRegionsOnly(templateBrainRight, Colors);
view([270, 0]);
title('Right Sagittal');
axis off;

subplot(1, 5, 3);
plotProjectedRegionsOnly(templateBrainLeft, Colors);
view([180, 0]);
title('Anterior');
axis off;

subplot(1, 5, 4);
plotProjectedRegionsOnly(templateBrainLeft, Colors);
view([-180, 90]);
title('Superior');
axis off;

subplot(1, 5, 5);
plotProjectedRegionsOnly(templateBrainLeft, Colors);
view([0, 0]);
title('Posterior');
axis off;

% Save main cortex figure
saveas(gcf, [saveDir 'CortexAllRegions.png']);
saveas(gcf, [saveDir 'CortexAllRegions.svg']);

%% 2. INSULA FIGURE - Detailed insula views
fprintf('Creating insula figure...\n');

% Prepare insula model using regionSort table (same methodology as figure2.m)
insulaBool = contains(templateBrain.regionList, regionSort{strcmp(regionSort{:,3}, 'Insula'), 1});
insulaFieldnames = brainFieldnames(insulaBool);
insulaTemplate = struct('regions', struct());
for i = 1:length(insulaFieldnames)
    insulaTemplate.regions.(insulaFieldnames{i}) = templateBrain.regions.(insulaFieldnames{i});
end
insulaTemplateLeft = getOneSide(insulaTemplate, 'left');
insulaColors = Colors(insulaBool, :);

if any(insulaBool)
    figure('Position', [38, 188, 3397, 946]);
    sgtitle('Insula Regions - Detailed Views', 'FontSize', 16, 'FontWeight', 'bold');
    
    subplot(1, 5, 1);
    plotProjectedRegionsOnly(insulaTemplateLeft, insulaColors);
    view([270, 0]);
    title('Insula - Sagittal');
    axis off;
    
    subplot(1, 5, 2);
    plotProjectedRegionsOnly(insulaTemplateLeft, insulaColors);
    view([180, 0]);
    title('Insula - Anterior');
    axis off;
    
    subplot(1, 5, 3);
    plotProjectedRegionsOnly(insulaTemplateLeft, insulaColors);
    view([0, 0]);
    title('Insula - Posterior');
    axis off;
    
    subplot(1, 5, 4);
    plotProjectedRegionsOnly(insulaTemplateLeft, insulaColors);
    view([-180, 90]);
    title('Insula - Superior');
    axis off;
    
    subplot(1, 5, 5);
    plotProjectedRegionsOnly(insulaTemplateLeft, insulaColors);
    view([0, -90]);
    title('Insula - Inferior');
    axis off;
    
    % Save insula figure
    saveas(gcf, [saveDir 'InsulaRegions.png']);
    saveas(gcf, [saveDir 'InsulaRegions.svg']);
    
    % Create legend for insula regions
    figure('Position', [100, 100, 800, 600]);
    sgtitle('Insula Region Legend', 'FontSize', 16, 'FontWeight', 'bold');
    
    % Get regions and colors for insula
    insulaRegionNames = allRegions(insulaBool);
    
    % Create color swatches for insula regions
    barh(1:length(insulaRegionNames), ones(length(insulaRegionNames), 1), 'FaceColor', 'flat', 'CData', insulaColors);
    
    % Add region names
    yticks(1:length(insulaRegionNames));
    yticklabels(insulaRegionNames);
    set(gca, 'YDir', 'reverse', 'TickLabelInterpreter', 'none');
    
    xlim([0, 1.2]);
    set(gca, 'XTick', []);
    grid off;
    box off;
    
    % Save insula legend
    saveas(gcf, [saveDir 'Legend_Insula.png']);
    saveas(gcf, [saveDir 'Legend_Insula.svg']);
    
    % Store insula data
    legendData.insulaRegions = allRegions(insulaBool);
    legendData.insulaColors = insulaColors;
else
    fprintf('No insula regions found in template\n');
end

%% 3. HIPPOCAMPUS/AMYGDALA FIGURE - Detailed subcortical views
fprintf('Creating hippocampus/amygdala figure...\n');

hipAmygColors = Colors(hipAmygBool, :);

if any(hipAmygBool)
    figure('Position', [38, 188, 3397, 946]);
    sgtitle('Hippocampus/Amygdala Regions - Detailed Views', 'FontSize', 16, 'FontWeight', 'bold');
    
    subplot(1, 5, 1);
    plotProjectedRegionsOnly(hipAmygTemplate, hipAmygColors);
    view([-176.4, -90.0]);
    title('Hip/Amyg - View 1');
    axis off;
    
    subplot(1, 5, 2);
    plotProjectedRegionsOnly(hipAmygTemplate, hipAmygColors);
    view([-180.8, 73.9]);
    title('Hip/Amyg - View 2');
    axis off;
    
    subplot(1, 5, 3);
    plotProjectedRegionsOnly(hipAmygTemplate, hipAmygColors);
    view([90, 0]);
    title('Hip/Amyg - Lateral');
    axis off;
    
    
    % Save hippocampus/amygdala figure
    saveas(gcf, [saveDir 'HippocampusAmygdalaRegions.png']);
    saveas(gcf, [saveDir 'HippocampusAmygdalaRegions.svg']);
    
    % Create legend for hippocampus/amygdala regions
    figure('Position', [100, 100, 800, 600]);
    sgtitle('Hippocampus/Amygdala Region Legend', 'FontSize', 16, 'FontWeight', 'bold');
    
    % Get regions and colors for hippocampus/amygdala
    hipAmygRegionNames = allRegions(hipAmygBool);
    
    % Create color swatches for hippocampus/amygdala regions
    barh(1:length(hipAmygRegionNames), ones(length(hipAmygRegionNames), 1), 'FaceColor', 'flat', 'CData', hipAmygColors);
    
    % Add region names
    yticks(1:length(hipAmygRegionNames));
    yticklabels(hipAmygRegionNames);
    set(gca, 'YDir', 'reverse', 'TickLabelInterpreter', 'none');
    
    xlim([0, 1.2]);
    set(gca, 'XTick', []);
    grid off;
    box off;
    
    % Save hippocampus/amygdala legend
    saveas(gcf, [saveDir 'Legend_HippocampusAmygdala.png']);
    saveas(gcf, [saveDir 'Legend_HippocampusAmygdala.svg']);
    
    % Store hippocampus/amygdala data
    legendData.hipAmygRegions = allRegions(hipAmygBool);
    legendData.hipAmygColors = hipAmygColors;
else
    fprintf('No hippocampus/amygdala regions found in template\n');
end

%% Create comprehensive legend figure for all brain regions
fprintf('Creating comprehensive legend for all %d brain regions...\n', nTotalRegions);

figure('Position', [100, 100, 1400, 1000]);
sgtitle('Brain Region Reference Legend - All Regions', 'FontSize', 20, 'FontWeight', 'bold');

% Calculate layout for all regions - organize in multiple columns
regionsPerColumn = 25; % Adjust as needed
nCols = ceil(nTotalRegions / regionsPerColumn);

% Create color swatches for all regions
barh(1:nTotalRegions, ones(nTotalRegions, 1), 'FaceColor', 'flat', 'CData', regionColors);

% Add region names
yticks(1:nTotalRegions);
yticklabels(allRegions);
set(gca, 'YDir', 'reverse', 'TickLabelInterpreter', 'none');

xlim([0, 1.2]);
set(gca, 'XTick', []);
grid off;
box off;

% Save comprehensive legend
saveas(gcf, [saveDir 'ComprehensiveLegend.png']);
saveas(gcf, [saveDir 'ComprehensiveLegend.svg']);



%% Save legend data to file
save([saveDir 'legendData.mat'], 'legendData', 'templateBrain', 'regionColors');

% Also save as CSV for easy reference
% Ensure dimensions match
fprintf('Debug: allRegions length = %d, regionColors rows = %d\n', length(allRegions), size(regionColors, 1));

if length(allRegions) ~= size(regionColors, 1)
    error('Dimension mismatch: allRegions has %d elements but regionColors has %d rows', ...
        length(allRegions), size(regionColors, 1));
end

legendTable = table();
legendTable.Region = allRegions(:);  % Ensure column vector
legendTable.R = regionColors(:, 1);
legendTable.G = regionColors(:, 2);
legendTable.B = regionColors(:, 3);

writetable(legendTable, [saveDir 'RegionColorReference.csv']);

fprintf('Brain region legend generation complete!\n');
fprintf('Files saved to: %s\n', saveDir);
fprintf('Total regions processed: %d\n', nTotalRegions);
fprintf('Generated %d class-specific cortical figures\n', length(corticalClasses));
fprintf('Generated figures for: Class-specific cortex, Overall cortex, Insula, Hippocampus/Amygdala\n');
fprintf('Class-specific figures created for: %s\n', strjoin(corticalClasses, ', '));

%% Compile all figures into a comprehensive PDF document
fprintf('Creating comprehensive PDF document...\n');

% Initialize figure list for PDF compilation
figureList = {};

% Add class-specific cortical figures and their legends
for classIdx = 1:length(corticalClasses)
    classFileName = strrep(corticalClasses{classIdx}, ' ', '_');
    classFileName = strrep(classFileName, '/', '_');
    
    % Add brain figure
    cortexFigPath = [saveDir 'Cortex_' classFileName '.png'];
    if exist(cortexFigPath, 'file')
        figureList{end+1} = cortexFigPath;
    end
    
    % Add corresponding legend
    legendFigPath = [saveDir 'Legend_' classFileName '.png'];
    if exist(legendFigPath, 'file')
        figureList{end+1} = legendFigPath;
    end
end

% Add overall cortex figure
overallCortexPath = [saveDir 'CortexAllRegions.png'];
if exist(overallCortexPath, 'file')
    figureList{end+1} = overallCortexPath;
end

% Add insula figure and legend
insulaFigPath = [saveDir 'InsulaRegions.png'];
if exist(insulaFigPath, 'file')
    figureList{end+1} = insulaFigPath;
end

insulaLegendPath = [saveDir 'Legend_Insula.png'];
if exist(insulaLegendPath, 'file')
    figureList{end+1} = insulaLegendPath;
end

% Add hippocampus/amygdala figure and legend
hipAmygFigPath = [saveDir 'HippocampusAmygdalaRegions.png'];
if exist(hipAmygFigPath, 'file')
    figureList{end+1} = hipAmygFigPath;
end

hipAmygLegendPath = [saveDir 'Legend_HippocampusAmygdala.png'];
if exist(hipAmygLegendPath, 'file')
    figureList{end+1} = hipAmygLegendPath;
end

% Add comprehensive legend
comprehensiveLegendPath = [saveDir 'ComprehensiveLegend.png'];
if exist(comprehensiveLegendPath, 'file')
    figureList{end+1} = comprehensiveLegendPath;
end

% Create PDF document
if ~isempty(figureList)
    % Create a new figure for PDF compilation
    pdfFig = figure('Visible', 'off', 'Position', [100, 100, 1200, 1600]);
    
    % Calculate pages needed (2 figures per page for better readability)
    figuresPerPage = 2;
    numPages = ceil(length(figureList) / figuresPerPage);
    
    % Set up PDF file path
    pdfPath = [saveDir 'BrainRegionLegends_Complete.pdf'];
    
    % Process each page
    for pageIdx = 1:numPages
        clf(pdfFig); % Clear figure
        
        % Calculate figure indices for this page
        startIdx = (pageIdx - 1) * figuresPerPage + 1;
        endIdx = min(pageIdx * figuresPerPage, length(figureList));
        
        % Add title for the page
        sgtitle(sprintf('Brain Region Reference Legends - Page %d of %d', pageIdx, numPages), ...
            'FontSize', 14, 'FontWeight', 'bold');
        
        % Add figures to this page
        for figIdx = startIdx:endIdx
            subplotIdx = figIdx - startIdx + 1;
            
            % Read and display image
            img = imread(figureList{figIdx});
            
            % Create subplot with proper spacing
            subplot(figuresPerPage, 1, subplotIdx);
            imshow(img);
            
            % Add figure title based on filename
            [~, filename, ~] = fileparts(figureList{figIdx});
            title(strrep(filename, '_', ' '), 'FontSize', 12, 'Interpreter', 'none');
        end
        
        % Save page to PDF
        if pageIdx == 1
            exportgraphics(pdfFig, pdfPath, 'ContentType', 'image', 'Resolution', 300);
        else
            exportgraphics(pdfFig, pdfPath, 'ContentType', 'image', 'Resolution', 300, 'Append', true);
        end
    end
    
    close(pdfFig);
    fprintf('PDF document created: %s\n', pdfPath);
    fprintf('Total figures compiled: %d\n', length(figureList));
else
    fprintf('No figures found to compile into PDF\n');
end

%% Custom color generation function
function colors = generateDistinctBrainColors(nColors)
    % Generate a set of visually distinct colors suitable for brain region visualization
    % This function creates colors that are:
    % 1. Visually distinct from each other
    % 2. Suitable for medical/scientific visualization
    % 3. Avoid colors that might be confused with background
    
    fprintf('Debug: generateDistinctBrainColors called with nColors = %d\n', nColors);
    
    if nColors <= 0
        colors = [];
        fprintf('Debug: Returning empty colors array\n');
        return;
    end
    
    % Define base color families with good contrast and medical appropriateness
    baseHues = [
        0,      % Red
        30,     % Orange-red
        60,     % Yellow-orange
        90,     % Yellow-green
        120,    % Green
        150,    % Blue-green
        180,    % Cyan
        210,    % Light blue
        240,    % Blue
        270,    % Purple-blue
        300,    % Purple
        330     % Pink-red
    ];
    
    % Define saturation and brightness levels for variation
    satLevels = [0.7, 0.9, 0.5];  % Different saturation levels
    briLevels = [0.8, 0.6, 0.9];  % Different brightness levels
    
    colors = zeros(nColors, 3);
    colorIndex = 1;
    
    % Generate colors by cycling through hue, saturation, and brightness combinations
    for briIdx = 1:length(briLevels)
        for satIdx = 1:length(satLevels)
            for hueIdx = 1:length(baseHues)
                if colorIndex > nColors
                    break;
                end
                
                % Convert HSV to RGB
                hue = baseHues(hueIdx) / 360;
                sat = satLevels(satIdx);
                bri = briLevels(briIdx);
                
                colors(colorIndex, :) = hsv2rgb([hue, sat, bri]);
                colorIndex = colorIndex + 1;
            end
            if colorIndex > nColors, break; end
        end
        if colorIndex > nColors, break; end
    end
    
    % If we still need more colors, generate them with slight hue variations
    if colorIndex <= nColors
        for i = colorIndex:nColors
            % Create intermediate hues
            baseHueIdx = mod(i-1, length(baseHues)) + 1;
            hueOffset = (i - colorIndex) * 15; % 15-degree offset
            hue = mod(baseHues(baseHueIdx) + hueOffset, 360) / 360;
            
            % Use medium saturation and brightness
            sat = 0.75;
            bri = 0.75;
            
            colors(i, :) = hsv2rgb([hue, sat, bri]);
        end
    end
    
    % Post-process to ensure no colors are too dark or too light
    colors = max(colors, 0.1);  % Ensure minimum brightness
    colors = min(colors, 0.95); % Ensure maximum brightness
    
    % Apply slight randomization to avoid systematic patterns (but keep reproducible)
    rng(42); % Fixed seed for reproducibility
    shuffleIdx = randperm(nColors);
    colors = colors(shuffleIdx, :);
    
    fprintf('Debug: generateDistinctBrainColors returning colors with size [%d, %d]\n', size(colors, 1), size(colors, 2));
end

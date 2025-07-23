clear
close all
addpath(genpath(cd))

% Load dependencies
load('code/dependencies/templateBrain.mat');
load('code/dependencies/listHip.mat');
load('code/dependencies/listAmyg.mat');
regionSort = readtable('code/dependencies/regionCategories.xlsx');
load('data/randomForestResults/result.mat');
pooledData = load('data/pooledData.mat');

% Create output directory
saveDir = 'figures/main/figure7/';
mkdir(saveDir);



%%
correctClass = result(:,37) == result(:,38); %initialize bool for correct classification instances 
% Ensure correctClass is a row vector to match pooledData structure
correctClass = correctClass(:)';

rms = pooledData.RMS; %RMS
rmsP = pooledData.RMSP; %RMS pvalues
cohD = pooledData.cohensD; %coherence
cohDP = pooledData.pValue; %coherence pvalues

alphaCohD = calculateAlphaThreshold(cohDP, 0.0001);
alphaRMS = calculateAlphaThreshold(rmsP, 0.0001);

% Get significant responses for each measure
significantCohD = (cohDP < alphaCohD) & (cohD > 0);
significantRMS = rmsP < alphaRMS;

%% average coherence and RMS for correct vs incorrect- for rms and cohD, generate and plot the distributions for correctly classified vs incorrectly classified

% Prepare data for distributions
correctRMS = rms(correctClass);
incorrectRMS = rms(~correctClass);
correctCohD = cohD(correctClass);
incorrectCohD = cohD(~correctClass);

% Ensure arrays are column vectors for proper concatenation
correctRMS = correctRMS(:);
incorrectRMS = incorrectRMS(:);
correctCohD = correctCohD(:);
incorrectCohD = incorrectCohD(:);

% Define colors for correct (light grey) vs incorrect (modern orange) classification
correctColor = [0.8, 0.8, 0.8]; % Light grey
incorrectColor = getColors('modern orange'); % Modern orange

% Prepare data for violin plots following figure2 pattern
% Create data matrix: [correctRMS, incorrectRMS, correctCohD, incorrectCohD]
maxLength = max([length(correctRMS), length(incorrectRMS), length(correctCohD), length(incorrectCohD)]);
violinData = nan(maxLength, 4);

violinData(1:length(correctRMS), 1) = correctRMS;
violinData(1:length(incorrectRMS), 2) = incorrectRMS;
violinData(1:length(correctCohD), 3) = correctCohD;
violinData(1:length(incorrectCohD), 4) = incorrectCohD;

% Set up violin plot parameters
colors = [correctColor; incorrectColor]; % Colors for left/right halves
offset = 0.05;
groups = [1-offset, 1+offset, 2-offset, 2+offset]; % Groups for 2 violins
left = [1, 3]; % Left side indices (correct classifications)
right = [2, 4]; % Right side indices (incorrect classifications)

% Create custom box plots with dual y-axes
figure('Position', [100, 100, 800, 500]);

% Prepare data for box plots
rmsData = {correctRMS, incorrectRMS};
cohensDData = {correctCohD, incorrectCohD};
boxPositions = [1-offset, 1+offset]; % Same positions for both measures
rmsColors = [correctColor; incorrectColor];
cohensColors = [correctColor; incorrectColor];

% Function to create custom box plot
function createCustomBoxPlot(data, pos, color, boxWidth)
    data = data(~isnan(data)); % Remove NaN values
    
    if ~isempty(data)
        % Calculate statistics
        q1 = prctile(data, 25);
        q2 = median(data);
        q3 = prctile(data, 75);
        iqr = q3 - q1;
        
        % Calculate whiskers (1.5 * IQR)
        lowerWhisker = max([min(data), q1 - 1.5*iqr]);
        upperWhisker = min([max(data), q3 + 1.5*iqr]);
        
        % Draw box with light shading
        rectangle('Position', [pos-boxWidth/2, q1, boxWidth, iqr], ...
                 'FaceColor', [color, 0.3], ...
                 'EdgeColor', color, ...
                 'LineWidth', 1);
        
        % Draw median line in black for visibility
        line([pos-boxWidth/2, pos+boxWidth/2], [q2, q2], ...
             'Color', 'k', 'LineWidth', 2.5, 'LineStyle', '-', 'Marker', 'none');
        
        % Draw whiskers
        line([pos, pos], [q3, upperWhisker], ...
             'Color', color, 'LineWidth', 1, 'LineStyle', '-', 'Marker', 'none');
        line([pos, pos], [q1, lowerWhisker], ...
             'Color', color, 'LineWidth', 1, 'LineStyle', '-', 'Marker', 'none');
        
        % Draw whisker caps
        line([pos-boxWidth/4, pos+boxWidth/4], [upperWhisker, upperWhisker], ...
             'Color', color, 'LineWidth', 1, 'LineStyle', '-', 'Marker', 'none');
        line([pos-boxWidth/4, pos+boxWidth/4], [lowerWhisker, lowerWhisker], ...
             'Color', color, 'LineWidth', 1, 'LineStyle', '-', 'Marker', 'none');
    end
end

% Box width
boxWidth = 0.08;

% Plot RMS data on left y-axis
yyaxis left;
hold on;
for i = 1:length(rmsData)
    createCustomBoxPlot(rmsData{i}, boxPositions(i), rmsColors(i,:), boxWidth);
end
ylabel('RMS');
set(gca, 'YColor', 'k');

% Plot Cohen's D data on right y-axis  
yyaxis right;
hold on;
for i = 1:length(cohensDData)
    createCustomBoxPlot(cohensDData{i}, boxPositions(i) + 1, cohensColors(i,:), boxWidth); % Offset by 1 for x=2
end
ylabel('Cohen''s D');
set(gca, 'YColor', 'k');

% Customize plot
xlabel('Measure Type');
title('Classification Performance: Correct vs Incorrect');
set(gca, 'XTick', [1, 2], 'XTickLabel', {'RMS', 'Cohen''s D'});
set(gca, 'linewidth', 0.75, 'FontSize', 14, 'FontName', 'Helvetica');
xlim([0.5, 2.5]);

% Legend removed for cleaner appearance

box off;

saveas(gcf, [saveDir 'ClassificationDistributions.png']);
saveas(gcf, [saveDir 'ClassificationDistributions.svg']);

% Statistical tests comparing correct vs incorrect classifications
pRMS = ranksum(correctRMS, incorrectRMS);
pCohD = ranksum(correctCohD, incorrectCohD);

% Print summary statistics
fprintf('RMS - Correct Classification: Mean = %.3f, Std = %.3f\n', nanmean(correctRMS), nanstd(correctRMS));
fprintf('RMS - Incorrect Classification: Mean = %.3f, Std = %.3f\n', nanmean(incorrectRMS), nanstd(incorrectRMS));
fprintf('Cohen''s D - Correct Classification: Mean = %.3f, Std = %.3f\n', nanmean(correctCohD), nanstd(correctCohD));
fprintf('Cohen''s D - Incorrect Classification: Mean = %.3f, Std = %.3f\n', nanmean(incorrectCohD), nanstd(incorrectCohD));

% Print statistical test results
fprintf('\nStatistical Tests (Ranksum):\n');
fprintf('RMS: Correct vs Incorrect, p = %.6f\n', pRMS);
fprintf('Cohen''s D: Correct vs Incorrect, p = %.6f\n', pCohD);

% Save statistical results following figure2 pattern
saveResults.comparisonLabels = {'correct', 'incorrect'};
saveResults.meanRMS = [nanmean(correctRMS), nanmean(incorrectRMS)];
saveResults.stdRMS = [nanstd(correctRMS), nanstd(incorrectRMS)];
saveResults.meanCohensD = [nanmean(correctCohD), nanmean(incorrectCohD)];
saveResults.stdCohD = [nanstd(correctCohD), nanstd(incorrectCohD)];
saveResults.medianRMS = [nanmedian(correctRMS), nanmedian(incorrectRMS)];
saveResults.medianCohensD = [nanmedian(correctCohD), nanmedian(incorrectCohD)];
saveResults.pValues = [pRMS, pCohD];
appendLog('Figure 7: Classification Distribution Statistics', 'statistical comparisons between correct and incorrect classifications for RMS and Cohen''s D', saveResults);
clear saveResults;

%% percent significant cohens d or RMS for correct vs incorrect- calculate the percent of significant values for correct and incorrect classification for coherence and RMS

% Calculate percentages of significant values
percentSigRMS_Correct = sum(correctClass & significantRMS) / sum(correctClass) * 100;
percentSigRMS_Incorrect = sum(~correctClass & significantRMS) / sum(~correctClass) * 100;

percentSigCohD_Correct = sum(correctClass & significantCohD) / sum(correctClass) * 100;
percentSigCohD_Incorrect = sum(~correctClass & significantCohD) / sum(~correctClass) * 100;

% Create bar plot for percentages
figure('Position', [100, 100, 800, 600]);

% Data for bar plot
percentageData = [percentSigRMS_Correct, percentSigRMS_Incorrect; 
                  percentSigCohD_Correct, percentSigCohD_Incorrect];

b = bar(percentageData, 'EdgeColor', 'none');
b(1).FaceColor = correctColor;
b(2).FaceColor = incorrectColor;

% Formatting
set(gca, 'XTickLabel', {'RMS', 'Cohen''s D'});
ylabel('Percentage of Significant Responses (%)');
title('Percentage of Significant Responses by Classification Accuracy');
box off;

% Add percentage labels on bars
for i = 1:size(percentageData, 1)
    for j = 1:size(percentageData, 2)
        text(i + (j-1.5)*0.15, percentageData(i,j) + 1, ...
             sprintf('%.1f%%', percentageData(i,j)), ...
             'HorizontalAlignment', 'center', 'FontSize', 10);
    end
end

saveas(gcf, [saveDir 'SignificancePercentages.png']);
saveas(gcf, [saveDir 'SignificancePercentages.svg']);

% Print percentage results
fprintf('\nPercentage of Significant Responses:\n');
fprintf('RMS - Correct Classification: %.1f%%\n', percentSigRMS_Correct);
fprintf('RMS - Incorrect Classification: %.1f%%\n', percentSigRMS_Incorrect);
fprintf('Cohen''s D - Correct Classification: %.1f%%\n', percentSigCohD_Correct);
fprintf('Cohen''s D - Incorrect Classification: %.1f%%\n', percentSigCohD_Incorrect);

% Save percentage results
saveResults.comparisonLabels = {'RMS_correct', 'RMS_incorrect', 'CohensD_correct', 'CohensD_incorrect'};
saveResults.percentageSignificant = [percentSigRMS_Correct, percentSigRMS_Incorrect, percentSigCohD_Correct, percentSigCohD_Incorrect];
saveResults.totalCorrect = sum(correctClass);
saveResults.totalIncorrect = sum(~correctClass);
appendLog('Figure 7: Significant Response Percentages', 'percentage of significant responses by classification accuracy for RMS and Cohen''s D', saveResults);
clear saveResults;

%% Generate anatomical figures showing the percentage of correctly classified responses at each region.

% Prepare brain models following figure6 pattern
hipAmyg = [listAmyg, listHip];
brainFieldnames = fieldnames(templateBrain.regions);

% Prepare brain models for visualization (following figure6 pattern)
hipAmygBool = contains(templateBrain.regionList, hipAmyg);
brainFieldnames2 = brainFieldnames(~hipAmygBool);

templateBrain2 = struct('regions', struct());
for i = 1:length(brainFieldnames2)
    templateBrain2.regions.(brainFieldnames2{i}) = templateBrain.regions.(brainFieldnames2{i});
end

% Create right and left hemisphere models
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

% Generate insula model
insulaBool = contains(templateBrain.regionList, regionSort{strcmp(regionSort{:,3}, 'Insula'), 1});
insulaFieldnames = brainFieldnames(insulaBool);
insulaTemplate = struct('regions', struct());
for i = 1:length(insulaFieldnames)
   insulaTemplate.regions.(insulaFieldnames{i}) = templateBrain.regions.(insulaFieldnames{i});
end
insulaTemplateLeft = getOneSide(insulaTemplate, 'left');

% Calculate percentage of correctly classified responses for each brain region
percentCorrect = zeros(1, length(brainFieldnames));
storeNoCoverage = zeros(1, length(brainFieldnames));

for r = 1:length(brainFieldnames)
    curRegion = templateBrain.regionList{r};
    curRegionIDX = contains([pooledData.electrodeRegionLabel{:}], curRegion);
    
    if sum(curRegionIDX) == 0
        storeNoCoverage(r) = 1;
        percentCorrect(r) = nan;
    else
        storeNoCoverage(r) = 0;
        % Calculate percentage of correct classifications in this region
        % Simple calculation: how many correct out of total in this region
        regionCorrect = sum(correctClass(curRegionIDX));
        regionTotal = sum(curRegionIDX);
        percentCorrect(r) = (regionCorrect / regionTotal) * 100;
    end
end

% Prepare colors for visualization
Alphas = percentCorrect;
Nan = isnan(Alphas);
noCover = logical(storeNoCoverage);

% Use a gradient colormap from low (red) to high (green) classification accuracy
classificationColormap = colormap('turbo');
Colors = mapEffectSizesToColors(Alphas, classificationColormap, 'to range', [0 100]);

Colors(Nan,:) = 0.8; % Gray for NaN
Colors(noCover,:) = 0.4; % Dark gray for no coverage

% Create brain visualization
figure('Position', [38, 188, 3397, 946]);
sgtitle('Classification Accuracy by Brain Region (%)', 'FontSize', 16, 'FontWeight', 'bold');

subplot(1, 5, 1);
plotProjectedRegionsOnly(templateBrainLeft, Colors);
view([270, 0]);
title('Left Lateral');
axis off;

subplot(1, 5, 2);
plotProjectedRegionsOnly(templateBrainRight, Colors);
view([270, 0]);
title('Right Lateral');
axis off;

subplot(1, 5, 3);
insulaColors = Colors(insulaBool, :);
plotProjectedRegionsOnly(insulaTemplateLeft, insulaColors);
view([270, 0]);
title('Insula');
axis off;

subplot(1, 5, 4);
hipAmygColors = Colors(hipAmygBool, :);
plotProjectedRegionsOnly(hipAmygTemplate, hipAmygColors);
view([-176.4, -90.0]);
title('Hippocampus/Amygdala View 1');
axis off;

subplot(1, 5, 5);
hipAmygColors = Colors(hipAmygBool, :);
plotProjectedRegionsOnly(hipAmygTemplate, hipAmygColors);
view([-180.8, 73.9]);
title('Hippocampus/Amygdala View 2');
axis off;

saveas(gcf, [saveDir 'ClassificationAccuracyBrain.png']);
saveas(gcf, [saveDir 'ClassificationAccuracyBrain.svg']);

% Create colorbar legend
figure();
ax = axes;
colorbar(ax);
colormap(classificationColormap);
clim([0, 100]);
title('Classification Accuracy (%)');
text(0.5, 0.5, sprintf('Range: %.1f%% - %.1f%%', min(Alphas(~Nan)), max(Alphas(~Nan))), ...
     'Units', 'normalized', 'HorizontalAlignment', 'center');
axis off;

saveas(gcf, [saveDir 'ClassificationAccuracyLegend.svg']);

% Create distribution plot of classification accuracy across regions using kernel density
figure('Position', [1440, 818, 1471, 420]);
[f_accuracy, xi_accuracy] = ksdensity(Alphas(~Nan));
plot(xi_accuracy, f_accuracy, 'Color', getColors('modern orange'), 'LineWidth', 2);
xlabel('Classification Accuracy (%)');
ylabel('Density');
title('Distribution of Classification Accuracy Across Brain Regions');
box off;

saveas(gcf, [saveDir 'ClassificationAccuracyDistribution.svg']);

% Save results
saveResults.regionNames = templateBrain.regionList;
saveResults.classificationAccuracy = percentCorrect;
saveResults.overallAccuracy = sum(correctClass) / length(correctClass) * 100;
saveResults.totalResponses = length(correctClass);
saveResults.correctResponses = sum(correctClass);

appendLog('Figure 7: Classification Analysis', 'Random forest classification accuracy analysis', saveResults);

% Print summary
fprintf('\nOverall Classification Accuracy: %.1f%% (%d/%d)\n', ...
        saveResults.overallAccuracy, saveResults.correctResponses, saveResults.totalResponses);
fprintf('Best performing region: %s (%.1f%%)\n', ...
        templateBrain.regionList{find(percentCorrect == max(percentCorrect(~isnan(percentCorrect))), 1)}, ...
        max(percentCorrect(~isnan(percentCorrect))));
fprintf('Worst performing region: %s (%.1f%%)\n', ...
        templateBrain.regionList{find(percentCorrect == min(percentCorrect(~isnan(percentCorrect))), 1)}, ...
        min(percentCorrect(~isnan(percentCorrect))));
close all
clear
addpath(genpath(cd))
load("data/interChannelCoherenceSignificant.mat", "interChannelCoherence")
saveDir = 'figures/main/figure4/dependencies/';
mkdir(saveDir)

% Remove regions field if it exists
if isfield(interChannelCoherence, 'regions')
    interChannelCoherence = rmfield(interChannelCoherence, 'regions');
end

% Initialize colors for each condition
aColor = getColors('lush lilac');
mColor = getColors('celadon porcelain');
pColor = getColors('lago blue');

% Load brain templates and region information
load('code/dependencies/templateBrain.mat');
load('code/dependencies/listHip.mat');
load('code/dependencies/listAmyg.mat');
regionSort = readtable('code/dependencies/regionCategories.xlsx');
hipAmyg = [listAmyg, listHip];
brainFieldnames = fieldnames(templateBrain.regions);

%%
% Get the condition names from the structure fields
conditions = fieldnames(interChannelCoherence);

% First, find the global minimum correlation value across all conditions
globalMinCorr = Inf;
globalMaxCorr = -Inf;

for condIdx = 1:length(conditions)
    conditionName = conditions{condIdx};
    
    % Extract matrices for the current condition
    tc = interChannelCoherence.(conditionName).taskCoherence;
    pValues = interChannelCoherence.(conditionName).pValue;
    
    % Find non-zero, non-NaN, significant correlations
    validCorr = tc(~isnan(tc) & tc ~= 0 & pValues < 0.001);
    
    if ~isempty(validCorr)
        globalMinCorr = min(globalMinCorr, min(validCorr));
        globalMaxCorr = max(globalMaxCorr, max(validCorr));
    end
end

% If no valid correlations were found, set defaults
if isinf(globalMinCorr)
    globalMinCorr = 0;
    globalMaxCorr = 1;
end

fprintf('Global correlation range: [%.4f, %.4f]\n', globalMinCorr, globalMaxCorr);

% Define grey color for masking non-significant or NaN values
greyColor = [0.8, 0.8, 0.8];

% Process each condition
for condIdx = 1:length(conditions)
    conditionName = conditions{condIdx};
    
    % Use MATLAB's built-in parula colormap
    currentColormap = parula;
    
    % Extract data for the current condition
    tc = interChannelCoherence.(conditionName).taskCoherence;
    pValues = interChannelCoherence.(conditionName).pValue;
    labels = interChannelCoherence.(conditionName).labels;
    
    % Identify valid channels (with non-NaN values and significant connections)
    validChannels = false(1, size(tc, 1));
    alpha = 0.05; % Significance threshold
    
    for j = 1:size(tc, 1)
        % Create mask for non-diagonal elements
        mask = true(1, size(tc, 1));
        mask(j) = false; % Exclude diagonal
        
        % Check for NaN values and significant connections
        row_values = tc(j, :);
        col_values = tc(:, j)';
        row_has_values = ~all(isnan(row_values(mask)));
        col_has_values = ~all(isnan(col_values(mask)));
        
        row_p = pValues(j, :);
        col_p = pValues(:, j)';
        row_has_sig = any(row_p(mask) < alpha & ~isnan(row_p(mask)));
        col_has_sig = any(col_p(mask) < alpha & ~isnan(col_p(mask)));
        
        % A channel is valid if it has non-NaN values AND has at least one significant connection
        validChannels(j) = (row_has_values || col_has_values) && (row_has_sig || col_has_sig);
    end
    
    % Filter out invalid channels
    tc_filtered = tc(validChannels, validChannels);
    p_filtered = pValues(validChannels, validChannels);
    labels_filtered = labels(validChannels);
    
    % Skip processing if too few valid channels
    if sum(validChannels) < 2
        fprintf('Condition %s has too few valid channels (%d). Skipping.\n', ...
                conditionName, sum(validChannels));
        continue;
    end
    
    % Create masks for NaN and non-significant values
    combined_mask = isnan(tc_filtered) | p_filtered >= 0.001;
    
    % Replace NaN and non-significant values with 0 for clustering calculations
    tc_filtered(combined_mask) = 0;

    % Symmetrize the correlation matrix
    tc_sym = tc_filtered + tc_filtered' - diag(diag(tc_filtered));
    
    % Create distance matrix for clustering (d = 1 - correlation)
    D = 1 - tc_sym;
    D(1:size(D,1)+1:end) = 0; % Ensure diagonal is zero
    
    % Convert to vector form for linkage function
    distVec = squareform(D);
    
    % Perform hierarchical clustering using average linkage
    Z = linkage(distVec, 'average');
    
    % Create figure for visualization
    fig1 = figure('Name', ['Condition: ', conditionName, ' (', num2str(sum(validChannels)), '/', num2str(length(validChannels)), ' valid channels)'], ...
           'NumberTitle', 'off', 'Position', [800          60        1674        1247]);
    
    % Get leaf ordering from dendrogram (invisible figure)
    hFig = figure('Visible', 'off');
    [~, ~, outperm] = dendrogram(Z, 0);
    close(hFig);
    
    % Create mask for non-significant or NaN values
    mask = (tc_sym == 0);
    
    % Prepare visualization matrix
    tc_viz = tc_sym;
    tc_viz(mask) = NaN; % Mask with NaN for special coloring
    
    % Plot heatmap
    h = imagesc(tc_viz);
    ax = gca;
    ax.CLim = [globalMinCorr, 1]; % Set consistent color limits
    
    % Make NaN values transparent and show grey background
    set(h, 'AlphaData', ~isnan(tc_viz));
    set(ax, 'Color', greyColor);
    
    % Apply colormap and add colorbar
    colormap(ax, currentColormap);
    c = colorbar;
    
    % Set titles and labels
    title(['Original Correlation Matrix - ', conditionName]);
    xlabel('Channel');
    ylabel('Channel');
    set(ax, 'XTick', 1:length(labels_filtered), 'XTickLabel', labels_filtered, ...
            'YTick', 1:length(labels_filtered), 'YTickLabel', labels_filtered, ...
            'TickLabelInterpreter', 'none');
    xtickangle(45);
    ylabel(c, sprintf('Correlation\n[%.2f, %.2f]', globalMinCorr, 1));
    saveas(fig1,[saveDir '_' conditionName 'correlationMatrix.svg'])
    
    % Plot 2: Dendrogram
    fig2 = figure('Position', [800          60        1674        1247]);
    dendrogram(Z, 0, 'Labels', labels_filtered);
    title(['Hierarchical Clustering - ', conditionName]);
    xlabel('Channel');
    ylabel('Distance (1 - correlation)');
    ax2 = gca;
    set(ax2, 'TickLabelInterpreter', 'none');

    % Find optimal clustering threshold
    [distanceThreshold, thresholdMetrics.(conditionName)] = findOptimalClusterThreshold(Z,[],'similarity');
    
    % Add threshold line to dendrogram
    hold on;
    plot(get(ax2, 'XLim'), [distanceThreshold, distanceThreshold], 'r--', 'LineWidth', 2);
    hold off;
    
    % Get clusters at the threshold
    clusters = cluster(Z, 'Cutoff', distanceThreshold, 'Criterion', 'distance');
    numClusters = max(clusters);
    
    saveas(fig2,[saveDir '_' conditionName '_dendrogram.svg'])

    % Plot 3: Reordered correlation matrix by clusters
    fig3 = figure('Position', [800          60        1674        1247]);
    
    % Reorder matrix and labels based on dendrogram leaf order
    tc_reordered = tc_sym(outperm, outperm);
    reordered_labels = labels_filtered(outperm);
    reordered_clusters = clusters(outperm);
    
    % Create left-to-right cluster ordering
    [unique_clusters, ~] = unique(reordered_clusters, 'stable');
    cluster_map = zeros(max(clusters), 1);
    for clIdx = 1:length(unique_clusters)
        cluster_map(unique_clusters(clIdx)) = clIdx;
    end
    
    % Remap clusters for visualization
    reordered_clusters_mapped = cluster_map(reordered_clusters);
    
    % Prepare reordered matrix for visualization
    mask_reordered = (tc_reordered == 0);
    tc_reordered_viz = tc_reordered;
    tc_reordered_viz(mask_reordered) = NaN;
    
    % Plot reordered heatmap
    h_reordered = imagesc(tc_reordered_viz);
    ax3 = gca;
    ax3.CLim = [globalMinCorr, 1];
    
    % Make NaN values transparent and show grey background
    set(h_reordered, 'AlphaData', ~isnan(tc_reordered_viz));
    set(ax3, 'Color', greyColor);
    
    % Apply colormap and add colorbar
    colormap(ax3, currentColormap);
    c = colorbar;
    
    % Set titles and labels
    xlabel('Channel');
    ylabel('Channel');
    set(ax3, 'XTick', 1:length(reordered_labels), 'XTickLabel', reordered_labels, ...
            'YTick', 1:length(reordered_labels), 'YTickLabel', reordered_labels, ...
            'TickLabelInterpreter', 'none');
    xtickangle(45);
    ylabel(c, sprintf('Correlation\n[%.2f, %.2f]', globalMinCorr, 1));
    
    % Add cluster boundary lines
    hold on;
    
    % Identify valid clusters (more than 2 regions)
    valid_cluster_nums = [];
    for clIdx = 1:max(reordered_clusters_mapped)
        if sum(reordered_clusters_mapped == clIdx) > 2
            valid_cluster_nums = [valid_cluster_nums, clIdx];
        end
    end
    
    % Create mapping for valid clusters
    valid_clusters = zeros(size(reordered_clusters_mapped));
    for idx = 1:length(reordered_clusters_mapped)
        if ismember(reordered_clusters_mapped(idx), valid_cluster_nums)
            valid_clusters(idx) = find(valid_cluster_nums == reordered_clusters_mapped(idx));
        end
    end
    
    % Draw cluster boundary lines
    validClusterBoundaries = find(diff(valid_clusters) ~= 0);
    for b = 1:length(validClusterBoundaries)
        % Horizontal and vertical lines at cluster boundaries
        line([0.5, length(reordered_clusters)+0.5], [validClusterBoundaries(b)+0.5, validClusterBoundaries(b)+0.5], ...
             'Color', 'k', 'LineWidth', 2);
        line([validClusterBoundaries(b)+0.5, validClusterBoundaries(b)+0.5], [0.5, length(reordered_clusters)+0.5], ...
             'Color', 'k', 'LineWidth', 2);
    end
    hold off;
    axis square
    saveas(fig3,[saveDir '_' conditionName '_reorderedCorrelationMatrix.svg'])

    % Plot 4: Metrics for threshold selection
    fig4 = figure('Position', [800          60        1674        1247]);
    
    % Extract threshold values and metrics
    thresholdValues = [thresholdMetrics.(conditionName).threshold];
    entropyValues = [thresholdMetrics.(conditionName).shannonEntropy];
    
    % Calculate merge density
    heights = Z(:,3);
    numBins = 20;
    [mergeDensity, binEdges] = histcounts(heights, numBins);
    binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;
    normMergeDensity = mergeDensity / max(mergeDensity);
    
    % Find natural break points (local minima in merge density)
    localMinima = find(diff(sign(diff([Inf, normMergeDensity, Inf]))) > 0);
    naturalBreakPoints = binCenters(localMinima);
    
    % Plot Shannon entropy on left y-axis
    yyaxis left
    plot(thresholdValues, entropyValues, '-', 'LineWidth', 2, 'Color', [0.2 0.4 0.8], 'MarkerFaceColor', [0.2 0.4 0.8]);
    ylabel('Shannon Entropy', 'Color', [0.2 0.4 0.8]);
    
    % Add marker for selected threshold
    hold on;
    selectedThresholdIdx = find(abs(thresholdValues - distanceThreshold) < 1e-6, 1);
    if ~isempty(selectedThresholdIdx)
        plot(distanceThreshold, entropyValues(selectedThresholdIdx), 'o', ...
             'MarkerSize', 10, 'LineWidth', 2, 'Color', [0.2 0.4 0.8]);
    end
    hold off;
    
    % Plot merge density on right y-axis
    yyaxis right
    plot(binCenters, normMergeDensity, '-', 'LineWidth', 2, 'Color', [0.3 0.7 0.3]);
    hold on;
    
    % Plot natural break points as vertical lines
    for bpIdx = 1:length(naturalBreakPoints)
        plot([naturalBreakPoints(bpIdx), naturalBreakPoints(bpIdx)], [0, normMergeDensity(localMinima(bpIdx))], '--', 'Color', [0.7 0.3 0.3], 'LineWidth', 1);
    end
    
    % Add threshold line
    ylimits = [0 1];
    ylim(ylimits);
    line([distanceThreshold, distanceThreshold], ylimits, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
    
    % Configure y-axis appearance
    ax4 = gca;
    ax4.YAxis(2).Color = [0.3 0.7 0.3];
    ylabel('Normalized Merge Density', 'Color', [0.3 0.7 0.3]);
    ax4.YAxis(2).TickValues = 0:0.2:1;
    
    % Add labels and styling
    xlabel('Distance Threshold');
    title('Cluster Metrics and Merge Density');
    title(['selected threshold ' num2str(distanceThreshold)])
    set(ax4, 'Box', 'off');
    
    % Add legend
    legend({'Shannon Entropy', 'Merge Density', 'Natural Break Points'}, 'Location', 'best', 'Box', 'off');
    saveas(fig4,[saveDir '_' conditionName '_shannonEntropyMergeDensity.svg'])
    % Apply colormap to entire figure
    colormap(currentColormap);
    
    % Add overall figure title
    sgtitle([conditionName, ': ', num2str(numClusters), ' clusters at threshold ', num2str(distanceThreshold)], 'FontWeight', 'bold');
    
    % Store cluster assignments in the structure
    % Create mapping from filtered labels to original positions
    labelMap = containers.Map(labels_filtered, find(validChannels));
    
    % Initialize cluster assignments
    regionClusterLabels = zeros(length(templateBrain.regionList), 1);
    
    % Create inverse cluster mapping
    inverse_cluster_map = zeros(max(clusters), 1);
    for clIdx = 1:length(unique_clusters)
        inverse_cluster_map(unique_clusters(clIdx)) = clIdx;
    end
    
    % Assign cluster labels to regions
    for j = 1:length(labels_filtered)
        origIdx = labelMap(labels_filtered{j});
        regionIdx = find(strcmp(templateBrain.regionList, labels{origIdx}));
        
        if ~isempty(regionIdx)
            originalCluster = clusters(j);
            remappedCluster = inverse_cluster_map(originalCluster);
            regionClusterLabels(regionIdx) = remappedCluster;
        end
    end
    
    % Identify and handle small clusters (≤2 regions)
    clusterCounts = zeros(numClusters, 1);
    for clIdx = 1:numClusters
        clusterCounts(clIdx) = sum(regionClusterLabels == clIdx);
    end
    
    smallClusters = find(clusterCounts <= 2);
    for scIdx = 1:length(smallClusters)
        smallClusterIdx = smallClusters(scIdx);
        regionClusterLabels(regionClusterLabels == smallClusterIdx) = 0;
    end
    
    % Display cluster information
    fprintf('\nCondition: %s\n', conditionName);
    fprintf('Number of clusters: %d\n', numClusters);
    
    if ~isempty(smallClusters)
        fprintf('Small clusters (≤2 regions) set to 0: %s\n', num2str(smallClusters'));
    end
    
    % Print regions in each cluster
    validClusters = setdiff(unique(regionClusterLabels), 0);
    for vcIdx = 1:length(validClusters)
        clusterIdx = validClusters(vcIdx);
        clusterRegions = templateBrain.regionList(regionClusterLabels == clusterIdx);
        fprintf('Cluster %d: %s\n', clusterIdx, strjoin(clusterRegions, ', '));
    end
    
    % Store results in the structure
    interChannelCoherence.(conditionName).regionClusterLabels = regionClusterLabels;
    interChannelCoherence.(conditionName).clusterRegionNames = cell(max(regionClusterLabels), 1);
    
    for clIdx = 1:max(regionClusterLabels)
        interChannelCoherence.(conditionName).clusterRegionNames{clIdx} = ...
            templateBrain.regionList(regionClusterLabels == clIdx);
    end
    
    interChannelCoherence.(conditionName).clusterMapping = inverse_cluster_map;

    % Calculate cophenetic distances and entropy
    copheneticDistances = pdist(tc_sym, 'correlation');
    interChannelCoherence.(conditionName).copheneticEntropy = -sum(copheneticDistances .* log2(copheneticDistances + eps), 'all') / numel(copheneticDistances);
    interChannelCoherence.(conditionName).copheneticDistances = copheneticDistances;

    % Calculate average correlations per region
    interChannelCoherence.(conditionName).avgCorrelations = mean(tc_sym, 2, 'omitnan');
    interChannelCoherence.(conditionName).regionLabels = labels_filtered;
end

%% Create visualization of cophenetic entropy and average correlations
figure('Name', 'Tree Entropy and Average Correlations', 'Position', [100, 100, 1200, 500]);

% Store data for each condition for statistical comparison
copheneticData = cell(length(conditions), 1);
correlationData = cell(length(conditions), 1);

% Subplot 1: Cophenetic Entropy Distribution
subplot(1,2,1)
hold on;
% Define colors for each condition
conditionColors = containers.Map({'ACC', 'MCC', 'PCC'}, {aColor, mColor, pColor});
for condIdx = 1:length(conditions)
    conditionName = conditions{condIdx};
    if isfield(interChannelCoherence.(conditionName), 'copheneticDistances')
        distances = interChannelCoherence.(conditionName).copheneticDistances;
        copheneticData{condIdx} = distances; % Store for statistical comparison
        [f, xi] = ksdensity(distances);
        plot(xi, f, 'LineWidth', 2, 'Color', conditionColors(conditionName));
    end
end
xlabel('Cophenetic Distance');
ylabel('Density');
title('Cophenetic Distance Distribution');
legend(conditions, 'Location', 'best');

% Perform pairwise ranksum tests for cophenetic distances and add p-values to plot
y_pos = 0.9;
p_acc_mcc = ranksum(copheneticData{1}, copheneticData{2});
text(0.1, y_pos, ['ACC vs MCC: p = ' num2str(p_acc_mcc)], 'Units', 'normalized');
y_pos = y_pos - 0.1;

p_acc_pcc = ranksum(copheneticData{1}, copheneticData{3});
text(0.1, y_pos, ['ACC vs PCC: p = ' num2str(p_acc_pcc)], 'Units', 'normalized');
y_pos = y_pos - 0.1;

p_mcc_pcc = ranksum(copheneticData{2}, copheneticData{3});
text(0.1, y_pos, ['MCC vs PCC: p = ' num2str(p_mcc_pcc)], 'Units', 'normalized');
box off;

saveResults.conditions = {'ACC', 'MCC', 'PCC'};
saveResults.meanCopeneticDistances = [mean(copheneticData{1}),mean(copheneticData{2}),mean(copheneticData{3})];
saveResults.stdCopeneticDistances = [std(copheneticData{1}),std(copheneticData{2}),std(copheneticData{3})];
saveResults.comparisonLabels = {'ACC vs MCC','ACC vs PCC','MCC vs PCC'};
saveResults.comparisonCopheneticDistance = [p_acc_mcc,p_acc_pcc,p_mcc_pcc];

% Subplot 2: Average Correlations Swarm Plot
subplot(1,2,2);

% Prepare data for beeswarm - one group per condition
dataVec = []; % Vector to store all data points
groupVec = []; % Vector to store group assignments

for condIdx = 1:length(conditions)
    conditionName = conditions{condIdx};
    if isfield(interChannelCoherence.(conditionName), 'avgCorrelations')
        % Get correlations for this condition
        correlations = interChannelCoherence.(conditionName).avgCorrelations;
        
        % Store for statistical comparison
        correlationData{condIdx} = correlations;
        
        % Add to data vector
        dataVec = [dataVec; correlations];
        
        % Assign group number (1, 2, or 3)
        groupVec = [groupVec; repmat(condIdx, length(correlations), 1)];
    end
end

% Create beeswarm plot
beeswarm(groupVec, dataVec, 'colormap', [aColor; mColor; pColor], 'overlay_style', 'ci', 'MarkerFaceAlpha', 0.6);

% Customize x-axis labels
set(gca, 'XTick', 1:length(conditions), 'XTickLabel', conditions);

% Perform pairwise ranksum tests for average correlations
y_pos = 0.9;
p_acc_mcc = ranksum(correlationData{1}, correlationData{2});
text(0.1, y_pos, ['ACC vs MCC: p = ' num2str(p_acc_mcc)], 'Units', 'normalized');
y_pos = y_pos - 0.1;

p_acc_pcc = ranksum(correlationData{1}, correlationData{3});
text(0.1, y_pos, ['ACC vs PCC: p = ' num2str(p_acc_pcc)], 'Units', 'normalized');
y_pos = y_pos - 0.1;

p_mcc_pcc = ranksum(correlationData{2}, correlationData{3});
text(0.1, y_pos, ['MCC vs PCC: p = ' num2str(p_mcc_pcc)], 'Units', 'normalized');

ylabel('Average Correlation');
title('Average Correlations by Condition');
box off;
saveas(gcf,[saveDir 'copheneticEntropyAverageCorrelations.svg'])



saveResults.meanCorrelations = [nanmean(correlationData{1}),nanmean(correlationData{2}),nanmean(correlationData{3})];
[aL, aU] = bootstrapCI(correlationData{1}); %get upper and lower confidence interval values
[mL, mU] = bootstrapCI(correlationData{2});
[pL, pU] = bootstrapCI(correlationData{3});
saveResults.ciCorrelationsLower = [aL, mL, pL];
saveResults.ciCorrelationsUpper = [aU, mU, pU];
saveResults.comparisonCorrelations = [p_acc_mcc,p_acc_pcc,p_mcc_pcc];

appendLog('Fig 4', 'hierarchical clustering, comparisons of cophenetic distances and of correlations between regions', saveResults)

%% Prepare brain models for visualization
% Generate brain model without hippocampus/amygdala
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

%% Visualize clusters on 3D brain models
% Create colormap for clusters
clusterColormap = [
    0.8, 0.8, 0.8;  % Cluster 0 (small clusters) - light gray
    getColors('rainbow matrix')  % Using rainbow matrix colormap for clusters
];

% Process each condition
for condIdx = 1:length(conditions)
    conditionName = conditions{condIdx};
    
    % Skip if no cluster information
    if ~isfield(interChannelCoherence.(conditionName), 'regionClusterLabels')
        continue;
    end
    
    % Get cluster labels
    regionClusterLabels = interChannelCoherence.(conditionName).regionClusterLabels;
    
    % Create figure for brain visualizations
    figure('Name', ['Clusters - ' conditionName], 'Position', [281, 32, 3060, 1260]);
    
    % Find non-zero unique clusters (exclude 0 which is for small/unclustered regions)
    validClusters = setdiff(unique(regionClusterLabels), 0);
    
    % Create mapping from original cluster indices to sequential numbers (1,2,3...)
    seqClusterMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
    seqClusterMap(0) = 0; % Keep 0 as is for small/unclustered regions
    
    for i = 1:length(validClusters)
        seqClusterMap(validClusters(i)) = i;
    end
    
    % Create sequential cluster labels
    seqRegionClusterLabels = zeros(size(regionClusterLabels));
    for i = 1:length(regionClusterLabels)
        if regionClusterLabels(i) > 0
            seqRegionClusterLabels(i) = seqClusterMap(regionClusterLabels(i));
        end
    end
    
    % Assign colors based on sequential cluster labels
    regionColors = zeros(length(templateBrain.regionList), 3);
    colorIndices = seqRegionClusterLabels + 1;  % Add 1 to use as colormap indices
    
    for i = 1:length(colorIndices)
        colorIdx = min(colorIndices(i), size(clusterColormap, 1));
        regionColors(i, :) = clusterColormap(colorIdx, :);
    end
    
    % Left Cortex View
    subplot(2, 3, 1);
    plotProjectedRegionsOnly(templateBrainLeft, regionColors);
    view([270, 0]);
    
    % Right Cortex View
    subplot(2, 3, 2);
    rightColors = regionColors(~hipAmygBool, :);
    plotProjectedRegionsOnly(templateBrainRight, rightColors);
    view([270, 0]);
    
    % Insula View
    subplot(2, 3, 3);
    insulaColors = regionColors(insulaBool, :);
    plotProjectedRegionsOnly(insulaTemplateLeft, insulaColors);
    view([270, 0]);
    
    % Hippocampus/Amygdala View 1
    subplot(2, 3, 4);
    hipAmygColors = regionColors(hipAmygBool, :);
    plotProjectedRegionsOnly(hipAmygTemplate, hipAmygColors);
    view([-176.4, -90.0]);
    
    % Hippocampus/Amygdala View 2
    subplot(2, 3, 5);
    plotProjectedRegionsOnly(hipAmygTemplate, hipAmygColors);
    view([-180.8, 73.9]);
    
    % Create a legend subplot showing cluster colors
    subplot(2, 3, 6);
    
    % Find unique clusters in sequential numbering
    uniqueSeqClusters = unique(seqRegionClusterLabels);
    numClusters = length(uniqueSeqClusters);
    
    % Simple legend implementation
    if numClusters > 0
        hold on;
        axis off;  % Turn off axis
        
        % Create a simple color legend
        for i = 1:numClusters
            clusterIdx = uniqueSeqClusters(i);
            colorIdx = clusterIdx + 1;  % Add 1 to match colormap indexing
            
            % Plot a colored rectangle
            y_pos = numClusters - i + 1;  % Position from top to bottom
            rectangle('Position', [0.1, y_pos-0.3, 0.3, 0.6], 'FaceColor', clusterColormap(colorIdx, :), 'EdgeColor', 'k');
            
            % Add text label
            if clusterIdx == 0
                text(0.5, y_pos, 'Small/unclustered', 'FontSize', 14);
            else
                % Just use the sequential cluster number for the label
                text(0.5, y_pos, ['Cluster ', num2str(clusterIdx)], 'FontSize', 14);
            end
        end
        
        % Set axis limits
        ylim([0, numClusters+1]);
        xlim([0, 3]);
        
        title('Cluster Legend', 'FontSize', 14);
    else
        % Display message if no clusters
        text(0.5, 0.5, 'No valid clusters', 'HorizontalAlignment', 'center', 'FontSize', 14);
        axis off;
    end
    
            
    % Store the sequential cluster mapping
    interChannelCoherence.(conditionName).sequentialClusterMap = seqClusterMap;

    saveas(gcf,[saveDir '_' conditionName 'clusterMaps.png'])
end

% Save the updated structure with cluster information
save("data/interChannelCoherenceWithClusters.mat", "interChannelCoherence");

%% Now visualize CCEPs for each cluster in each condition

load('data/pooledData.mat')
alpha = calculateAlphaThreshold(pValue, 0.0001);
significant = (pValue < alpha) & (cohensD > 0);
load('code/dependencies/cingulateNames.mat');

set(0,'DefaultFigureRenderer','painters')

temp = [stimulatedRegion{:}];
interChannelCoherence.ACC.stimIDX = ismember(temp,leftACC) | ismember(temp,rightACC);
interChannelCoherence.MCC.stimIDX = ismember(temp,leftMCC) | ismember(temp,rightMCC);
interChannelCoherence.PCC.stimIDX = ismember(temp,leftPCC) | ismember(temp,rightPCC);

ccepColors = getColors('rainbow matrix');

length_samples = 3800;
% Sampling rate
fs = 2000; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

% Downsample to 150 points
downsampleFactor = ceil(length_samples / 150);
downsampledTimeVector = timeVector(1:downsampleFactor:end);

for condIdx = 1:length(conditions)
    conditionName = conditions{condIdx};
    
    curCondition = interChannelCoherence.(conditionName).stimIDX; %logical array for the stimulation conditioon

    % Get the cluster region names for this condition
    clusterRegionNames = interChannelCoherence.(conditionName).clusterRegionNames;
    
    % Find non-empty clusters
    nonEmptyClusters = find(~cellfun(@isempty, clusterRegionNames));
    figure('Position',[272         728        3039         510]);
    % Iterate through each non-empty cluster
    
    for clusterIdx = 1:length(nonEmptyClusters)

        subplot(1,length(nonEmptyClusters),clusterIdx)

        clusterNum = nonEmptyClusters(clusterIdx);
        regions = clusterRegionNames{clusterNum};
        
        findRegions = contains([electrodeRegionLabel{:}],regions);
        curIDX = significant & curCondition & findRegions;

        curCCEPs = CCEPs(:,curIDX)'; %rotate, since data was stored as time x channel
        
        % Downsample CCEPs
        downsampledCCEPs = curCCEPs(:,1:downsampleFactor:end);
        
        currentColor = ccepColors(clusterIdx,:);


        for s = 1:size(downsampledCCEPs,1)
        
            plot(downsampledTimeVector,downsampledCCEPs(s,:),'linewidth',.75,'Color',[.8,.8,.8,.3])
            hold on
        end
            plot(downsampledTimeVector,nanmean(abs(downsampledCCEPs),1),'linewidth',2,'Color', currentColor)
            box off
            text(0.1, .9, ['# channels '  num2str(sum(curIDX))], 'Units', 'normalized');
    end

    saveas(gcf,[saveDir '_' conditionName 'ccepClusters.svg'])

end

close all

%% save cluster regions to data log:
clear saveResults
saveResults.ACCCluster1 = interChannelCoherence.ACC.clusterRegionNames{1,1};
saveResults.ACCCluster2 = interChannelCoherence.ACC.clusterRegionNames{3,1};
saveResults.ACCCluster3 = interChannelCoherence.ACC.clusterRegionNames{4,1};
saveResults.ACCCluster4 = interChannelCoherence.ACC.clusterRegionNames{5,1};
saveResults.ACCCluster5 = interChannelCoherence.ACC.clusterRegionNames{9,1};
saveResults.ACCCluster6 = interChannelCoherence.ACC.clusterRegionNames{10,1};
saveResults.ACCCluster7 = interChannelCoherence.ACC.clusterRegionNames{11,1};
saveResults.ACCCluster8 = interChannelCoherence.ACC.clusterRegionNames{13,1};

saveResults.MCCCluster2 = interChannelCoherence.MCC.clusterRegionNames{1,1};
saveResults.MCCCluster3 = interChannelCoherence.MCC.clusterRegionNames{5,1};
saveResults.MCCCluster4 = interChannelCoherence.MCC.clusterRegionNames{6,1};
saveResults.MCCCluster5 = interChannelCoherence.MCC.clusterRegionNames{8,1};
saveResults.MCCCluster6 = interChannelCoherence.MCC.clusterRegionNames{10,1};
saveResults.MCCCluster7 = interChannelCoherence.MCC.clusterRegionNames{16,1};
saveResults.MCCCluster8 = interChannelCoherence.MCC.clusterRegionNames{17,1};

saveResults.PCCCluster2 = interChannelCoherence.PCC.clusterRegionNames{1,1};
saveResults.PCCCluster3 = interChannelCoherence.PCC.clusterRegionNames{2,1};
saveResults.PCCCluster4 = interChannelCoherence.PCC.clusterRegionNames{3,1};
saveResults.PCCCluster5 = interChannelCoherence.PCC.clusterRegionNames{4,1};
saveResults.PCCCluster6 = interChannelCoherence.PCC.clusterRegionNames{5,1};
saveResults.PCCCluster7 = interChannelCoherence.PCC.clusterRegionNames{8,1};
saveResults.PCCCluster8 = interChannelCoherence.PCC.clusterRegionNames{11,1};


appendLog('Fig 4-regions in each cluster', 'hierarchical clustering, a list of regions within each cluster for each region', saveResults)

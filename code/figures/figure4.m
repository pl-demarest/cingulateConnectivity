close all
clear
addpath(genpath(cd))
load("data/interChannelCoherenceSignificant.mat", "interChannelCoherence")

interChannelCoherence = rmfield(interChannelCoherence,'regions');

%initialize colors
aColor = getColors('lush lilac');
mColor = getColors('celadon porcelain');
pColor = getColors('lago blue');

%
load('code/dependencies/templateBrain.mat');
load('code/dependencies/listHip.mat');
load('code/dependencies/listAmyg.mat');
regionSort = readtable('code/dependencies/regionCategories.xlsx');
hipAmyg = [listAmyg,listHip];
brainFieldnames = fieldnames(templateBrain.regions);

%%

% Script: hierarchicalClusteringAnalysis.m
% This script performs hierarchical clustering on the taskCoherence matrix
% for each stimulation condition stored in the interChannelCoherence structure.
% It also visualizes the corresponding correlation matrix.
%
% Each field (e.g., 'ACC', 'MCC', 'PCC') in interChannelCoherence should contain:
%   - taskCoherence: an upper-triangular correlation matrix with a diagonal.
%   - baselineCoherence: (unused here)
%   - pValue: significance values for comparisons.
%   - labels: a cell array with channel labels.
%
% Note: This script assumes that you have the Statistics and Machine Learning Toolbox.

% Get the condition names from the structure fields
conditions = fieldnames(interChannelCoherence);

% Set distance threshold for clustering

for i = 1:length(conditions)
    conditionName = conditions{i};
    
    % Extract the taskCoherence matrix for the current condition
    tc = interChannelCoherence.(conditionName).taskCoherence;
    
    % Get p-values matrix
    pValues = interChannelCoherence.(conditionName).pValue;
    
    % Get channel labels
    labels = interChannelCoherence.(conditionName).labels;
    
    % Identify channels that contain only NaN values or only non-significant p-values
    % For each row/column, check if all values are NaN or non-significant (excluding the diagonal)
    validChannels = false(1, size(tc, 1));
    
    % Define significance threshold
    alpha = 0.05;
    
    for j = 1:size(tc, 1)
        % Create logical mask for non-diagonal elements
        mask = true(1, size(tc, 1));
        mask(j) = false; % Exclude diagonal
        
        % Check row/column for NaN values
        row_values = tc(j, :);
        col_values = tc(:, j)';
        row_has_values = ~all(isnan(row_values(mask)));
        col_has_values = ~all(isnan(col_values(mask)));
        
        % Check row/column for significant p-values
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
    
    % Skip processing if there are too few valid channels
    if sum(validChannels) < 2
        fprintf('Condition %s has too few valid channels (%d). Skipping.\n', ...
                conditionName, sum(validChannels));
        continue;
    end
    
    % Replace remaining NaN values with 0
    tc_filtered(isnan(tc_filtered)) = 0;

    %replace non-significant values with 0
    tc_filtered(p_filtered >= 0.001) = 0;

    % Since tc is an upper triangular matrix with a diagonal,
    % symmetrize it by copying the upper triangle to the lower triangle.
    tc_sym = tc_filtered + tc_filtered' - diag(diag(tc_filtered));
    
    % Convert the correlation matrix to a distance matrix.
    % Here we use d = 1 - correlation.
    D = 1 - tc_sym;
    
    % Ensure the diagonal of the distance matrix is zero.
    D(1:size(D,1)+1:end) = 0;
    
    % Convert the distance matrix to a vector form required by linkage.
    distVec = squareform(D);
    
    % Perform hierarchical clustering using average linkage.
    Z = linkage(distVec, 'average');
    
    % Create a figure with three subplots: original correlation matrix, dendrogram, and reordered matrix
    figure('Name', ['Condition: ', conditionName, ' (', num2str(sum(validChannels)), '/', num2str(length(validChannels)), ' valid channels)'], ...
           'NumberTitle', 'off', 'Position', [100, 100, 1500, 600]);
    
    % Get the cluster-based ordering
    % First plot the dendrogram invisibly to get the leaf ordering
    hFig = figure('Visible', 'off');
    [~, ~, outperm] = dendrogram(Z, 0);
    close(hFig);
    
    % outperm contains the order of leaves (most closely related regions)
    
    % Subplot 1: Visualize the original symmetrized correlation matrix using a heatmap.
    subplot(2,2,1);
    
    % Create masked correlation matrix for visualization
    mask = (tc_sym == 0);
    tc_masked = tc_sym;
    
    % Find min and max of non-zero correlations
    nonZeroCorr = tc_sym(~mask);
    if ~isempty(nonZeroCorr)
        minCorr = min(nonZeroCorr);
        maxCorr = max(nonZeroCorr);
    else
        minCorr = 0;
        maxCorr = 1;
    end
    
    % Create custom colormap with grey for masked values
    baseMap = getColors('white muted brick gradient');
    customMap = [0.8 0.8 0.8; baseMap];  % Add grey at the start for masked values
    
    % Scale non-zero values to range [1/size(customMap,1), 1]
    % Zero values will be mapped to index 1 (grey)
    tc_masked(~mask) = (tc_sym(~mask) - minCorr) / (maxCorr - minCorr) * (1 - 2/size(customMap,1)) + 2/size(customMap,1);
    tc_masked(mask) = 1/size(customMap,1);  % Map zeros to grey
    
    % Plot the masked correlation matrix
    imagesc(tc_masked);
    colormap(gca, customMap);
    colorbar;
    title(['Original Correlation Matrix - ', conditionName]);
    xlabel('Channel');
    ylabel('Channel');
    ax1 = gca;
    set(ax1, 'XTick', 1:length(labels_filtered), 'XTickLabel', labels_filtered, ...
             'YTick', 1:length(labels_filtered), 'YTickLabel', labels_filtered);
    % Disable TeX interpreter to prevent subscripting from underscores
    set(ax1, 'TickLabelInterpreter', 'none');
    xtickangle(45);  % Rotate x-axis labels for clarity
    
    % Add colorbar label with actual correlation range
    c = colorbar;
    ylabel(c, sprintf('Correlation\n[%.2f, %.2f]', minCorr, maxCorr));
    
    % Subplot 2: Plot the dendrogram from hierarchical clustering.
    subplot(2,2,2);
    h = dendrogram(Z, 0, 'Labels', labels_filtered);
    title(['Hierarchical Clustering - ', conditionName]);
    xlabel('Channel');
    ylabel('Distance (1 - correlation)');
    ax2 = gca;
    % Disable TeX interpreter for dendrogram labels
    set(ax2, 'TickLabelInterpreter', 'none');

    [distanceThreshold, thresholdMetrics.(conditionName)] = findOptimalClusterThreshold(Z,[],'similarity');
    
    % Add horizontal line at distance threshold
    hold on;
    plot(get(ax2, 'XLim'), [distanceThreshold, distanceThreshold], 'r--', 'LineWidth', 2);
    hold off;
    
    % Get clusters at the specified threshold
    clusters = cluster(Z, 'Cutoff', distanceThreshold, 'Criterion', 'distance');
    numClusters = max(clusters);
    
    % Subplot 3: Visualize the reordered correlation matrix based on cluster relationships
    subplot(2,2,3);
    % Reorder the correlation matrix based on the clustering results
    tc_reordered = tc_sym(outperm, outperm);
    reordered_labels = labels_filtered(outperm);
    
    % Reorder clusters based on the outperm order
    reordered_clusters = clusters(outperm);
    
    % Create a mapping for left-to-right cluster ordering
    % First, get the first occurrence of each cluster in left-to-right order
    [unique_clusters, first_indices] = unique(reordered_clusters, 'stable');
    
    % Create a mapping from original cluster numbers to left-to-right order
    cluster_map = zeros(max(clusters), 1);
    for c = 1:length(unique_clusters)
        cluster_map(unique_clusters(c)) = c;
    end
    
    % Remap cluster numbers to left-to-right order
    reordered_clusters_mapped = cluster_map(reordered_clusters);
    
    % Create masked version of reordered matrix
    mask_reordered = (tc_reordered == 0);
    tc_reordered_masked = tc_reordered;
    
    % Scale non-zero values as before
    tc_reordered_masked(~mask_reordered) = (tc_reordered(~mask_reordered) - minCorr) / (maxCorr - minCorr) * (1 - 2/size(customMap,1)) + 2/size(customMap,1);
    tc_reordered_masked(mask_reordered) = 1/size(customMap,1);  % Map zeros to grey
    
    % Plot the masked reordered correlation matrix
    imagesc(tc_reordered_masked);
    colormap(gca, customMap);
    colorbar;
    title(['Cluster-ordered Correlation Matrix - ', conditionName]);
    xlabel('Channel');
    ylabel('Channel');
    ax3 = gca;
    set(ax3, 'XTick', 1:length(reordered_labels), 'XTickLabel', reordered_labels, ...
             'YTick', 1:length(reordered_labels), 'YTickLabel', reordered_labels);
    % Disable TeX interpreter to prevent subscripting from underscores
    set(ax3, 'TickLabelInterpreter', 'none');
    xtickangle(45);  % Rotate x-axis labels for clarity
    
    % Add colorbar label with actual correlation range
    c = colorbar;
    ylabel(c, sprintf('Correlation\n[%.2f, %.2f]', minCorr, maxCorr));
    
    % Add cluster outlines
    hold on;
    % Find boundaries between clusters in the reordered matrix
    clusterBoundaries = find(diff(reordered_clusters_mapped) ~= 0);
    
    % Draw lines to show cluster boundaries
    for b = 1:length(clusterBoundaries)
        % Draw horizontal line
        line([0.5, length(reordered_clusters)+0.5], [clusterBoundaries(b)+0.5, clusterBoundaries(b)+0.5], ...
             'Color', 'k', 'LineWidth', 2);
        % Draw vertical line
        line([clusterBoundaries(b)+0.5, clusterBoundaries(b)+0.5], [0.5, length(reordered_clusters)+0.5], ...
             'Color', 'k', 'LineWidth', 2);
    end
    
    % Add text indicating cluster numbers
    clusterStartIndices = [1; clusterBoundaries+1];
    clusterEndIndices = [clusterBoundaries; length(reordered_clusters)];
    
    for c = 1:numClusters
        % Find indices for this cluster in the remapped numbering
        clusterIndices = find(reordered_clusters_mapped == c);
        if ~isempty(clusterIndices)
            % Calculate center of cluster
            centerIdx = mean(clusterIndices);
            % Add text annotation
            text(centerIdx, centerIdx, ['C', num2str(c)], 'Color', 'k', 'FontWeight', 'bold', ...
                 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1 0.7]);
        end
    end
    hold off;
    
    % Subplot 4: Visualize Shannon entropy and natural break scores across thresholds
    subplot(2,2,4);
    
    % Extract threshold values and metrics from thresholdMetrics
    thresholdValues = [thresholdMetrics.(conditionName).threshold];
    entropyValues = [thresholdMetrics.(conditionName).shannonEntropy];
    
    % Get the heights from the linkage matrix
    heights = Z(:,3);
    
    % Calculate merge density at different heights
    numBins = 20;
    [mergeDensity, binEdges] = histcounts(heights, numBins);
    binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;
    
    % Normalize merge density
    normMergeDensity = mergeDensity / max(mergeDensity);
    
    % Find local minima in merge density (potential natural breaks)
    localMinima = find(diff(sign(diff([Inf, normMergeDensity, Inf]))) > 0);
    naturalBreakPoints = binCenters(localMinima);
    
    % Create two y-axes for different metrics
    yyaxis left
    % Plot Shannon entropy vs threshold
    plot(thresholdValues, entropyValues, '-o', 'LineWidth', 2, 'Color', [0.2 0.4 0.8], 'MarkerFaceColor', [0.2 0.4 0.8]);
    ylabel('Shannon Entropy', 'Color', [0.2 0.4 0.8]);
    
    % Add marker for the selected threshold (entropy)
    hold on;
    selectedThresholdIdx = find(abs(thresholdValues - distanceThreshold) < 1e-6, 1);
    if ~isempty(selectedThresholdIdx)
        plot(distanceThreshold, entropyValues(selectedThresholdIdx), 'o', ...
             'MarkerSize', 10, 'LineWidth', 2, 'Color', [0.2 0.4 0.8]);
    end
    hold off;
    
    % Configure right y-axis for merge density
    yyaxis right
    % Plot merge density
    plot(binCenters, normMergeDensity, '-', 'LineWidth', 2, 'Color', [0.3 0.7 0.3]);
    hold on;
    
    % Plot natural break points
    for i = 1:length(naturalBreakPoints)
        plot([naturalBreakPoints(i), naturalBreakPoints(i)], [0, normMergeDensity(localMinima(i))], '--', 'Color', [0.7 0.3 0.3], 'LineWidth', 1);
    end
    
    % Add vertical line at selected threshold
    ylimits = [0 1];  % Set y-axis limits explicitly to 0-1 for normalized density
    ylim(ylimits);
    line([distanceThreshold, distanceThreshold], ylimits, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1.5);
    
    % Style the right y-axis to match merge density color
    ax = gca;
    ax.YAxis(2).Color = [0.3 0.7 0.3];
    ylabel('Normalized Merge Density', 'Color', [0.3 0.7 0.3]);
    
    % Ensure y-axis ticks are at reasonable intervals
    ax.YAxis(2).TickValues = 0:0.2:1;
    
    hold off;
    
    % Add labels and title
    xlabel('Distance Threshold');
    title('Cluster Metrics and Merge Density');
    
    % Clean up appearance
    set(gca, 'Box', 'off');
    
    % Add legend with more descriptive labels
    legend({'Shannon Entropy', 'Merge Density', 'Natural Break Points'}, ...
           'Location', 'best', 'Box', 'off');
    
    % Add overall colormap to make colors consistent across all plots
    %colormap(getColors('modern blue to modern orange gradient'));
    colormap(getColors('white muted brick gradient'))
    clim([0 1])
    
    % Add a figure description showing number of clusters
    sgtitle([conditionName, ': ', num2str(numClusters), ' clusters at threshold ', ...
             num2str(distanceThreshold)], 'FontWeight', 'bold');
             
    % Store cluster assignments for each channel/region
    % First, create a mapping from filtered labels back to original positions
    labelMap = containers.Map(labels_filtered, find(validChannels));
    
    % Initialize cluster assignments for all regions in templateBrain
    regionClusterLabels = zeros(length(templateBrain.regionList), 1);
    
    % Map clusters back to original regions, using the remapped (left-to-right) cluster numbering
    % Create a mapping from original cluster numbers to the reordered left-to-right cluster numbers
    % This is the inverse of cluster_map we created earlier
    inverse_cluster_map = zeros(max(clusters), 1);
    for c = 1:length(unique_clusters)
        inverse_cluster_map(unique_clusters(c)) = c;
    end
    
    for j = 1:length(labels_filtered)
        % Find the original index of this channel
        origIdx = labelMap(labels_filtered{j});
        
        % Find which region in templateBrain.regionList this corresponds to
        regionIdx = find(strcmp(templateBrain.regionList, labels{origIdx}));
        
        if ~isempty(regionIdx)
            % Assign the remapped cluster label (left-to-right ordering)
            originalCluster = clusters(j);
            remappedCluster = inverse_cluster_map(originalCluster);
            regionClusterLabels(regionIdx) = remappedCluster;
        end
    end
    
    % Count regions in each cluster
    clusterCounts = zeros(numClusters, 1);
    for c = 1:numClusters
        clusterCounts(c) = sum(regionClusterLabels == c);
    end
    
    % Find small clusters (2 or fewer regions)
    smallClusters = find(clusterCounts <= 2);
    
    % Set small cluster regions to cluster 0
    for sc = 1:length(smallClusters)
        smallClusterIdx = smallClusters(sc);
        regionClusterLabels(regionClusterLabels == smallClusterIdx) = 0;
    end
    
    % Display clusters with their regions
    fprintf('\nCondition: %s\n', conditionName);
    fprintf('Number of clusters: %d\n', numClusters);
    
    % Report small clusters that were set to 0
    if ~isempty(smallClusters)
        fprintf('Small clusters (≤2 regions) set to 0: %s\n', ...
                num2str(smallClusters'));
    end
    
    % Print regions in each cluster
    validClusters = setdiff(unique(regionClusterLabels), 0);
    for c = 1:length(validClusters)
        clusterIdx = validClusters(c);
        clusterRegions = templateBrain.regionList(regionClusterLabels == clusterIdx);
        fprintf('Cluster %d: %s\n', clusterIdx, strjoin(clusterRegions, ', '));
    end
    
    % Store the cluster assignments in the interChannelCoherence structure
    interChannelCoherence.(conditionName).regionClusterLabels = regionClusterLabels;
    interChannelCoherence.(conditionName).clusterRegionNames = cell(max(regionClusterLabels), 1);
    
    % Store the names of regions in each cluster
    for c = 1:max(regionClusterLabels)
        interChannelCoherence.(conditionName).clusterRegionNames{c} = ...
            templateBrain.regionList(regionClusterLabels == c);
    end
    
    % Also store the inverse mapping for reference
    interChannelCoherence.(conditionName).clusterMapping = inverse_cluster_map;
end

%% next, label brain regions based on the clusters and specified threshold
% initialize brain structures
% generate brain without a hippocampus
hipAmygBool = contains(templateBrain.regionList,hipAmyg);%hip/amyg fieldnames already exist in a separate .mat file
brainFieldnames2 = brainFieldnames(~hipAmygBool);

for i = 1:length(brainFieldnames2)

    templateBrain2.regions.(brainFieldnames2{i}) = templateBrain.regions.(brainFieldnames2{i});

end

%for using a right brain model, show the midsection and remove regions from
%sagittal view
templateBrainRight = getOneSide(templateBrain2,'right');
templateBrainRight = isolatePortionOfModel(templateBrainRight,'x','less',27);

templateBrainLeft = getOneSide(templateBrain,'left');
templateBrainLeft = isolatePortionOfModel(templateBrainLeft,'x','less',-15);

% generate model of the hippocampus 
hipAmygFieldnames = brainFieldnames(hipAmygBool);

%make new struct for hipp and amyg
for i = 1:length(hipAmygFieldnames)

    hipAmygTemplate.regions.(hipAmygFieldnames{i}) = templateBrain.regions.(hipAmygFieldnames{i});

end
hipAmygTemplate = getOneSide(hipAmygTemplate,'left');

insulaBool = contains(templateBrain.regionList,regionSort{strcmp(regionSort{:,3},'Insula'),1}); %extract insula fieldnames from table
insulaFieldnames = brainFieldnames(insulaBool); %ensure that fieldnames are ordered accordingly 
%index insula subregions and generate an insula struct
for i = 1:length(insulaFieldnames)
   insulaTemplate.regions.(insulaFieldnames{i}) = templateBrain.regions.(insulaFieldnames{i});
end
insulaTemplateLeft = getOneSide(insulaTemplate,'left');

%% Visualize clusters from hierarchical analysis on 3D brain models
% Create a custom colormap for clusters
clusterColormap = [
    0.8, 0.8, 0.8;  % Cluster 0 (small clusters) - light gray
    0.9, 0.1, 0.1;  % Cluster 1 - red
    0.1, 0.5, 0.9;  % Cluster 2 - blue
    0.1, 0.8, 0.2;  % Cluster 3 - green
    0.9, 0.6, 0.1;  % Cluster 4 - orange
    0.8, 0.2, 0.8;  % Cluster 5 - purple
    0.2, 0.7, 0.7;  % Cluster 6 - teal
    0.7, 0.7, 0.2;  % Cluster 7 - olive
    0.5, 0.2, 0.5;  % Cluster 8 - dark purple
    0.9, 0.4, 0.6;  % Cluster 9 - pink
    0.4, 0.9, 0.6;  % Cluster 10 - mint
];
% Add more colors if needed for more clusters

% Process each condition
conditions = fieldnames(interChannelCoherence);

for condIdx = 1:length(conditions)
    conditionName = conditions{condIdx};
    
    % Skip if the condition doesn't have cluster information
    if ~isfield(interChannelCoherence.(conditionName), 'regionClusterLabels')
        continue;
    end
    
    % Get cluster labels for this condition
    regionClusterLabels = interChannelCoherence.(conditionName).regionClusterLabels;
    
    % Create a figure for this condition with 5 subplots (for different brain views)
    figure('Name', ['Clusters - ' conditionName], ...
           'Position', [281, 32, 3060, 1260]);
    
    % 1. Assign colors based on cluster labels
    regionColors = zeros(length(templateBrain.regionList), 3);
    
    % Add 1 to all labels to use as indices (cluster 0 becomes 1, etc.)
    % This ensures that cluster 0 (small clusters) gets the right color from the colormap
    colorIndices = regionClusterLabels + 1;
    
    % Assign colors based on cluster labels
    for i = 1:length(colorIndices)
        % Make sure we don't exceed colormap size
        colorIdx = min(colorIndices(i), size(clusterColormap, 1));
        regionColors(i, :) = clusterColormap(colorIdx, :);
    end
    
    % 2. Left Cortex View
    subplot(2, 3, 1);
    [surfaceLeft] = plotProjectedRegionsOnly(templateBrainLeft, regionColors);
    view([270, 0]);
    title([conditionName, ' - Left Lateral View']);
    
    % 3. Right Cortex View
    subplot(2, 3, 2);
    % Extract colors for regions in right hemisphere model
    rightColors = regionColors(~hipAmygBool, :);
    [surfaceRight] = plotProjectedRegionsOnly(templateBrainRight, rightColors);
    view([270, 0]);
    title([conditionName, ' - Right Lateral View']);
    
    % 4. Insula View
    subplot(2, 3, 3);
    insulaColors = regionColors(insulaBool, :);
    [surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft, insulaColors);
    view([270, 0]);
    title([conditionName, ' - Insula View']);
    
    % 5. Hippocampus/Amygdala View 1
    subplot(2, 3, 4);
    hipAmygColors = regionColors(hipAmygBool, :);
    [surfaceHA1] = plotProjectedRegionsOnly(hipAmygTemplate, hipAmygColors);
    view([-176.4, -90.0]);
    title([conditionName, ' - Hippocampus/Amygdala View 1']);
    
    % 6. Hippocampus/Amygdala View 2
    subplot(2, 3, 5);
    [surfaceHA2] = plotProjectedRegionsOnly(hipAmygTemplate, hipAmygColors);
    view([-180.8, 73.9]);
    title([conditionName, ' - Hippocampus/Amygdala View 2']);
    
    % 7. Add a legend for the clusters
    subplot(2, 3, 6);
    axis off;
    
    % Create a custom legend
    unique_clusters = unique(regionClusterLabels);
    numUniqueClusters = length(unique_clusters);
    
    for i = 1:numUniqueClusters
        cluster = unique_clusters(i);
        colorIdx = cluster + 1; % Adjust index for colormap
        
        % Make sure we don't exceed colormap size
        colorIdx = min(colorIdx, size(clusterColormap, 1));
        
        % Create a colored rectangle for this cluster
        x_pos = 0.1;
        y_pos = 0.9 - (i-1) * 0.1;
        
        % Calculate cluster summary
        if cluster == 0
            clusterName = 'Small clusters (≤2 regions)';
        else
            % Get regions in this cluster
            clusterRegions = interChannelCoherence.(conditionName).clusterRegionNames{cluster};
            numRegions = length(clusterRegions);
            clusterName = ['Cluster ' num2str(cluster) ' (' num2str(numRegions) ' regions)'];
        end
        
        rectangle('Position', [x_pos, y_pos, 0.1, 0.05], ...
                  'FaceColor', clusterColormap(colorIdx, :), ...
                  'EdgeColor', 'k');
        
        text(x_pos + 0.15, y_pos + 0.025, clusterName, ...
             'VerticalAlignment', 'middle');
        
        % Add regions list if not small cluster
        if cluster > 0
            % Get regions list
            regionsList = interChannelCoherence.(conditionName).clusterRegionNames{cluster};
            
            % Format regions list with max 3 regions per line
            regionsText = '';
            for r = 1:length(regionsList)
                regionsText = [regionsText, regionsList{r}];
                
                if r < length(regionsList)
                    if mod(r, 3) == 0
                        regionsText = [regionsText, ',\n'];
                    else
                        regionsText = [regionsText, ', '];
                    end
                end
            end
            
            % Add the regions text below the cluster name
            text(x_pos + 0.15, y_pos - 0.02, regionsText, ...
                 'VerticalAlignment', 'top', ...
                 'FontSize', 8, ...
                 'Interpreter', 'none');
        end
    end
    
    % Add overall title
    sgtitle([conditionName, ' Cluster Analysis (threshold = ', num2str(distanceThreshold), ')'], ...
            'FontWeight', 'bold', 'FontSize', 16);
end

% Save the updated structure with cluster information
save("data/interChannelCoherenceWithClusters.mat", "interChannelCoherence");




close all
clear
addpath(genpath(cd))
load("data/interChannelCoherenceSignificant.mat", "interChannelCoherence")

interChannelCoherence = rmfield(interChannelCoherence,'regions');

%initialize colors
aColor = getColors('lush lilac');
mColor = getColors('celadon porcelain');
pColor = getColors('lago blue');

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
distanceThreshold = 0.6; % Adjust this value as needed

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
           'NumberTitle', 'off', 'Position', [100, 100, 1200, 400]);
    
    % Get the cluster-based ordering
    % First plot the dendrogram invisibly to get the leaf ordering
    hFig = figure('Visible', 'off');
    [~, ~, outperm] = dendrogram(Z, 0);
    close(hFig);
    
    % outperm contains the order of leaves (most closely related regions)
    
    % Subplot 1: Visualize the original symmetrized correlation matrix using a heatmap.
    subplot(1,3,1);
    imagesc(tc_sym);
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
    clim([0 1])
    
    % Subplot 2: Plot the dendrogram from hierarchical clustering.
    subplot(1,3,2);
    h = dendrogram(Z, 0, 'Labels', labels_filtered);
    title(['Hierarchical Clustering - ', conditionName]);
    xlabel('Channel');
    ylabel('Distance (1 - correlation)');
    ax2 = gca;
    % Disable TeX interpreter for dendrogram labels
    set(ax2, 'TickLabelInterpreter', 'none');
    
    % Add horizontal line at distance threshold
    hold on;
    plot(get(ax2, 'XLim'), [distanceThreshold, distanceThreshold], 'r--', 'LineWidth', 2);
    hold off;
    
    % Get clusters at the specified threshold
    clusters = cluster(Z, 'Cutoff', distanceThreshold, 'Criterion', 'distance');
    numClusters = max(clusters);
    
    % Subplot 3: Visualize the reordered correlation matrix based on cluster relationships
    subplot(1,3,3);
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
    
    imagesc(tc_reordered);
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
    
    % Add overall colormap to make colors consistent across all plots
    colormap(parula);
    clim([0 1])
    
    % Add a figure description showing number of clusters
    sgtitle([conditionName, ': ', num2str(numClusters), ' clusters at threshold ', ...
             num2str(distanceThreshold)], 'FontWeight', 'bold');
end

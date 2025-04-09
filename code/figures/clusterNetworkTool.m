close all
clear
addpath(genpath(cd))

% Load data with error handling
try
    data = load("data/interChannelCoherenceSignificant.mat");
    % Check if interChannelCoherence exists in the loaded data
    if ~isfield(data, 'interChannelCoherence')
        error('The loaded MAT file does not contain interChannelCoherence structure');
    end
    icc = data.interChannelCoherence;
    
    % Check for regions field and remove if necessary
    if isfield(icc, 'regions')
        icc = rmfield(icc, 'regions');
    end
    
    % Verify structure has expected fields
    conditions = fieldnames(icc);
    if isempty(conditions)
        error('No condition fields found in interChannelCoherence structure');
    end
    
    % Check first condition for required fields
    testCondition = conditions{1};
    requiredFields = {'taskCoherence', 'pValue', 'labels'};
    for i = 1:length(requiredFields)
        if ~isfield(icc.(testCondition), requiredFields{i})
            error(['Missing required field: ' requiredFields{i} ' in condition ' testCondition]);
        end
    end
catch ME
    errordlg(['Error loading data: ' ME.message], 'Data Loading Error');
    return
end

% Debug: Display structure info
disp('Loaded interChannelCoherence structure:');
disp(['Number of conditions: ' num2str(length(conditions))]);
for i = 1:length(conditions)
    disp(['  Condition: ' conditions{i}]);
    condFields = fieldnames(icc.(conditions{i}));
    for j = 1:length(condFields)
        disp(['    Field: ' condFields{j}]);
    end
end

%initialize colors
aColor = getColors('lush lilac');
mColor = getColors('celadon porcelain');
pColor = getColors('lago blue');

% Define initial distance threshold
initialThreshold = 0.6;

% Initialize GUI figure
mainFig = figure('Name', 'Interactive Clustering Tool', 'NumberTitle', 'off', ...
    'Position', [100, 100, 1200, 700], 'Color', 'white');

% Store the data structure in the figure's application data
setappdata(mainFig, 'icc', icc);
setappdata(mainFig, 'conditions', conditions);

% Add condition selection dropdown
conditionPanel = uipanel(mainFig, 'Title', 'Condition Selection', ...
    'Position', [0.05, 0.85, 0.2, 0.1]);
conditionDropdown = uicontrol(conditionPanel, 'Style', 'popupmenu', ...
    'String', conditions, 'Position', [20, 10, 200, 25]);

% Add threshold slider
sliderPanel = uipanel(mainFig, 'Title', 'Distance Threshold', ...
    'Position', [0.3, 0.85, 0.55, 0.1]);
thresholdSlider = uicontrol(sliderPanel, 'Style', 'slider', ...
    'Min', 0.01, 'Max', 0.99, 'Value', initialThreshold, ...
    'Position', [20, 10, 550, 25]);
thresholdText = uicontrol(sliderPanel, 'Style', 'text', ...
    'String', ['Threshold: ', num2str(initialThreshold)], ...
    'Position', [580, 10, 100, 25]);

% Add significance threshold input
sigPanel = uipanel(mainFig, 'Title', 'Significance Level', ...
    'Position', [0.85, 0.85, 0.1, 0.1]);
sigEdit = uicontrol(sigPanel, 'Style', 'edit', ...
    'String', '0.05', 'Position', [20, 10, 80, 25]);

% Create axes for plots - modified to show only 2 plots
dendrogramAx = axes(mainFig, 'Position', [0.1, 0.45, 0.8, 0.35]);
reorderedMatAx = axes(mainFig, 'Position', [0.25, 0.05, 0.5, 0.35]);

% Info text area
infoText = uicontrol(mainFig, 'Style', 'text', ...
    'Position', [50, 10, 200, 80], ...
    'HorizontalAlignment', 'left');

% Store processed data and UI handles
setappdata(mainFig, 'appData', struct());
setappdata(mainFig, 'handles', struct(...
    'conditionDropdown', conditionDropdown, ...
    'thresholdSlider', thresholdSlider, ...
    'thresholdText', thresholdText, ...
    'sigEdit', sigEdit, ...
    'infoText', infoText, ...
    'dendrogramAx', dendrogramAx, ...
    'reorderedMatAx', reorderedMatAx));

% Function to process data and prepare for plotting
function processCondition(conditionName)
    try
        % Get the current figure and retrieve stored data and handles
        fig = gcf;
        icc = getappdata(fig, 'icc');
        handles = getappdata(fig, 'handles');
        
        % Extract the taskCoherence matrix for the current condition
        tc = icc.(conditionName).taskCoherence;
        
        % Get p-values matrix
        pValues = icc.(conditionName).pValue;
        
        % Get channel labels
        labels = icc.(conditionName).labels;
        
        % Validate data dimensions
        if size(tc, 1) ~= size(pValues, 1) || size(tc, 2) ~= size(pValues, 2)
            error('Mismatch between taskCoherence and pValue matrix dimensions');
        end
        
        if length(labels) ~= size(tc, 1)
            error('Mismatch between labels length and matrix dimensions');
        end
        
        % Display data dimensions for debugging
        disp(['Processing condition: ' conditionName]);
        disp(['  Matrix dimensions: ' num2str(size(tc, 1)) 'x' num2str(size(tc, 2))]);
        disp(['  Number of labels: ' num2str(length(labels))]);
        
        % Identify channels that contain only NaN values or only non-significant p-values
        validChannels = false(1, size(tc, 1));
        
        % Get significance threshold from UI
        alpha = str2double(get(handles.sigEdit, 'String'));
        
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
            set(handles.infoText, 'String', sprintf('Condition %s has too few valid channels (%d).\nTry adjusting significance threshold.', ...
                    conditionName, sum(validChannels)));
            return;
        end
        
        % Replace remaining NaN values with 0
        tc_filtered(isnan(tc_filtered)) = 0;
    
        % Since tc is an upper triangular matrix with a diagonal,
        % symmetrize it by copying the upper triangle to the lower triangle.
        tc_sym = tc_filtered + tc_filtered' - diag(diag(tc_filtered));
        
        % Convert the correlation matrix to a distance matrix.
        D = 1 - tc_sym;
        
        % Ensure the diagonal of the distance matrix is zero.
        D(1:size(D,1)+1:end) = 0;
        
        % Convert the distance matrix to a vector form required by linkage.
        distVec = squareform(D);
        
        % Perform hierarchical clustering using average linkage.
        Z = linkage(distVec, 'average');
        
        % Get the cluster-based ordering
        % Create a temporary invisible figure for dendrogram calculation
        temp_fig = figure('HandleVisibility', 'off', 'Visible', 'off');
        [~, ~, outperm] = dendrogram(Z, 0);
        close(temp_fig);
        
        % Store the processed data
        appData = struct();
        appData.tc_sym = tc_sym;
        appData.Z = Z;
        appData.labels_filtered = labels_filtered;
        appData.outperm = outperm;
        appData.numChannels = length(labels_filtered);
        setappdata(fig, 'appData', appData);
        
        % Update info text
        set(handles.infoText, 'String', sprintf('Condition: %s\nValid channels: %d/%d', ...
            conditionName, sum(validChannels), length(validChannels)));
            
        % Call updatePlots to refresh the display
        updatePlots(get(handles.thresholdSlider, 'Value'));
    catch ME
        % Display error in the info text
        fig = gcf;
        handles = getappdata(fig, 'handles');
        set(handles.infoText, 'String', sprintf('Error processing %s:\n%s', conditionName, ME.message));
        disp(['ERROR: ' ME.message]);
        disp(ME.stack(1));
    end
end

% Function to update plots based on threshold value
function updatePlots(threshold)
    try
        % Get the current figure and retrieve stored data and handles
        fig = gcf;
        appData = getappdata(fig, 'appData');
        handles = getappdata(fig, 'handles');
        
        if ~isfield(appData, 'Z') || ~isfield(appData, 'tc_sym')
            set(handles.infoText, 'String', 'No data available for plotting');
            return;
        end
        
        % Get clusters at the specified threshold
        clusters = cluster(appData.Z, 'Cutoff', threshold, 'Criterion', 'distance');
        numClusters = max(clusters);
        
        % Clear previous plots
        cla(handles.dendrogramAx);
        cla(handles.reorderedMatAx);
        
        % Plot 1: Dendrogram with threshold line
        axes(handles.dendrogramAx);
        dendrogram(appData.Z, 0, 'Labels', appData.labels_filtered);
        title('Hierarchical Clustering');
        xlabel('Channel');
        ylabel('Distance (1 - correlation)');
        set(gca, 'TickLabelInterpreter', 'none');
        
        % Add threshold line
        hold on;
        plot(get(gca, 'XLim'), [threshold, threshold], 'r--', 'LineWidth', 2);
        hold off;
        
        % Plot 2: Reordered matrix with cluster boundaries
        axes(handles.reorderedMatAx);
        
        % Reorder the correlation matrix and clusters
        tc_reordered = appData.tc_sym(appData.outperm, appData.outperm);
        reordered_labels = appData.labels_filtered(appData.outperm);
        reordered_clusters = clusters(appData.outperm);
        
        % Create a mapping for left-to-right cluster ordering
        % First, get the first occurrence of each cluster in left-to-right order
        [unique_clusters, first_indices] = unique(reordered_clusters, 'stable');
        
        % Create a mapping from original cluster numbers to left-to-right order
        cluster_map = zeros(max(clusters), 1);
        for i = 1:length(unique_clusters)
            cluster_map(unique_clusters(i)) = i;
        end
        
        % Remap cluster numbers to left-to-right order
        reordered_clusters_mapped = cluster_map(reordered_clusters);
        
        imagesc(tc_reordered);
        colorbar;
        title(['Clustered Matrix: ', num2str(numClusters), ' clusters']);
        xlabel('Channel');
        ylabel('Channel');
        set(gca, 'XTick', 1:appData.numChannels, 'XTickLabel', reordered_labels, ...
            'YTick', 1:appData.numChannels, 'YTickLabel', reordered_labels);
        set(gca, 'TickLabelInterpreter', 'none');
        xtickangle(45);
        clim([0 1]);
        
        % Add cluster outlines
        hold on;
        % Find boundaries between clusters in the reordered matrix
        clusterBoundaries = find(diff(reordered_clusters_mapped) ~= 0);
        
        % Draw boundaries
        for b = 1:length(clusterBoundaries)
            % Draw horizontal line
            line([0.5, appData.numChannels+0.5], [clusterBoundaries(b)+0.5, clusterBoundaries(b)+0.5], ...
                 'Color', 'k', 'LineWidth', 2);
            % Draw vertical line
            line([clusterBoundaries(b)+0.5, clusterBoundaries(b)+0.5], [0.5, appData.numChannels+0.5], ...
                 'Color', 'k', 'LineWidth', 2);
        end
        
        % Add text indicating cluster numbers
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
    catch ME
        % Get error message display handle
        fig = gcf;
        handles = getappdata(fig, 'handles');
        set(handles.infoText, 'String', sprintf('Error in plotting:\n%s', ME.message));
        disp(['ERROR in updatePlots: ' ME.message]);
    end
end

% Callback for condition change
function conditionCallback(~, ~)
    fig = gcf;
    handles = getappdata(fig, 'handles');
    conditions = getappdata(fig, 'conditions');
    selectedIdx = get(handles.conditionDropdown, 'Value');
    conditionName = conditions{selectedIdx};
    processCondition(conditionName);
end

% Callback for slider change
function sliderCallback(~, ~)
    fig = gcf;
    handles = getappdata(fig, 'handles');
    threshold = get(handles.thresholdSlider, 'Value');
    set(handles.thresholdText, 'String', ['Threshold: ', num2str(threshold, '%.2f')]);
    updatePlots(threshold);
end

% Callback for significance threshold change
function sigCallback(~, ~)
    try
        fig = gcf;
        handles = getappdata(fig, 'handles');
        alpha = str2double(get(handles.sigEdit, 'String'));
        if isnan(alpha) || alpha <= 0 || alpha >= 1
            set(handles.sigEdit, 'String', '0.05');
        end
        conditions = getappdata(fig, 'conditions');
        selectedIdx = get(handles.conditionDropdown, 'Value');
        conditionName = conditions{selectedIdx};
        processCondition(conditionName);
    catch ME
        fig = gcf;
        handles = getappdata(fig, 'handles');
        set(handles.sigEdit, 'String', '0.05');
        disp(['ERROR in sigCallback: ' ME.message]);
    end
end

% Set callbacks
set(conditionDropdown, 'Callback', @conditionCallback);
set(thresholdSlider, 'Callback', @sliderCallback);
set(sigEdit, 'Callback', @sigCallback);

% Initialize with first condition
try
    processCondition(conditions{1});
catch ME
    set(infoText, 'String', sprintf('Initialization error:\n%s', ME.message));
    disp(['ERROR during initialization: ' ME.message]);
end

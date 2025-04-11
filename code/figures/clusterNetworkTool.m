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

% Load 3D brain model data
try
    % Load templates and region lists
    load('code/dependencies/templateBrain.mat');
    load('code/dependencies/listHip.mat');
    load('code/dependencies/listAmyg.mat');
    regionSort = readtable('code/dependencies/regionCategories.xlsx');
    hipAmyg = [listAmyg,listHip];
    brainFieldnames = fieldnames(templateBrain.regions);
    
    % Process brain models
    % Generate brain without hippocampus
    hipAmygBool = contains(templateBrain.regionList,hipAmyg);
brainFieldnames2 = brainFieldnames(~hipAmygBool);

for i = 1:length(brainFieldnames2)

    templateBrain2.regions.(brainFieldnames2{i}) = templateBrain.regions.(brainFieldnames2{i});

end
    
    % Create right and left hemisphere models
    templateBrainRight = getOneSide(templateBrain2,'right');
    templateBrainRight = isolatePortionOfModel(templateBrainRight,'x','less',27);
    
    templateBrainLeft = getOneSide(templateBrain,'left');
    templateBrainLeft = isolatePortionOfModel(templateBrainLeft,'x','less',-15);
    
hipAmygBool = contains(templateBrain.regionList,hipAmyg);%hip/amyg fieldnames already exist in a separate .mat file
hipAmygFieldnames = brainFieldnames(hipAmygBool);

%make new struct for hipp and amyg
for i = 1:length(hipAmygFieldnames)

    hipAmygTemplate.regions.(hipAmygFieldnames{i}) = templateBrain.regions.(hipAmygFieldnames{i});

end
hipAmygTemplate = getOneSide(hipAmygTemplate,'left');

    
    % Create insula model
insulaBool = contains(templateBrain.regionList,regionSort{strcmp(regionSort{:,3},'Insula'),1}); %extract insula fieldnames from table
insulaFieldnames = brainFieldnames(insulaBool); %ensure that fieldnames are ordered accordingly 
%index insula subregions and generate an insula struct
for i = 1:length(insulaFieldnames)
   insulaTemplate.regions.(insulaFieldnames{i}) = templateBrain.regions.(insulaFieldnames{i});
end
insulaTemplateLeft = getOneSide(insulaTemplate,'left');
    % Store brain models in figure data
    brainModels = struct();
    brainModels.templateBrain = templateBrain;
    brainModels.templateBrainLeft = templateBrainLeft;
    brainModels.templateBrainRight = templateBrainRight;
    brainModels.hipAmygTemplate = hipAmygTemplate;
    brainModels.insulaTemplateLeft = insulaTemplateLeft;
    brainModels.hipAmygBool = hipAmygBool;
    brainModels.insulaBool = insulaBool;
    
catch ME
    warndlg(['Warning: Could not load brain models: ' ME.message], 'Brain Model Loading Warning');
    % Continue without 3D visualization
    brainModels = [];
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

% Define initial distance threshold
initialThreshold = 0.6;

% Initialize GUI figure - expanded for 3D visualization
mainFig = figure('Name', 'Interactive Clustering Tool', 'NumberTitle', 'off', ...
    'Position', [50, 50, 1500, 900], 'Color', 'white');

% Store the data structure in the figure's application data
setappdata(mainFig, 'icc', icc);
setappdata(mainFig, 'conditions', conditions);
setappdata(mainFig, 'brainModels', brainModels);
setappdata(mainFig, 'clusterColormap', clusterColormap);

% Add condition selection dropdown
conditionPanel = uipanel(mainFig, 'Title', 'Condition Selection', ...
    'Position', [0.02, 0.92, 0.15, 0.07]);
conditionDropdown = uicontrol(conditionPanel, 'Style', 'popupmenu', ...
    'String', conditions, 'Position', [10, 10, 200, 25]);

% Add threshold slider
sliderPanel = uipanel(mainFig, 'Title', 'Distance Threshold', ...
    'Position', [0.18, 0.92, 0.4, 0.07]);
thresholdSlider = uicontrol(sliderPanel, 'Style', 'slider', ...
    'Min', 0.01, 'Max', 0.99, 'Value', initialThreshold, ...
    'Position', [10, 10, 350, 25]);
thresholdText = uicontrol(sliderPanel, 'Style', 'text', ...
    'String', ['Threshold: ', num2str(initialThreshold, '%.2f')], ...
    'Position', [370, 10, 80, 25]);

% Add manual threshold entry field
thresholdEdit = uicontrol(sliderPanel, 'Style', 'edit', ...
    'String', num2str(initialThreshold, '%.2f'), ...
    'Position', [460, 10, 60, 25], ...
    'Tooltip', 'Enter threshold value (0.01-0.99)');

% Add significance threshold input
sigPanel = uipanel(mainFig, 'Title', 'Significance Level', ...
    'Position', [0.59, 0.92, 0.1, 0.07]);
sigEdit = uicontrol(sigPanel, 'Style', 'edit', ...
    'String', '0.05', 'Position', [20, 10, 80, 25]);

% Add toggle for masking small clusters
maskPanel = uipanel(mainFig, 'Title', 'Mask Small Clusters', ...
    'Position', [0.7, 0.92, 0.12, 0.07]);
maskToggle = uicontrol(maskPanel, 'Style', 'checkbox', ...
    'String', 'Mask ≤2 regions', 'Value', 0, ...
    'Position', [20, 10, 120, 25]);

% Add 3D view toggle
view3DPanel = uipanel(mainFig, 'Title', '3D View Options', ...
    'Position', [0.83, 0.92, 0.15, 0.07]);

% Initialize view3DToggle with the appropriate value and enabled state
if ~isempty(brainModels)
    view3DToggle = uicontrol(view3DPanel, 'Style', 'checkbox', ...
        'String', 'Show 3D Views', 'Value', 1, ...
        'Enable', 'on', 'Position', [20, 10, 100, 25]);
else
    view3DToggle = uicontrol(view3DPanel, 'Style', 'checkbox', ...
        'String', 'Show 3D Views', 'Value', 0, ...
        'Enable', 'off', 'Position', [20, 10, 100, 25]);
end

% Create tabbed panel for different views
viewTabs = uitabgroup(mainFig, 'Position', [0.02, 0.02, 0.96, 0.89]);

% Tab 1: Clustering Analysis
tab1 = uitab(viewTabs, 'Title', 'Clustering Analysis');

% Create axes for plots in tab 1
dendrogramAx = axes(tab1, 'Position', [0.1, 0.55, 0.8, 0.4]);
reorderedMatAx = axes(tab1, 'Position', [0.25, 0.05, 0.5, 0.4]);

% Info text area
infoText = uicontrol(tab1, 'Style', 'text', ...
    'Position', [50, 10, 200, 100], ...
    'HorizontalAlignment', 'left');

% Tab 2: 3D Brain Visualization (only if brain models loaded)
tab2 = [];
leftCortexAx = [];
rightCortexAx = [];
insulaAx = [];
hipAmygAx1 = [];
hipAmygAx2 = [];
legendPanel = [];

if ~isempty(brainModels)
    tab2 = uitab(viewTabs, 'Title', '3D Brain Views');
    
    % Create multiple axes for different brain views in tab 2
    leftCortexAx = axes(tab2, 'Position', [0.02, 0.53, 0.31, 0.45]);
    rightCortexAx = axes(tab2, 'Position', [0.35, 0.53, 0.31, 0.45]);
    insulaAx = axes(tab2, 'Position', [0.68, 0.53, 0.30, 0.45]);
    hipAmygAx1 = axes(tab2, 'Position', [0.18, 0.02, 0.31, 0.45]);
    hipAmygAx2 = axes(tab2, 'Position', [0.51, 0.02, 0.31, 0.45]);
    
    % Legend area
    legendPanel = uipanel(tab2, 'Title', 'Cluster Legend', ...
        'Position', [0.83, 0.02, 0.15, 0.45]);
end

% Store processed data and UI handles
setappdata(mainFig, 'appData', struct());
handles = struct(...
    'conditionDropdown', conditionDropdown, ...
    'thresholdSlider', thresholdSlider, ...
    'thresholdText', thresholdText, ...
    'thresholdEdit', thresholdEdit, ...
    'sigEdit', sigEdit, ...
    'infoText', infoText, ...
    'dendrogramAx', dendrogramAx, ...
    'reorderedMatAx', reorderedMatAx, ...
    'maskToggle', maskToggle, ...
    'view3DToggle', view3DToggle, ...
    'viewTabs', viewTabs, ...
    'tab1', tab1, ...
    'tab2', tab2);

% Add 3D view axes if brain models are available
if ~isempty(brainModels)
    handles.leftCortexAx = leftCortexAx;
    handles.rightCortexAx = rightCortexAx;
    handles.insulaAx = insulaAx;
    handles.hipAmygAx1 = hipAmygAx1;
    handles.hipAmygAx2 = hipAmygAx2;
    handles.legendPanel = legendPanel;
end

setappdata(mainFig, 'handles', handles);

% Callback for condition change
function conditionCallback(hObj, ~)
    % Disable the callback to prevent recursion issues
    set(hObj, 'Enable', 'off');
    
    try
        % First get the main figure and handles - use a try block to ensure we re-enable the control
        fig = ancestor(hObj, 'figure');
        if isempty(fig)
            fig = gcf;
        end
        
        % Get data from the figure
        handles = getappdata(fig, 'handles');
        conditions = getappdata(fig, 'conditions');
        
        % Get the selected condition index
        selectedIdx = get(handles.conditionDropdown, 'Value');
        if selectedIdx < 1 || selectedIdx > length(conditions)
            warning('Invalid condition index selected');
            return;
        end
        
        % Get the condition name
        conditionName = conditions{selectedIdx};
        
        % Process the condition - this updates appData in the figure
        try
            % Force figure into focus
            figure(fig);
            drawnow;
            
            % Process the condition
            processCondition(conditionName);
            
            % Make sure the figure is still on top
            figure(fig);
            drawnow;
            
            % Get the current threshold value
            threshold = get(handles.thresholdSlider, 'Value');
            
            % Force a plot update with the current threshold
            updatePlots(threshold);
            
            % Keep the figure in focus
            figure(fig);
            drawnow;
        catch ME
            warning('%s', ['Error in processing condition: ' ME.message]);
            % Use try-catch to handle error display gracefully
            try
                if isfield(handles, 'infoText')
                    % Create a safe error message
                    errMsg = sprintf('Error processing %s:\n%s', conditionName, ME.message);
                    set(handles.infoText, 'String', errMsg);
                end
            catch
                % If we can't set the info text, just print the error
                fprintf('ERROR: %s\n', ME.message);
            end
        end
    catch ME
        fprintf('ERROR in conditionCallback: %s\n', ME.message);
    end
    
    % Re-enable the callback
    try
        set(hObj, 'Enable', 'on');
    catch
        % Just in case something goes wrong
    end
end

% Function to process data and prepare for plotting
function processCondition(conditionName)
    try
        % Get the current figure and retrieve stored data and handles
        fig = gcf;
        icc = getappdata(fig, 'icc');
        handles = getappdata(fig, 'handles');
        brainModels = getappdata(fig, 'brainModels');
        
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
            
            % Disable 3D viewing if there are not enough channels
            if ~isempty(brainModels)
                set(handles.view3DToggle, 'Enable', 'off', 'Value', 0);
                set(handles.viewTabs, 'SelectedTab', handles.tab1);
            end
            return;
        else
            % Enable 3D viewing if there are enough channels
            if ~isempty(brainModels)
                set(handles.view3DToggle, 'Enable', 'on');
            end
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
        
        % Get the cluster-based ordering without creating a new figure
        % Save current figure management state
        currentFig = gcf;
        figVisState = get(0, 'DefaultFigureVisible');
        
        % Set global figure visibility to off and create hidden figure
        set(0, 'DefaultFigureVisible', 'off');
        try
            % Create temporary figure with no visibility
            h = figure('Visible', 'off', 'HandleVisibility', 'off', 'IntegerHandle', 'off');
            
            % Calculate cluster ordering
            [~, ~, outperm] = dendrogram(Z, 0);
            
            % Close temporary figure
            if ishandle(h)
                close(h);
            end
        catch ME
            % If any error occurs, make sure we clean up
            if exist('h', 'var') && ishandle(h)
                close(h);
            end
            rethrow(ME);
        end
        
        % Restore figure visibility state
        set(0, 'DefaultFigureVisible', figVisState);
        figure(currentFig); % Restore focus to the original figure
        
        % Get threshold value
        threshold = get(handles.thresholdSlider, 'Value');
        
        % Get clusters at the specified threshold
        clusters = cluster(Z, 'Cutoff', threshold, 'Criterion', 'distance');
        numClusters = max(clusters);
        
        % Add brain region cluster mapping if brain models are available
        if ~isempty(brainModels)
            % Get the templateBrain from brainModels
            templateBrain = brainModels.templateBrain;
            
            % Reorder clusters for visualization
            reordered_clusters = clusters(outperm);
            
            % Create a mapping for left-to-right cluster ordering
            [unique_clusters, ~] = unique(reordered_clusters, 'stable');
            
            % Create a mapping from original cluster numbers to left-to-right order
            inverse_cluster_map = zeros(numClusters, 1);
            for c = 1:length(unique_clusters)
                inverse_cluster_map(unique_clusters(c)) = c;
            end
            
            % First, create a mapping from filtered labels back to original positions
            labelMap = containers.Map(labels_filtered, find(validChannels));
            
            % Initialize cluster assignments for all regions in templateBrain
            regionClusterLabels = zeros(length(templateBrain.regionList), 1);
            
            % Map clusters back to original regions using the remapped cluster numbering
            for j = 1:length(labels_filtered)
                % Find the original index of this channel
                origIdx = labelMap(labels_filtered{j});
                
                % Find which region in templateBrain.regionList this corresponds to
                regionIdx = find(strcmp(templateBrain.regionList, labels{origIdx}));
                
                if ~isempty(regionIdx)
                    % Assign the remapped cluster label (left-to-right ordering)
                    originalCluster = clusters(j);
                    if originalCluster > 0
                        remappedCluster = inverse_cluster_map(originalCluster);
                        regionClusterLabels(regionIdx) = remappedCluster;
                    end
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
            
            % Store cluster regions for legend display
            clusterRegionNames = cell(max(regionClusterLabels), 1);
            for c = 1:max(regionClusterLabels)
                clusterRegionNames{c} = templateBrain.regionList(regionClusterLabels == c);
            end
        else
            regionClusterLabels = [];
            clusterRegionNames = [];
        end
        
        % Store the processed data
        appData = struct();
        appData.tc_sym = tc_sym;
        appData.Z = Z;
        appData.labels_filtered = labels_filtered;
        appData.outperm = outperm;
        appData.numChannels = length(labels_filtered);
        appData.clusters = clusters;
        appData.numClusters = numClusters;
        appData.validChannels = validChannels;
        appData.labels = labels;
        
        % Add region cluster data if available
        if ~isempty(brainModels)
            appData.regionClusterLabels = regionClusterLabels;
            appData.clusterRegionNames = clusterRegionNames;
            appData.inverse_cluster_map = inverse_cluster_map;
            appData.unique_clusters = unique_clusters;
        end
        
        setappdata(fig, 'appData', appData);
        
        % Update info text
        infoStr = sprintf('Condition: %s\nValid channels: %d/%d\nNumber of clusters: %d', ...
            conditionName, sum(validChannels), length(validChannels), numClusters);
        set(handles.infoText, 'String', infoStr);
    catch ME
        % Handle errors by displaying them
        warning('%s', ['Error in processCondition: ' ME.message]);
        rethrow(ME); % Re-throw to allow caller to handle
    end
end

% Function to update plots based on threshold value
function updatePlots(threshold)
    try
        % Get the current figure and retrieve stored data and handles
        fig = gcf;
        appData = getappdata(fig, 'appData');
        handles = getappdata(fig, 'handles');
        brainModels = getappdata(fig, 'brainModels');
        
        if ~isfield(appData, 'Z') || ~isfield(appData, 'tc_sym')
            set(handles.infoText, 'String', 'No data available for plotting');
            return;
        end
        
        % Get clusters at the specified threshold
        clusters = cluster(appData.Z, 'Cutoff', threshold, 'Criterion', 'distance');
        numClusters = max(clusters);
        
        % Check if masking small clusters is enabled
        maskSmallClusters = get(handles.maskToggle, 'Value');
        
        % Clear previous plots
        cla(handles.dendrogramAx);
        cla(handles.reorderedMatAx);
        
        % Plot 1: Dendrogram with threshold line
        % Make sure we're plotting in the correct axes
        axes(handles.dendrogramAx);
        
        % Call dendrogram with the 'Parent' parameter to ensure it plots in the correct axes
        dendrogram(appData.Z, 0, 'Labels', appData.labels_filtered, 'Parent', handles.dendrogramAx);
        title(handles.dendrogramAx, 'Hierarchical Clustering');
        xlabel(handles.dendrogramAx, 'Channel');
        ylabel(handles.dendrogramAx, 'Distance (1 - correlation)');
        set(handles.dendrogramAx, 'TickLabelInterpreter', 'none');
        
        % Add threshold line
        hold(handles.dendrogramAx, 'on');
        plot(handles.dendrogramAx, get(handles.dendrogramAx, 'XLim'), [threshold, threshold], 'r--', 'LineWidth', 2);
        hold(handles.dendrogramAx, 'off');
        
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
        
        % If masking small clusters is enabled, create a mask for clusters with >2 regions
        if maskSmallClusters
            % Count number of regions in each cluster
            clusterSizes = zeros(max(reordered_clusters_mapped), 1);
            for c = 1:max(reordered_clusters_mapped)
                clusterSizes(c) = sum(reordered_clusters_mapped == c);
            end
            
            % Create mask for clusters with >2 regions
            validClusters = clusterSizes > 2;
            validClusterMap = zeros(max(reordered_clusters_mapped), 1);
            validClusterMap(validClusters) = 1:sum(validClusters);
            
            % Apply mask to the matrix
            mask = validClusterMap(reordered_clusters_mapped) > 0;
            tc_reordered = tc_reordered(mask, mask);
            reordered_labels = reordered_labels(mask);
            reordered_clusters_mapped = validClusterMap(reordered_clusters_mapped(mask));
            
            % Update number of clusters
            numClusters = sum(validClusters);
        end
        
        % Create correlation matrix image in the correct axes
        imagesc(handles.reorderedMatAx, tc_reordered);
        colorbar(handles.reorderedMatAx);
        title(handles.reorderedMatAx, ['Clustered Matrix: ', num2str(numClusters), ' clusters']);
        xlabel(handles.reorderedMatAx, 'Channel');
        ylabel(handles.reorderedMatAx, 'Channel');
        set(handles.reorderedMatAx, 'XTick', 1:length(reordered_labels), 'XTickLabel', reordered_labels, ...
            'YTick', 1:length(reordered_labels), 'YTickLabel', reordered_labels);
        set(handles.reorderedMatAx, 'TickLabelInterpreter', 'none');
        xtickangle(handles.reorderedMatAx, 45);
        clim(handles.reorderedMatAx, [0 1]);
        
        % Add cluster outlines
        hold(handles.reorderedMatAx, 'on');
        % Find boundaries between clusters in the reordered matrix
        clusterBoundaries = find(diff(reordered_clusters_mapped) ~= 0);
        
        % Draw boundaries
        for b = 1:length(clusterBoundaries)
            % Draw horizontal line
            line(handles.reorderedMatAx, [0.5, length(reordered_clusters_mapped)+0.5], [clusterBoundaries(b)+0.5, clusterBoundaries(b)+0.5], ...
                 'Color', 'k', 'LineWidth', 2);
            % Draw vertical line
            line(handles.reorderedMatAx, [clusterBoundaries(b)+0.5, clusterBoundaries(b)+0.5], [0.5, length(reordered_clusters_mapped)+0.5], ...
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
                text(handles.reorderedMatAx, centerIdx, centerIdx, ['C', num2str(c)], 'Color', 'k', 'FontWeight', 'bold', ...
                     'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1 0.7]);
            end
        end
        hold(handles.reorderedMatAx, 'off');
        
        % Update the 3D brain visualization if available and enabled
        if ~isempty(brainModels) && isfield(handles, 'leftCortexAx') && get(handles.view3DToggle, 'Value')
            % Update cluster assignments for brain regions based on new threshold
            updateBrainClusters(threshold);
            
            % Get updated appData after cluster assignment update
            appData = getappdata(fig, 'appData');
            
            % Get colormap for clusters
            clusterColormap = getappdata(fig, 'clusterColormap');
            
            % Only proceed if we have cluster assignments for regions
            if isfield(appData, 'regionClusterLabels')
                % Get region cluster labels
                regionClusterLabels = appData.regionClusterLabels;
                
                % Create colors based on cluster labels
                regionColors = zeros(length(brainModels.templateBrain.regionList), 3);
                
                % Add 1 to cluster labels to use as indices (cluster 0 becomes 1, etc.)
                colorIndices = regionClusterLabels + 1;
                
                % Assign colors based on cluster
                for i = 1:length(colorIndices)
                    % Make sure we don't exceed colormap size
                    colorIdx = min(colorIndices(i), size(clusterColormap, 1));
                    regionColors(i, :) = clusterColormap(colorIdx, :);
                end
                
                % Plot each brain view
                % 1. Left Cortex View
                axes(handles.leftCortexAx);
                cla(handles.leftCortexAx);
                plotProjectedRegionsOnly(brainModels.templateBrainLeft, regionColors);
                view(handles.leftCortexAx, [270, 0]);
                title(handles.leftCortexAx, 'Left Lateral View');
                
                % 2. Right Cortex View
                axes(handles.rightCortexAx);
                cla(handles.rightCortexAx);
                rightColors = regionColors(~brainModels.hipAmygBool, :);
                plotProjectedRegionsOnly(brainModels.templateBrainRight, rightColors);
                view(handles.rightCortexAx, [270, 0]);
                title(handles.rightCortexAx, 'Right Lateral View');
                
                % 3. Insula View
                axes(handles.insulaAx);
                cla(handles.insulaAx);
                insulaColors = regionColors(brainModels.insulaBool, :);
                plotProjectedRegionsOnly(brainModels.insulaTemplateLeft, insulaColors);
                view(handles.insulaAx, [270, 0]);
                title(handles.insulaAx, 'Insula View');
                
                % 4. Hippocampus/Amygdala View 1
                axes(handles.hipAmygAx1);
                cla(handles.hipAmygAx1);
                hipAmygColors = regionColors(brainModels.hipAmygBool, :);
                plotProjectedRegionsOnly(brainModels.hipAmygTemplate, hipAmygColors);
                view(handles.hipAmygAx1, [-176.4, -90.0]);
                title(handles.hipAmygAx1, 'Hippocampus/Amygdala View 1');
                
                % 5. Hippocampus/Amygdala View 2
                axes(handles.hipAmygAx2);
                cla(handles.hipAmygAx2);
                plotProjectedRegionsOnly(brainModels.hipAmygTemplate, hipAmygColors);
                view(handles.hipAmygAx2, [-180.8, 73.9]);
                title(handles.hipAmygAx2, 'Hippocampus/Amygdala View 2');
                
                % Update legend
                updateClusterLegend();
            end
        end
        
        % Update info text with new number of clusters
        currentInfo = get(handles.infoText, 'String');
        
        % Handle the update differently based on whether currentInfo is a cell array or string
        if iscell(currentInfo)
            % Find the line with "Number of clusters" and update it
            clusterLineFound = false;
            for i = 1:length(currentInfo)
                if ischar(currentInfo{i}) && contains(currentInfo{i}, 'Number of clusters')
                    currentInfo{i} = ['Number of clusters: ' num2str(numClusters)];
                    clusterLineFound = true;
                    break;
                end
            end
            
            % If no line with cluster count was found, append it
            if ~clusterLineFound
                currentInfo{end+1} = ['Number of clusters: ' num2str(numClusters)];
            end
        else
            % Handle as string
            if ischar(currentInfo)
                if contains(currentInfo, 'Number of clusters')
                    % Replace the existing number
                    lines = strsplit(currentInfo, '\n');
                    clusterLineFound = false;
                    for i = 1:length(lines)
                        if contains(lines{i}, 'Number of clusters')
                            lines{i} = ['Number of clusters: ' num2str(numClusters)];
                            clusterLineFound = true;
                            break;
                        end
                    end
                    
                    % If somehow no line was found despite contains being true, append it
                    if ~clusterLineFound
                        lines{end+1} = ['Number of clusters: ' num2str(numClusters)];
                    end
                    
                    currentInfo = strjoin(lines, '\n');
                else
                    % Append the number of clusters
                    currentInfo = [currentInfo sprintf('\nNumber of clusters: %d', numClusters)];
                end
            else
                % If not a string or cell array, just create a new string
                currentInfo = sprintf('Number of clusters: %d', numClusters);
            end
        end
        
        set(handles.infoText, 'String', currentInfo);
        
        % Ensure the focus remains on the main figure
        figure(fig);
        
    catch ME
        % Get error message display handle
        fig = gcf;
        handles = getappdata(fig, 'handles');
        set(handles.infoText, 'String', sprintf('Error in plotting:\n%s', ME.message));
        disp(['ERROR in updatePlots: ' ME.message]);
        disp(ME.stack(1));
    end
end

% Helper function to update brain cluster assignments based on new threshold
function updateBrainClusters(threshold)
    try
        % Get the current figure and retrieve stored data
        fig = gcf;
        appData = getappdata(fig, 'appData');
        brainModels = getappdata(fig, 'brainModels');
        
        if isempty(brainModels) || ~isfield(appData, 'Z')
            return;
        end
        
        % Get templateBrain
        templateBrain = brainModels.templateBrain;
        
        % Get clusters at the specified threshold
        clusters = cluster(appData.Z, 'Cutoff', threshold, 'Criterion', 'distance');
        numClusters = max(clusters);
        
        % Reorder clusters for visualization
        reordered_clusters = clusters(appData.outperm);
        
        % Create a mapping for left-to-right cluster ordering
        [unique_clusters, ~] = unique(reordered_clusters, 'stable');
        
        % Create a mapping from original cluster numbers to left-to-right order
        inverse_cluster_map = zeros(numClusters, 1);
        for c = 1:length(unique_clusters)
            inverse_cluster_map(unique_clusters(c)) = c;
        end
        
        % Create a mapping from filtered labels back to original positions
        labelMap = containers.Map(appData.labels_filtered, find(appData.validChannels));
        
        % Initialize cluster assignments for all regions in templateBrain
        regionClusterLabels = zeros(length(templateBrain.regionList), 1);
        
        % Map clusters back to original regions using the remapped cluster numbering
        for j = 1:length(appData.labels_filtered)
            % Find the original index of this channel
            origIdx = labelMap(appData.labels_filtered{j});
            
            % Find which region in templateBrain.regionList this corresponds to
            regionIdx = find(strcmp(templateBrain.regionList, appData.labels{origIdx}));
            
            if ~isempty(regionIdx)
                % Assign the remapped cluster label (left-to-right ordering)
                originalCluster = clusters(j);
                if originalCluster > 0
                    remappedCluster = inverse_cluster_map(originalCluster);
                    regionClusterLabels(regionIdx) = remappedCluster;
                end
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
        
        % Store cluster regions for legend display
        clusterRegionNames = cell(max(regionClusterLabels), 1);
        for c = 1:max(regionClusterLabels)
            clusterRegionNames{c} = templateBrain.regionList(regionClusterLabels == c);
        end
        
        % Update appData with new cluster information
        appData.regionClusterLabels = regionClusterLabels;
        appData.clusterRegionNames = clusterRegionNames;
        appData.numClusters = numClusters;
        appData.inverse_cluster_map = inverse_cluster_map;
        appData.unique_clusters = unique_clusters;
        
        % Store updated appData
        setappdata(fig, 'appData', appData);
    catch ME
        disp(['ERROR in updateBrainClusters: ' ME.message]);
        disp(ME.stack(1));
    end
end

% Function to update the cluster legend
function updateClusterLegend()
    try
        % Get the current figure and retrieve stored data
        fig = gcf;
        appData = getappdata(fig, 'appData');
        handles = getappdata(fig, 'handles');
        clusterColormap = getappdata(fig, 'clusterColormap');
        
        if ~isfield(appData, 'regionClusterLabels') || ~isfield(handles, 'legendPanel')
            return;
        end
        
        % Get region cluster labels and names
        regionClusterLabels = appData.regionClusterLabels;
        clusterRegionNames = appData.clusterRegionNames;
        
        % Clear previous legend items
        delete(findall(handles.legendPanel, 'Type', 'uicontrol'));
        
        % Get unique clusters (including 0 for small clusters)
        unique_clusters = unique(regionClusterLabels);
        
        % Create scrollable panel for legend items
        legendScroll = uipanel(handles.legendPanel, 'Position', [0.05, 0.05, 0.9, 0.9], ...
                               'BorderType', 'none');
        
        % Calculate panel height based on number of clusters (each cluster needs about 0.15 height units)
        legendItems = uipanel(legendScroll, 'Position', [0, 0, 1, max(1, length(unique_clusters)*0.15)], ...
                              'BorderType', 'none');
        
        % Create slider for scrolling if needed
        if length(unique_clusters)*0.15 > 1
            slider = uicontrol(legendScroll, 'Style', 'slider', ...
                              'Units', 'normalized', ...
                              'Position', [0.95, 0, 0.05, 1], ...
                              'Value', 1, ...
                              'Callback', @scrollLegend);
            setappdata(slider, 'legendItems', legendItems);
        end
        
        % Add cluster info
        for i = 1:length(unique_clusters)
            cluster = unique_clusters(i);
            colorIdx = cluster + 1; % Adjust index for colormap
            
            % Make sure we don't exceed colormap size
            colorIdx = min(colorIdx, size(clusterColormap, 1));
            
            % Create background panel for this cluster
            clusterPanel = uipanel(legendItems, 'Position', [0.05, 1-i*0.15, 0.9, 0.14], ...
                                   'BorderType', 'none', 'BackgroundColor', [0.95, 0.95, 0.95]);
            
            % Color sample
            uicontrol(clusterPanel, 'Style', 'text', ...
                     'Units', 'normalized', ...
                     'Position', [0.05, 0.5, 0.15, 0.4], ...
                     'BackgroundColor', clusterColormap(colorIdx, :), ...
                     'String', '');
            
            % Cluster label
            if cluster == 0
                clusterLabel = 'Small clusters (≤2 regions)';
                numRegions = sum(regionClusterLabels == 0);
            else
                numRegions = length(clusterRegionNames{cluster});
                clusterLabel = ['Cluster ' num2str(cluster) ' (' num2str(numRegions) ' regions)'];
            end
            
            uicontrol(clusterPanel, 'Style', 'text', ...
                     'Units', 'normalized', ...
                     'Position', [0.25, 0.5, 0.7, 0.4], ...
                     'String', clusterLabel, ...
                     'HorizontalAlignment', 'left', ...
                     'BackgroundColor', [0.95, 0.95, 0.95]);
            
            % Region list (if not small clusters)
            if cluster > 0 && ~isempty(clusterRegionNames{cluster})
                % Format regions list
                regionsText = strjoin(clusterRegionNames{cluster}, ', ');
                
                % Truncate if too long
                if length(regionsText) > 50
                    regionsText = [regionsText(1:47) '...'];
                end
                
                uicontrol(clusterPanel, 'Style', 'text', ...
                         'Units', 'normalized', ...
                         'Position', [0.25, 0.1, 0.7, 0.4], ...
                         'String', regionsText, ...
                         'HorizontalAlignment', 'left', ...
                         'FontSize', 8, ...
                         'BackgroundColor', [0.95, 0.95, 0.95]);
            end
        end
    catch ME
        disp(['ERROR in updateClusterLegend: ' ME.message]);
        disp(ME.stack(1));
    end
end

% Callback for legend scrolling
function scrollLegend(hObject, ~)
    legendItems = getappdata(hObject, 'legendItems');
    value = get(hObject, 'Value');
    
    % Adjust position based on slider value (1 is top, 0 is bottom)
    pos = get(legendItems, 'Position');
    pos(2) = (value - 1) * (pos(4) - 1);
    set(legendItems, 'Position', pos);
end

% Callback for slider change
function sliderCallback(~, ~)
    fig = gcf;
    handles = getappdata(fig, 'handles');
    threshold = get(handles.thresholdSlider, 'Value');
    
    % Update the text display
    thresholdStr = num2str(threshold, '%.2f');
    set(handles.thresholdText, 'String', ['Threshold: ', thresholdStr]);
    
    % Update the edit field to match (without triggering its callback)
    set(handles.thresholdEdit, 'String', thresholdStr);
    
    % Update plots with the new threshold
    updatePlots(threshold);
end

% Callback for manual threshold entry
function thresholdEditCallback(hObj, ~)
    try
        % Get the entered value
        enteredValue = str2double(get(hObj, 'String'));
        
        % Validate the input
        if isnan(enteredValue)
            warning('Invalid threshold value entered');
            fig = gcf;
            handles = getappdata(fig, 'handles');
            set(hObj, 'String', num2str(get(handles.thresholdSlider, 'Value'), '%.2f'));
            return;
        end
        
        % Constrain to valid range
        threshold = min(max(enteredValue, 0.01), 0.99);
        
        % Update the value display if it was constrained
        if threshold ~= enteredValue
            set(hObj, 'String', num2str(threshold, '%.2f'));
        end
        
        % Get the main figure and handles
        fig = gcf;
        handles = getappdata(fig, 'handles');
        
        % Update the slider to match (without triggering its callback)
        set(handles.thresholdSlider, 'Value', threshold);
        
        % Update text display
        set(handles.thresholdText, 'String', ['Threshold: ', num2str(threshold, '%.2f')]);
        
        % Update plots
        updatePlots(threshold);
    catch ME
        warning('%s', ['Error in threshold edit: ' ME.message]);
    end
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

% Callback for mask toggle
function maskCallback(~, ~)
    fig = gcf;
    handles = getappdata(fig, 'handles');
    updatePlots(get(handles.thresholdSlider, 'Value'));
end

% Callback for 3D view toggle
function view3DCallback(hObject, ~)
    % Get the current figure
    fig = gcf;
    
    % Retrieve stored data and handles
    handles = getappdata(fig, 'handles');
    brainModels = getappdata(fig, 'brainModels');
    
    % Skip if no brain models are available
    if isempty(brainModels)
        return;
    end
    
    % Get the toggle state
    show3D = get(hObject, 'Value');
    
    % Update plots with current threshold
    threshold = get(handles.thresholdSlider, 'Value');
    updatePlots(threshold);
    
    % Switch to appropriate tab
    if show3D
        % Only switch if tab2 exists
        if ~isempty(handles.tab2)
            set(handles.viewTabs, 'SelectedTab', handles.tab2);
        end
    else
        % Switch to clustering tab
        set(handles.viewTabs, 'SelectedTab', handles.tab1);
    end
end

% Set callbacks
set(conditionDropdown, 'Callback', @conditionCallback);
set(thresholdSlider, 'Callback', @sliderCallback);
set(sigEdit, 'Callback', @sigCallback);
set(maskToggle, 'Callback', @maskCallback);
set(view3DToggle, 'Callback', @view3DCallback);
set(thresholdEdit, 'Callback', @thresholdEditCallback);

% Initialize with first condition - use safer initialization
try
    % Use a separate function for initialization to avoid scope issues
    initializeGUI(mainFig, conditions{1}, infoText);
catch ME
    % Use try-catch for safe error reporting
    try
        if exist('infoText', 'var') && ishandle(infoText)
            set(infoText, 'String', sprintf('Initialization error:\n%s', ME.message));
        end
    catch 
        % Fallback error reporting
    end
    
    % Always print error to command window as backup
    fprintf('ERROR during initialization: %s\n', ME.message);
    fprintf('  Line: %d in %s\n', ME.line, ME.stack(1).name);
end

% Helper function for initialization
function initializeGUI(fig, firstCondition, infoText)
    % Make sure figure is active
    if ishandle(fig)
        figure(fig);
        drawnow;
        
        % Process first condition
        processCondition(firstCondition);
    else
        warning('Invalid figure handle during initialization');
    end
end

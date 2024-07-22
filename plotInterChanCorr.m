clear all
addpath(genpath(cd))
load('data/interChannelCoherence.mat');

regionSort = readtable('code/dependencies/regionCategories.xlsx');
regionOrdered = {'Orbitofrontal cortex','Frontal Lobe','Cingulate cortex','Motor Cortex','Somatosensory Cortex','Operculum','Temporal Lobe','Hippocampus','Amygdala','Insula','Parietal Lobe','Occipital Lobe','Thalamus','White matter','Other'};

%%

% sort table by brain region
[~,idx] = ismember(regionSort.Class, regionOrdered);
[~,sortIdx] = sort(idx);
sortedTable = regionSort(sortIdx,:);


regions = [sortedTable.Name ;sortedTable.Name];

%%
fns = fieldnames(interChannelCoherence);

[r, c] = getSubplotDimensions(length(fns));
for i = 1:length(fns)



figure('Position',[ 83         377        3267         756]);
sgtitle(fns{i})
curDat = (interChannelCoherence.(fns{i}).TaskCoherence).^2;
curSig = interChannelCoherence.(fns{i}).pValue;
curD = interChannelCoherence.(fns{i}).cohensD;

nanIDX = isnan(curSig);
removeNan = find(any(nanIDX,1));


sigIDX = curSig < (0.05/(212*212));

subplot(1,3,1)
h = heatmap(curDat,'MissingDataColor',[1,1,1]);
    if i ==1 || i == 2
    colormap(getColors('lush lilac gradient'))
    elseif i == 3 || i == 4
    colormap(getColors('celadon porcelain gradient'))
    elseif i == 5 || i == 6
    colormap(getColors('lago blue gradient'))
    end
gca.XDisplayLabels = regions;
gca.YDisplayLabels = regions;
h.GridVisible = 'off';
title('Rho')
clim([0 .5])

subplot(1,3,2)
h = heatmap(curD,'MissingDataColor',[1,1,1]);
    if i ==1 || i == 2
    colormap(getColors('lush lilac gradient'))
    elseif i == 3 || i == 4
    colormap(getColors('celadon porcelain gradient'))
    elseif i == 5 || i == 6
    colormap(getColors('lago blue gradient'))
    end
gca.XDisplayLabels = regions;
gca.YDisplayLabels = regions;
title('CohD')
h.GridVisible = 'off';
clim([-3 3])


subplot(1,3,3)
h2 = imshow(sigIDX);
title('significant')

% Assuming correlationMatrix and logicalMatrix are defined
n = size(curDat, 1);  % Number of columns/rows
tri_upper = triu(sigIDX, 1);  % Extract upper triangular part, excluding the diagonal
% Create a graph
G = graph(tri_upper);

% Find connected components
[bin, binsize] = conncomp(G);





end

%%
fns = fieldnames(interChannelCoherence);

[r, c] = getSubplotDimensions(length(fns));
for i = 1:length(fns)




curDat = (interChannelCoherence.(fns{i}).TaskCoherence).^2;
curSig = interChannelCoherence.(fns{i}).pValue;
curD = interChannelCoherence.(fns{i}).cohensD;

nanIDX = isnan(curSig);
removeNan = find(any(nanIDX,1));


sigIDX = curSig < (0.05/(212*212));

% Assume 'logMatrix' is your logical matrix where 1s indicate significant correlations.

% Step 1: Extract the upper triangular part of the logical matrix
upperTriLog = triu(sigIDX, 1);  % Exclude the diagonal

% Step 2: Create adjacency matrix (make it symmetric)
adjMatrix = upperTriLog + upperTriLog';

% Step 3: Create a graph and find connected components
G = graph(adjMatrix);
comp = conncomp(G);

% Step 4: Extract and group indices
numComponents = max(comp);
groups = cell(1, numComponents);
for i = 1:numComponents
    groups{i} = find(comp == i);
end

% Step 5: Plot the graph
figure;
h = plot(G, 'Layout', 'force');


% Label nodes for clarity
labelnode(h, 1:numnodes(G), string(1:numnodes(G)));

% Display the groups
disp(groups);




end
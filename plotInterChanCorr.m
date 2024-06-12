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

figure();
sgtitle(fns{i})
curDat = (interChannelCoherence.(fns{i}).TaskCoherence).^2;
curSig = interChannelCoherence.(fns{i}).pValue;
curD = interChannelCoherence.(fns{i}).cohensD;

nanIDX = isnan(curSig);
removeNan = find(any(nanIDX,1));


sigIDX = curSig < 0.001;

subplot(1,3,1)
h = heatmap(curDat,'MissingDataColor',[.01,.01,.01]);
colormap(getColors('black red gradient'));
gca.XDisplayLabels = regions;
gca.YDisplayLabels = regions;
title('Rho')

subplot(1,3,2)
h = heatmap(curD,'MissingDataColor',[.01,.01,.01]);
colormap(getColors('black red gradient'));
gca.XDisplayLabels = regions;
gca.YDisplayLabels = regions;
title('CohD')
clim([-3 3])


subplot(1,3,3)
h2 = imshow(sigIDX);
title('significant')



end
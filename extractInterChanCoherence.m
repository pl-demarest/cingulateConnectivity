clear
addpath(genpath(cd))
load('data/pooledData.mat','electrodeCoordinates','CCEPs','electrodeRegionLabel','stimulatedChannels','stimulatedRegion','pValue','cohensD')

c.ACC = {'G_and_S_cingul-Ant'};
c.MCC = {'G_and_S_cingul-Mid-Ant'
'G_and_S_cingul-Mid-Post'};
c.PCC = {'G_cingul-Post-dorsal'
'G_cingul-Post-ventral'};

alpha = calculateAlphaThreshold(pValue, 0.0001);
significant = (pValue < alpha) & (cohensD > 0);

%% Downsample CCEPs
CCEPs = downsample(CCEPs,3);

% (Optional) Combine conditions across hemispheres if desired:
% c.ACC = [c.leftACC, c.rightACC];
% c.MCC = [c.leftMCC, c.rightMCC];
% c.PCC = [c.leftPCC, c.rightPCC];

regionSort = readtable('code/dependencies/regionCategories.xlsx');
%Reorganize table by merging somatosensory and motor regions, and remove
%any class regions "Other"
figureRegions = regionSort;
merge = contains(figureRegions.Class,{'Motor Cortex','Somatosensory Cortex'});
mergeTo = 'Somato-Motor Cortex';

remove = contains(figureRegions.Class,{'Occipital Lobe', 'Other', 'White Matter', 'White matter'});

figureRegions.Class(merge) = {mergeTo};
figureRegions(remove,:) = [];

%reorder and sort regions by region CLass
classOrder = {'Orbitofrontal cortex','Frontal Lobe','Cingulate cortex','Somato-Motor Cortex','Operculum','Temporal Lobe','Hippocampus','Amygdala','Insula','Parietal Lobe','Occipital Lobe','Thalamus'};

[~,idx] = ismember(figureRegions.Class,classOrder);
[~,sortIDX] = sort(idx);
figureRegions = figureRegions(sortIDX,:);
figureRegions = removevars(figureRegions,'Region');

[~,groupLabels] = ismember(figureRegions.Class,classOrder);

% Using the y coordinates of electrodes with labels, organize the table
% region names within each group to be from anterior to posterior
groupLabelsUnique = unique(groupLabels);

% iterate through each group, identify all the regions, obtain an average y
% value for each, reorder based on anterior to posterior of each group
for g = 1:length(groupLabelsUnique)
initDistances = [];

curRegionsIDX = groupLabels == groupLabelsUnique(g);
curRegions = figureRegions.Name(curRegionsIDX);

%initialize and store temporary average position of electrodes regions within the class label, 

tempDistances = [];

for r = 1:length(curRegions)
regionsIDX = contains([electrodeRegionLabel{:}],curRegions{r});
tempDistances(r) = mean(electrodeCoordinates(2,regionsIDX));
end

%oranize and resort by rank, then amend table as needed 
[~,idx] = sort(tempDistances,'descend');
curRegions = curRegions(idx);
figureRegions.Name(curRegionsIDX) = curRegions;
end

%% remove any table entries where the region does not exist in the dataset.
close all
regions = unique([electrodeRegionLabel{:}]);

%since data labels contain more characters than table labels, we will have
%to loop through and use the contains function for each individual element.
%Also, do not include the cingul-Marginalis as part of this divergent
%connectivity figure since it is not one of the regions of interest.
count = 1;
temp = [];
for i = 1:length(figureRegions.Name)
    if ~any(contains(regions,figureRegions.Name(i))) || strcmp(figureRegions.Name(i), 'S_cingul-Marginalis')
        temp(count) = i;
        count = count+1;
    end
end

figureRegions(temp,:) = [];

% Use only one entry per region (combine left & right)
regions = figureRegions.Name;

storeMeanTaskCorr = nan(length(regions),length(regions));
storeMeanBaseCorr = nan(length(regions),length(regions));
storeP = nan(length(regions),length(regions));
storeCohensD = nan(length(regions),length(regions));
storeBaseLag = nan(length(regions),length(regions));
storeTaskLag = nan(length(regions),length(regions));
storeBaseCor = cell(length(regions),length(regions));
storeTaskCor = cell(length(regions),length(regions));

%%
conditions = fieldnames(c);
baseWindow = 1:610;
taskWindow = 640:1108;

for con = 1:length(conditions)
    curCondition = c.(conditions{con});
    curIDX = contains([stimulatedRegion{:}], curCondition);
    disp(conditions{con})
    fprintf(1, '[.')
    
    for i = 1:length(regions)
        curRegion = regions{i}; % cell array indexing
        curRegionIDX = contains([electrodeRegionLabel{:}], curRegion);
        % Remove hemisphere mask: group channels regardless of hemisphere
        indexes = curRegionIDX & curIDX & ~stimulatedChannels & significant;
        curDat = CCEPs(:, indexes)';
    
        for j = i:length(regions)
            curRegion2 = regions{j};
            curRegionIDX2 = contains([electrodeRegionLabel{:}], curRegion2);
            indexes2 = curRegionIDX2 & curIDX & ~stimulatedChannels & significant;
            curDat2 = CCEPs(:, indexes2)';
    
            if ~((isempty(curDat2) || isempty(curDat)) || ((size(curDat,1) <= 1) && (size(curDat2,1) <= 1)))
                [baseCorr, baseLag] = getUniqueCorrelations(curDat(:, baseWindow), curDat2(:, baseWindow), 'cross');
                [taskCorr, taskLag] = getUniqueCorrelations(curDat(:, taskWindow), curDat2(:, taskWindow), 'cross');
    
                p = signrank(baseCorr, taskCorr);
                Tmean = nanmean(taskCorr);
                Bmean = nanmean(baseCorr);
                effectSize = computeCohenD(taskCorr, baseCorr, 'paired');
    
                storeMeanTaskCorr(i, j) = Tmean;
                storeMeanBaseCorr(i, j) = Bmean;
                storeP(i, j) = p;
                storeCohensD(i, j) = effectSize;
                storeBaseLag(i, j) = nanmean(baseLag);
                storeTaskLag(i, j) = nanmean(taskLag);
                
                storeBaseCor{i, j} = baseCorr;
                storeTaskCor{i, j} = taskCorr;
                fprintf(1, '.');
            end
        end
    end
    fprintf(1, '] done\n');
    
    interChannelCoherence.(conditions{con}).taskCoherence = storeMeanTaskCorr;
    interChannelCoherence.(conditions{con}).baselineCoherence = storeMeanBaseCorr;
    interChannelCoherence.(conditions{con}).pValue = storeP;
    interChannelCoherence.(conditions{con}).cohensD = storeCohensD;
    interChannelCoherence.(conditions{con}).baseCoherenceAll = storeBaseCor;
    interChannelCoherence.(conditions{con}).CCEPCoherenceAll = storeTaskCor;
    interChannelCoherence.(conditions{con}).labels = regions;
    interChannelCoherence.(conditions{con}).baseLag = storeBaseLag;
    interChannelCoherence.(conditions{con}).taskLag = storeTaskLag;
end

interChannelCoherence.regions = regions;

save("data/interChannelCoherenceSignificant.mat", "interChannelCoherence", '-v7.3')

clear
addpath(genpath(cd))
load('data/pooledData.mat')


c.rightACC = {'ctx_rh_G_and_S_cingul-Ant','wm_rh_G_and_S_cingul-Ant'};
c.leftACC = {'ctx_lh_G_and_S_cingul-Ant','wm_lh_G_and_S_cingul-Ant'};

c.rightMCC = {'ctx_rh_G_and_S_cingul-Mid-Ant','ctx_rh_G_and_S_cingul-Mid-Post','wm_rh_G_and_S_cingul-Mid-Ant','wm_rh_G_and_S_cingul-Mid-Post'};
c.leftMCC = {'ctx_lh_G_and_S_cingul-Mid-Ant','ctx_lh_G_and_S_cingul-Mid-Post','wm_lh_G_and_S_cingul-Mid-Ant','wm_lh_G_and_S_cingul-Mid-Post'};

c.rightPCC = {'ctx_rh_G_cingul-Post-dorsal', 'ctx_rh_G_cingul-Post-ventral', 'wm_rh_G_cingul-Post-dorsal','wm_rh_G_cingul-Post-ventral'};
c.leftPCC = {'ctx_lh_G_cingul-Post-dorsal','ctx_lh_G_cingul-Post-ventral','wm_lh_G_cingul-Post-dorsal','wm_lh_G_cingul-Post-ventral'};

regionSort = readtable('code/dependencies/regionCategories.xlsx');
regionOrdered = {'Orbitofrontal cortex','Frontal Lobe','Cingulate cortex','Motor Cortex','Somatosensory Cortex','Operculum','Temporal Lobe','Hippocampus','Amygdala','Insula','Parietal Lobe','Occipital Lobe','Thalamus','White matter','Other'};

%%
chans = electrodeCoordinates';
uChans = unique(chans,"rows",'stable');

% sort table by brain region
[~,idx] = ismember(regionSort.Class, regionOrdered);
[~,sortIdx] = sort(idx);
sortedTable = regionSort(sortIdx,:);


regions = sortedTable.Name;

%%
conditions = fieldnames(c);
baseWindow = [1:1900];
taskWindow = [1920: 3320];

for con = 1:length(conditions)

curCondition = c.(conditions{con});

curIDX = contains([stimulatedRegion{:}],curCondition);


% left hemisphere
lh = chans(:,1) < 0;
% right hemisphere
rh = chans(:,1) > 0;

for i = 1:length(regions)

    curRegion = regions(i);
    curRegionIDX = contains([electrodeRegionLabel{:}],curRegion);
    indexes = curRegionIDX & curIDX & ~stimulatedChannels & lh';

    curDat = CCEPs(:,indexes)';


    %left hemisphere
    for j = 1:length(regions)
        curRegion2 = regions(j);
        curRegionIDX2 = contains([electrodeRegionLabel{:}],curRegion2);
        indexes2 = curRegionIDX2 & curIDX & ~stimulatedChannels & lh';
        curDat2 = CCEPs(:,indexes2)';


        if (isempty(curDat2) || isempty(curDat)) || ((size(curDat,1) <= 1) && (size(curDat2,1) <= 1))

        storeMeanTaskCorr(i,j) = nan;
        storeMeanBaseCorr(i,j) = nan;
        storeP(i,j) = nan;
        storeCohensD(i,j) = nan;

        storeBaseCor{i,j} = {nan};
        storeTaskCor{i,j} = {nan};


        else
        baseCorr = getUniqueCorrelations(curDat(:,baseWindow),curDat2(:,baseWindow));
        taskCorr = getUniqueCorrelations(curDat(:,taskWindow),curDat2(:,taskWindow));

        p = signrank(baseCorr,taskCorr);
        Tmean = nanmean(taskCorr);
        Bmean = nanmean(baseCorr);
        effectSize = computeCohenD(taskCorr,baseCorr,'paired');

        storeMeanTaskCorr(i,j) = Tmean;
        storeMeanBaseCorr(i,j) = Bmean;
        storeP(i,j) = p;
        storeCohensD(i,j) = effectSize;
        
        
        storeBaseCor{i,j} = baseCorr;
        storeTaskCor{i,j} = taskCorr;

        end
    end

    countj = 1;
    for j = length(regions)+1:2*length(regions)
        curRegion2 = regions(countj);
        curRegionIDX2 = contains([electrodeRegionLabel{:}],curRegion2);
        indexes2 = curRegionIDX2 & curIDX & ~stimulatedChannels & rh';
        curDat2 = CCEPs(:,indexes2)';


        if (isempty(curDat2) || isempty(curDat)) || ((size(curDat,1) <= 1) && (size(curDat2,1) <= 1))

        storeMeanTaskCorr(i,j) = nan;
        storeMeanBaseCorr(i,j) = nan;
        storeP(i,j) = nan;
        storeCohensD(i,j) = nan;

        storeBaseCor{i,j} = {nan};
        storeTaskCor{i,j} = {nan};


        else
        baseCorr = getUniqueCorrelations(curDat(:,baseWindow),curDat2(:,baseWindow));
        taskCorr = getUniqueCorrelations(curDat(:,taskWindow),curDat2(:,taskWindow));

        p = signrank(baseCorr,taskCorr);
        Tmean = nanmean(taskCorr);
        Bmean = nanmean(baseCorr);
        effectSize = computeCohenD(taskCorr,baseCorr,'paired');

        storeMeanTaskCorr(i,j) = Tmean;
        storeMeanBaseCorr(i,j) = Bmean;
        storeP(i,j) = p;
        storeCohensD(i,j) = effectSize;
        
        
        storeBaseCor{i,j} = baseCorr;
        storeTaskCor{i,j} = taskCorr;

        end

    countj = countj + 1;
    end

end

% right hemisphere
rh = chans(:,1) > 0;
counti = 1;
for i = length(regions)+1:2*length(regions)

    curRegion = regions(counti);
    curRegionIDX = contains([electrodeRegionLabel{:}],curRegion);
    indexes = curRegionIDX & curIDX & ~stimulatedChannels & rh';

    curDat = CCEPs(:,indexes)';

     for j = 1:length(regions)
        curRegion2 = regions(j);
        curRegionIDX2 = contains([electrodeRegionLabel{:}],curRegion2);
        indexes2 = curRegionIDX2 & curIDX & ~stimulatedChannels & lh';
        curDat2 = CCEPs(:,indexes2)';


        if (isempty(curDat2) || isempty(curDat)) || ((size(curDat,1) <= 1) && (size(curDat2,1) <= 1))

        storeMeanTaskCorr(i,j) = nan;
        storeMeanBaseCorr(i,j) = nan;
        storeP(i,j) = nan;
        storeCohensD(i,j) = nan;

        storeBaseCor{i,j} = {nan};
        storeTaskCor{i,j} = {nan};


        else
        baseCorr = getUniqueCorrelations(curDat(:,baseWindow),curDat2(:,baseWindow));
        taskCorr = getUniqueCorrelations(curDat(:,taskWindow),curDat2(:,taskWindow));

        p = signrank(baseCorr,taskCorr);
        Tmean = nanmean(taskCorr);
        Bmean = nanmean(baseCorr);
        effectSize = computeCohenD(taskCorr,baseCorr,'paired');

        storeMeanTaskCorr(i,j) = Tmean;
        storeMeanBaseCorr(i,j) = Bmean;
        storeP(i,j) = p;
        storeCohensD(i,j) = effectSize;
        
        
        storeBaseCor{i,j} = baseCorr;
        storeTaskCor{i,j} = taskCorr;

        end
    end

    countj = 1;
    for j = length(regions)+1:2*length(regions)
        curRegion2 = regions(countj);
        curRegionIDX2 = contains([electrodeRegionLabel{:}],curRegion2);
        indexes2 = curRegionIDX2 & curIDX & ~stimulatedChannels & rh';
        curDat2 = CCEPs(:,indexes2)';


        if (isempty(curDat2) || isempty(curDat)) || ((size(curDat,1) <= 1) && (size(curDat2,1) <= 1))

        storeMeanTaskCorr(i,j) = nan;
        storeMeanBaseCorr(i,j) = nan;
        storeP(i,j) = nan;
        storeCohensD(i,j) = nan;

        storeBaseCor{i,j} = {nan};
        storeTaskCor{i,j} = {nan};


        else
        baseCorr = getUniqueCorrelations(curDat(:,baseWindow),curDat2(:,baseWindow));
        taskCorr = getUniqueCorrelations(curDat(:,taskWindow),curDat2(:,taskWindow));

        p = signrank(baseCorr,taskCorr);
        Tmean = nanmean(taskCorr);
        Bmean = nanmean(baseCorr);
        effectSize = computeCohenD(taskCorr,baseCorr,'paired');

        storeMeanTaskCorr(i,j) = Tmean;
        storeMeanBaseCorr(i,j) = Bmean;
        storeP(i,j) = p;
        storeCohensD(i,j) = effectSize;
        
        
        storeBaseCor{i,j} = baseCorr;
        storeTaskCor{i,j} = taskCorr;

        end

    countj = countj + 1;
    end
    
counti = counti + 1;

end

interChannelCoherence.(conditions{con}).TaskCoherence = storeMeanTaskCorr;
interChannelCoherence.(conditions{con}).BaselineCoherence = storeMeanBaseCorr;
interChannelCoherence.(conditions{con}).pValue = storeP;
interChannelCoherence.(conditions{con}).cohensD = storeCohensD;
interChannelCoherence.(conditions{con}).BaseCoherence = storeBaseCor;
interChannelCoherence.(conditions{con}).CCEPCoherence = storeTaskCor;
interChannelCoherence.(conditions{con}).labels = regions;

end

save("data/interChannelCoherence.mat","interChannelCoherence",'-v7.3')
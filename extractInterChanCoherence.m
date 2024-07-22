clear
addpath(genpath(cd))
load('data/pooledData.mat','electrodeCoordinates','CCEPs','electrodeRegionLabel','stimulatedChannels','stimulatedRegion')

%%downsample CCEPs
CCEPs = downsample(CCEPs,3);

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


regions = [sortedTable.Name; sortedTable.Name];


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
baseWindow = [1:627];
taskWindow = [641: 1108];
% left hemisphere
lh = chans(:,1) < 0;
% right hemisphere
rh = chans(:,1) > 0;

for con = 1:length(conditions)

curCondition = c.(conditions{con});
curIDX = contains([stimulatedRegion{:}],curCondition);
disp(conditions{con})
fprintf(1,'[.')
for i = 1:length(regions)

    curRegion = regions(i);
    curRegionIDX = contains([electrodeRegionLabel{:}],curRegion);
    if i <= (length(regions)/2)
    indexes = curRegionIDX & curIDX & ~stimulatedChannels & lh';
    elseif i > (length(regions)/2)
    indexes = curRegionIDX & curIDX & ~stimulatedChannels & rh';
    end
    curDat = CCEPs(:,indexes)';

    %left hemisphere
    for j = i:length(regions)
        curRegion2 = regions(j);
        curRegionIDX2 = contains([electrodeRegionLabel{:}],curRegion2);

        if j <= (length(regions)/2)
        indexes2 = curRegionIDX2 & curIDX & ~stimulatedChannels & lh';
        elseif j > (length(regions)/2)
        indexes2 = curRegionIDX2 & curIDX & ~stimulatedChannels & rh';
        end
        curDat2 = CCEPs(:,indexes2)';


        if ~((isempty(curDat2) || isempty(curDat)) || ((size(curDat,1) <= 1) && (size(curDat2,1) <= 1)))

        [baseCorr, baseLag] = getUniqueCorrelations(curDat(:,baseWindow),curDat2(:,baseWindow),'cross');
        [taskCorr, taskLag] = getUniqueCorrelations(curDat(:,taskWindow),curDat2(:,taskWindow),'cross');

        p = signrank(baseCorr,taskCorr);
        Tmean = nanmean(taskCorr);
        Bmean = nanmean(baseCorr);
        effectSize = computeCohenD(taskCorr,baseCorr,'paired');

        storeMeanTaskCorr(i,j) = Tmean;
        storeMeanBaseCorr(i,j) = Bmean;
        storeP(i,j) = p;
        storeCohensD(i,j) = effectSize;
        storeBaseLag(i,j) = nanmean(baseLag);
        storeTaskLag(i,j) = nanmean(taskLag);
        
        storeBaseCor{i,j} = baseCorr;
        storeTaskCor{i,j} = taskCorr;
            fprintf(1,'.');
        
        end

    end

end


fprintf(1,'] done\n');

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

save("data/interChannelCoherence.mat","interChannelCoherence",'-v7.3')
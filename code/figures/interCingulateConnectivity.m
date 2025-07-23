%% for  figure components of figure 2
clear
close all
addpath(genpath(cd))

%add PEABrain to handle 3dd modeling
addpath(genpath('/Volumes/Samsung_T5/PEABrain'));
%
pooledData = load('data/pooledData.mat');
load('data/compiledData.mat');
load('code/dependencies/templateBrain.mat');
load('code/dependencies/listHip.mat');
load('code/dependencies/listAmyg.mat');
load('code/dependencies/cingulateNames.mat');
load('data/pooledBrain.mat');


regionSort = readtable('code/dependencies/regionCategories.xlsx');
saveDir = 'figures/main/figure2/dependencies/';
mkdir(saveDir);

% get logical array for significant responses
alpha = calculateAlphaThreshold(pooledData.pValue, 0.0001);
significant = (pooledData.pValue < alpha) & (pooledData.cohensD > 0);

stimulated = logical(pooledData.stimulatedChannels);

sigChannelsIDX = find(pooledData.pValue < alpha);
stimRegion = [pooledData.stimulatedRegion{sigChannelsIDX}]; 
temp = [pooledData.stimulatedRegion{:}];
%index groups for each subregion of the cingulate
idx.lACC = find(ismember(stimRegion,leftACC));
idx.rACC = find(ismember(stimRegion,rightACC));
idx.lMCC = find(ismember(stimRegion,leftMCC));
idx.rMCC = find(ismember(stimRegion,rightMCC));
idx.lPCC = find(ismember(stimRegion,leftPCC));
idx.rPCC = find(ismember(stimRegion,rightPCC));
acc = ismember(temp,leftACC) | ismember(temp,rightACC);
mcc = ismember(temp,leftMCC) | ismember(temp,rightMCC);
pcc = ismember(temp,leftPCC) | ismember(temp,rightPCC);

%initialize colors
aColor = getColors('lush lilac');
mColor = getColors('celadon porcelain');
pColor = getColors('lago blue');

%initialize names of cingulate cortex for downstream indexing
cingulateNamesSimple = {'G_and_S_cingul-Ant'
'G_and_S_cingul-Mid-Ant'
'G_and_S_cingul-Mid-Post'
'G_cingul-Post-dorsal'
'G_cingul-Post-ventral'};

%create cingulate cortex data structure (same as figure 1)
cingulateRegions.regions = rmfield(cortOut.regions,'otherRegions');

%colors for the cingulate 3D model
regionColorsCC = [getColors('lush lilac');
    getColors('lago blue');
    getColors('celadon porcelain');
    getColors('celadon porcelain');
    getColors('lago blue');
    0.2,0.2,0.2;
    0.2,0.2,0.2];

%% generate a inter-cingulate connectivity

%get logical arrays for electrodes recording in each cingulate subregion;
temp = [pooledData.electrodeRegionLabel{:}];
accR = ismember(temp,leftACC) | ismember(temp,rightACC);
mccR = ismember(temp,leftMCC) | ismember(temp,rightMCC);
pccR = ismember(temp,leftPCC) | ismember(temp,rightPCC);
jitterAmplitude = 5;


figure('Position',[281          32        3060        1260]);
[CCsurface] = plotProjectedRegionsOnly(cingulateRegions,regionColorsCC);
for i = 1:length(CCsurface)
CCsurface(i).FaceAlpha = 0.1; %change alpha of all generated surfaces
end
hold on

%iterate through the 3 conditions, creating a 3d plot of the connections
%between the stimulated electrode coordinate and the recording electrode

for c = 1:3

if c == 1 %plot all observed connections between acc and mcc/pcc

    stimulatedIDX = acc; %channels where ACC was stimulated
    recordedIDX = mccR | pccR;
    plotIDX = stimulatedIDX & recordedIDX & significant;

    iteratePlot = find(plotIDX);

    %normalize data within condition
    dataToPlot = normalizeToRange(pooledData.cohensD(plotIDX), 1, 4);
    for i = 1:length(iteratePlot)
        curIDX = iteratePlot(i);
        currentStart = pooledData.stimulatedChannelCoord(:,curIDX)';
        currentEnd = pooledData.electrodeCoordinates(:,curIDX)';
        curEffect = dataToPlot(i);

        [x,y,z] = curvedSpline3D(currentStart, currentEnd, 3,1, 15, 100,jitterAmplitude);
        plot3(x, y, z, 'LineWidth', curEffect, 'Color', [aColor,.7]);
        
    hold on
    end
%store datapoints of MCC/PCC connectivity 
accMCC = pooledData.cohensD(mccR & stimulatedIDX & significant);
accPCC = pooledData.cohensD(pccR & stimulatedIDX & significant);

%count number of subjects 
accSubjects = length(unique(pooledData.subjectID(plotIDX)));



elseif c == 2 %for mcc

    stimulatedIDX = mcc; %channels where ACC was stimulated
    recordedIDX = accR | pccR;
    plotIDX = stimulatedIDX & recordedIDX & significant;

    iteratePlot = find(plotIDX);

    %normalize data within condition
    dataToPlot = normalizeToRange(pooledData.cohensD(plotIDX), 1, 4);
    for i = 1:length(iteratePlot)
        curIDX = iteratePlot(i);
        currentStart = pooledData.stimulatedChannelCoord(:,curIDX)';
        currentEnd = pooledData.electrodeCoordinates(:,curIDX)';
        curEffect = dataToPlot(i);
        
        
        [x,y,z] = curvedSpline3D(currentStart, currentEnd, 3, 1, 20, 100,jitterAmplitude);
        plot3(x, y, z, 'LineWidth', curEffect, 'Color', [mColor,.7]);
        
    hold on
    end

    %store datapoints of ACC/PCC connectivity 
mccACC = pooledData.cohensD(accR & stimulatedIDX & significant);
mccPCC = pooledData.cohensD(pccR & stimulatedIDX & significant);

%count number of subjects 
mccSubjects = length(unique(pooledData.subjectID(plotIDX)));

elseif c == 3

    stimulatedIDX = pcc; %channels where ACC was stimulated
    recordedIDX = accR | mccR;
    plotIDX = stimulatedIDX & recordedIDX & significant;

    iteratePlot = find(plotIDX);

    %normalize data within condition
    dataToPlot = normalizeToRange(pooledData.cohensD(plotIDX), 1, 4);
    for i = 1:length(iteratePlot)
        curIDX = iteratePlot(i);
        currentStart = pooledData.stimulatedChannelCoord(:,curIDX)';
        currentEnd = pooledData.electrodeCoordinates(:,curIDX)';
        curEffect = dataToPlot(i);


        [x,y,z] = curvedSpline3D(currentStart, currentEnd, 2, 1, 20, 100,jitterAmplitude);
        plot3(x, y, z, 'LineWidth', curEffect, 'Color', [pColor,.7]);

        
    hold on
    end
%store datapoints of MCC/PCC connectivity 
pccACC = pooledData.cohensD(accR & stimulatedIDX & significant);
pccMCC = pooledData.cohensD(mccR & stimulatedIDX & significant);

%count number of subjects 
pccSubjects = length(unique(pooledData.subjectID(plotIDX)));

end

end

set(gca,'CameraViewAngleMode','Manual')
axis equal
saveResults.subjectCountLabels = {'ACC','MCC','PCC'};
saveResults.subjectCount = [accSubjects, mccSubjects, pccSubjects];
zoom(1)

%%
view([-270,0])%for sagital
saveas(gcf,[saveDir '_CCsagital1.svg'])
saveas(gcf,[saveDir '_CCsagital1.png'])

view([270,0])%for sagital
saveas(gcf,[saveDir '_CCsagital2.svg'])
saveas(gcf,[saveDir '_CCsagital2.png'])

%% create violin plots of each subregion's connectivity measures

%for ACC
accDat = nan(max([length(mccACC), length(pccACC)]),2);
accDat(1:length(mccACC),1) = mccACC; accDat(1:length(pccACC),2) = pccACC;

%for MCC
mccDat = nan(max([length(accMCC), length(pccMCC)]),2);
mccDat(1:length(accMCC),1) = accMCC; mccDat(1:length(pccMCC),2) = pccMCC;

%for PCC
pccDat = nan(max([length(accPCC), length(mccPCC)]),2);
pccDat(1:length(accPCC),1) = accPCC; pccDat(1:length(mccPCC),2) = mccPCC;

maxRows = max([size(accDat,1), size(mccDat,1), size(pccDat,1)]);

% Create a new matrix with NaNs: there are 2 columns per original matrix (total 6)
allData = nan(maxRows, 6);

% Insert each matrix into its own set of columns
allData(1:size(accDat,1), 1:2) = accDat; %mmc,pcc
allData(1:size(mccDat,1), 3:4) = mccDat; %acc,pcc
allData(1:size(pccDat,1), 5:6) = pccDat; %acc,mcc

%statistical tests

a = ranksum(allData(:,1),allData(:,2));
m = ranksum(allData(:,3),allData(:,4));
p = ranksum(allData(:,5),allData(:,6));

saveResults.comparisonLabels = {'acc: mcc vs pcc', 'mcc: acc vs pcc', 'pcc: acc vs mcc'};
saveResults.comparisonStats = [a,m,p];
saveResults.averagesLabels = {'mcc-acc','pcc-acc','acc-mcc','pcc-mcc','acc-pcc','mcc-pcc'};
saveResults.averageConnectivity = [nanmean(allData(:,1)),nanmean(allData(:,2)),nanmean(allData(:,3)),nanmean(allData(:,4)),nanmean(allData(:,5)),nanmean(allData(:,6))];

%store confidence intervals to save

for i = 1:size(allData,2)
[ciLower(i), ciUpper(i)]= bootstrapCI(allData(:,i));
end
saveResults.ciLower = ciLower;
saveResults.ciUpper = ciUpper;
appendLog('Supp Fig 2 Inter-cingulate connectivity', 'statistical comparisons of each cingulate subregion to each other subregions using coherence', saveResults)
clear saveResults;

dataVec = [];    % To store all numeric data
groupVec = [];   % To store corresponding integer group labels
% Loop over each column in allData.
for j = 1:size(allData,2)
    % Extract non-NaN entries from the j-th column.
    validIdx = ~isnan(allData(:,j));
    colData = allData(validIdx, j);
    
    % Use the column number as the integer group label.
    groupLabel = j;
    
    % Append data and the corresponding group labels.
    dataVec = [dataVec; colData];
    groupVec = [groupVec; repmat(groupLabel, length(colData), 1)];
end
%colors for groups
colors = [mColor;pColor;aColor;pColor;aColor;mColor];

%
figure('position',[10 10 800 800/1.23])
beeswarm(groupVec,dataVec,'overlay_style','ci','colormap',colors)
saveas(gcf,[saveDir '_CCSwarm.svg'])
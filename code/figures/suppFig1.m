%% for  figure components of figure 2
clear
close all
addpath(genpath(cd))

pooledData = load('data/pooledData.mat');
load('data/compiledData.mat');
load('code/dependencies/templateBrain.mat');
load('code/dependencies/listHip.mat');
load('code/dependencies/listAmyg.mat');
load('code/dependencies/cingulateNames.mat');
load('data/pooledBrain.mat');

hipAmyg = [listAmyg,listHip];
regionSort = readtable('code/dependencies/regionCategories.xlsx');
saveDir = 'figures/main/figure1/dependencies/';
mkdir(saveDir);

% get logical array for significant responses
alpha = calculateAlphaThreshold(pooledData.pValue, 0.0001);
significant = (pooledData.pValue < alpha) & (pooledData.cohensD > 0);

stimulated = logical(pooledData.stimulatedChannels);


%create logical arrays for the stimulation conditions
condition(1,:) = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(1));
condition(2,:) = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(2:3));
condition(3,:) = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(4:5));
conditionNames = {'ACC','MCC','PCC'};

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

brainFieldnames = fieldnames(templateBrain.regions);

%% Prepare brain models for visualization
% Generate brain model without hippocampus/amygdala
hipAmygBool = contains(templateBrain.regionList, hipAmyg);
brainFieldnames2 = brainFieldnames(~hipAmygBool);

templateBrain2 = struct('regions', struct());
for i = 1:length(brainFieldnames2)
    templateBrain2.regions.(brainFieldnames2{i}) = templateBrain.regions.(brainFieldnames2{i});
end

% Create right and left hemisphere models
templateBrainRight = getOneSide(templateBrain2, 'right');
templateBrainRight = isolatePortionOfModel(templateBrainRight, 'x', 'less', 27);

templateBrainLeft = getOneSide(templateBrain, 'left');
templateBrainLeft = isolatePortionOfModel(templateBrainLeft, 'x', 'less', -15);

% Generate hippocampus/amygdala model
hipAmygFieldnames = brainFieldnames(hipAmygBool);
hipAmygTemplate = struct('regions', struct());
for i = 1:length(hipAmygFieldnames)
    hipAmygTemplate.regions.(hipAmygFieldnames{i}) = templateBrain.regions.(hipAmygFieldnames{i});
end
hipAmygTemplate = getOneSide(hipAmygTemplate, 'left');

% Generate insula model
insulaBool = contains(templateBrain.regionList, regionSort{strcmp(regionSort{:,3}, 'Insula'), 1});
insulaFieldnames = brainFieldnames(insulaBool);
insulaTemplate = struct('regions', struct());
for i = 1:length(insulaFieldnames)
   insulaTemplate.regions.(insulaFieldnames{i}) = templateBrain.regions.(insulaFieldnames{i});
end
insulaTemplateLeft = getOneSide(insulaTemplate, 'left');


%% % significant responses CohD



for c = 1:size(condition,1) % iterate through each condition


figure('Position',[38         188        3397         946]);
for r = 1:length(brainFieldnames)
curRegion = templateBrain.regionList{r};
curRegionIDX = contains([pooledData.electrodeRegionLabel{:}],curRegion);

curIDXSig = curRegionIDX & condition(c,:) & significant;
curIDXAll = curRegionIDX & condition(c,:);
percentageSig(c,r) = sum(curIDXSig)/sum(curIDXAll);

if sum(curRegionIDX) == 0
    storeNoCoverage(r) = 1;
else 
    storeNoCoverage(r) = 0;
end
end

Alphas = percentageSig(c,:);
Nan = isnan(Alphas);
noCover = logical(storeNoCoverage);

if c ==1
    curMap = getColors('lush lilac gradient');
elseif c == 2
    curMap = getColors('celadon porcelain gradient');
else
    curMap = getColors('lago blue gradient');
end

[~,~,Colors] = electrodeEffectSizes(Alphas,curMap,1.5,4,[0.8,0.8,0.8]);
Colors = mapEffectSizesToColors(Alphas, curMap, 'to range', [0 1]);

Colors(Nan,:) = 0.4;
Colors(noCover,:) = 0.4;

subplot(1,5,1)
[surface] = plotProjectedRegionsOnly(templateBrainLeft,Colors);
view([270,0])

subplot(1,5,2)
[surface] = plotProjectedRegionsOnly(templateBrainRight,Colors);
view([270,0])

subplot(1,5,3)
insulaColors = Colors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulaColors);
view([270,0])

subplot(1,5,4)
hipAmygColors = Colors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])

subplot(1,5,5)
hipAmygColors = Colors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])
saveas(gcf,[saveDir conditionNames{c} '_percentSignificantCohD.png'])

figure();
ax = axes;
colorbar(ax)
colormap(curMap)
text(.5,.5,num2str(max(Alphas)),'Units','normalized')
axis off
saveas(gcf,[saveDir conditionNames{c} '_percentSignificantCohDLegend.svg'])

end

saveResults.regionNames = templateBrain.regionList;
saveResults.percentageSignificantACC = percentageSig(1,:);
saveResults.percentageSignificantMCC = percentageSig(2,:);
saveResults.percentageSignificantPCC = percentageSig(3,:);
appendLog(['Supp Fig 1 Sig. Coherence'], [': percentage of significantly coherent responses in contacts for each region' ], saveResults)
clear saveResults;

%% % significant responses RMS


% get logical array for significant responses
alpha = calculateAlphaThreshold(pooledData.RMSP, 0.0001);
significant = (pooledData.RMSP < alpha) & (pooledData.RMS > 0);



for c = 1:size(condition,1) % iterate through each condition


figure('Position',[38         188        3397         946]);
for r = 1:length(brainFieldnames)
curRegion = templateBrain.regionList{r};
curRegionIDX = contains([pooledData.electrodeRegionLabel{:}],curRegion);

curIDXSig = curRegionIDX & condition(c,:) & significant;
curIDXAll = curRegionIDX & condition(c,:);
percentageSig(c,r) = sum(curIDXSig)/sum(curIDXAll);

if sum(curRegionIDX) == 0
    storeNoCoverage(r) = 1;
else 
    storeNoCoverage(r) = 0;
end
end

Alphas = percentageSig(c,:);
Nan = isnan(Alphas);
noCover = logical(storeNoCoverage);

if c ==1
    curMap = getColors('lush lilac gradient');

elseif c == 2
    curMap = getColors('celadon porcelain gradient');
else
    curMap = getColors('lago blue gradient');
end

[~,~,Colors] = electrodeEffectSizes(Alphas,curMap,1.5,4,[0.8,0.8,0.8]);

Colors(Nan,:) = 0.4;
Colors(noCover,:) = 0.4;

subplot(1,5,1)
[surface] = plotProjectedRegionsOnly(templateBrainLeft,Colors);
view([270,0])

subplot(1,5,2)
[surface] = plotProjectedRegionsOnly(templateBrainRight,Colors);
view([270,0])

subplot(1,5,3)
insulaColors = Colors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulaColors);
view([270,0])

subplot(1,5,4)
hipAmygColors = Colors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])

subplot(1,5,5)
hipAmygColors = Colors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])
saveas(gcf,[saveDir conditionNames{c} '_percentSignificantRMS.png'])


figure();
ax = axes;
colorbar(ax)
colormap(curMap)
text(.5,.5,num2str(max(Alphas)),'Units','normalized')
axis off
saveas(gcf,[saveDir conditionNames{c} '_percentSignificantRMSALegend.svg'])

end

saveResults.regionNames = templateBrain.regionList;
saveResults.percentageSignificantACC = percentageSig(1,:);
saveResults.percentageSignificantMCC = percentageSig(2,:);
saveResults.percentageSignificantPCC = percentageSig(3,:);
appendLog('Supp Fig 1 Sig. RMS', [': percentage of significant responses by magnitude in contacts for each region' ], saveResults)
clear saveResults;

%% for  figure components of figure 6
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
saveDir = 'figures/main/figure6/dependencies/jett/';
mkdir(saveDir);

% get logical array for significant responses
alpha = calculateAlphaThreshold(pooledData.pValue, 0.0001);
alphaG = calculateAlphaThreshold(pooledData.gammaP, 0.0001);
significant = (pooledData.pValue < alpha) & (pooledData.cohensD > 0);
significantG = pooledData.gammaP < alphaG;

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
    getColors('celadon porcelain');
    getColors('lago blue')];

% initialize variables
leftHStim = contains([pooledData.stimulatedRegion{:}],'_lh_');
rightHStim = contains([pooledData.stimulatedRegion{:}],'_rh_');

leftHRec = pooledData.electrodeCoordinates(1,:) < 0;
rightHRec = pooledData.electrodeCoordinates(1,:) > 0;

sigChannelsIDX = find(pooledData.pValue < alpha);
stimRegion = [pooledData.stimulatedRegion{sigChannelsIDX}]; 

%index groups for each subregion of the cingulate
idx.lACC = find(ismember(stimRegion,leftACC));
idx.rACC = find(ismember(stimRegion,rightACC));
idx.lMCC = find(ismember(stimRegion,leftMCC));
idx.rMCC = find(ismember(stimRegion,rightMCC));
idx.lPCC = find(ismember(stimRegion,leftPCC));
idx.rPCC = find(ismember(stimRegion,rightPCC));

brainFieldnames = fieldnames(templateBrain.regions);

aColor = getColors('lush lilac');
mColor = getColors('celadon porcelain');
pColor = getColors('lago blue');

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

%% gamma + ccep
for c = 1:size(condition,1) % iterate through each condition


figure('Position',[38         188        3397         946]);
for r = 1:length(brainFieldnames)
curRegion = templateBrain.regionList{r};
curRegionIDX = contains([pooledData.electrodeRegionLabel{:}],curRegion);

curIDXSig = curRegionIDX & condition(c,:) & significant & significantG;
gamma(c,r) = nanmean(pooledData.gammaRho(curIDXSig));

        if (c==1) && any(contains(cingulateNamesSimple(1),templateBrain.regionList{r}))
        gamma(c,r) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif (c==2) && any(contains(cingulateNamesSimple(2:3),templateBrain.regionList{r}))
        gamma(c,r) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif (c==3) && any(contains(cingulateNamesSimple(4:5),templateBrain.regionList{r}))
        gamma(c,r) = nan;% set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        end

if sum(curRegionIDX) == 0
    storeNoCoverage(r) = 1;
else 
    storeNoCoverage(r) = 0;
end

end

% caluclate percentage of responses with significant gamma

percent(c) = sum(condition(c,:) & significant & significantG)/sum(condition(c,:) & significant);
count(c,1) = sum(condition(c,:) & significant);
count(c,2) = sum(condition(c,:) & significant & significantG);

Alphas = gamma(c,:);
Nan = isnan(Alphas);
noCover = logical(storeNoCoverage);

%Colors = mapEffectSizesToColors(Alphas, getColors('modern blue to muted brick gradient'), 'to range', [-.4 .4]);
Colors = mapEffectSizesToColors(Alphas, colormap('parula'), 'to range', [-.4 .4]);

Colors(Nan,:) = 0.8;
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

saveas(gcf,[saveDir conditionNames{c} '_CCEPandGamma.png'])

figure();
ax = axes;
colorbar(ax)
colormap('parula')
text(.5,.5,['longest = ' num2str(max(Alphas)) 'shortest = ' num2str(min(Alphas))],'Units','normalized')
axis off
clim([-.4 .4])
saveas(gcf,[saveDir conditionNames{c} '_CCEPandGammaLegend.svg'])

figure('Position',[1440         818        1471         420]);
scatterDistribution1D(pooledData.responseDurationByAbruptChanges(condition(c,:) & significant),[],.1,.3,30,regionColorsCC(c,:)) %figure for whole distribution of channels
box off
saveas(gcf,[saveDir conditionNames{c} '_CCEPandGammaChannels.svg'])

figure('Position',[1440         818        1471         420]);
scatterDistribution1D(Alphas,[],.1,.3,30,regionColorsCC(c,:))
box off
saveas(gcf,[saveDir conditionNames{c} '_CCEPandGammaRegions.svg'])

end

saveResults.labels = brainFieldnames;
saveResults.ACCGamma = gamma(1,:);
saveResults.MCCGamma = gamma(2,:);
saveResults.PCCGamma = gamma(3,:);
saveResults.conditionsContactCount = {'ACC','MCC','PCC'};
saveResults.significantCCEPCount = count(:,1);
saveResults.significantGamma = count(:,2);
saveResults.percentSigGamma = count(:,2)./count(:,1);

appendLog('Figure 6: evoked gamma resonse', 'evoked gamma responses for each region', saveResults)

%% bar plot to compare percentages
figure();
b = bar(count,'EdgeColor','none');

% Set face color to flat for both bars
for ii = 1:2
    b(ii).FaceColor = 'flat';
end

% Set alpha values 
b(1).FaceAlpha = 1.0;  
b(2).FaceAlpha = 0.5; 

% Map condition names to colors for both bars
for ii = 1:2
    for i = 1:3
        switch conditionNames{i}
            case 'ACC'
                b(ii).CData(i,:) = getColors('lush lilac');
            case 'MCC'
                b(ii).CData(i,:) = getColors('celadon porcelain');
            case 'PCC'
                b(ii).CData(i,:) = getColors('lago blue');
        end
    end
end
box off
title('significant vs significant with gamma')
saveas(gcf,[saveDir '_channelComparisonCCEPGamma.svg'])
%% gamma - ccep
for c = 1:size(condition,1) % iterate through each condition


figure('Position',[38         188        3397         946]);
for r = 1:length(brainFieldnames)
curRegion = templateBrain.regionList{r};
curRegionIDX = contains([pooledData.electrodeRegionLabel{:}],curRegion);

curIDXSig = curRegionIDX & condition(c,:) & ~significant & significantG;
curIDXAll = curRegionIDX & condition(c,:);
gamma(c,r) = nanmean(pooledData.gammaRho(curIDXSig));

        if (c==1) && any(contains(cingulateNamesSimple(1),templateBrain.regionList{r}))
        gamma(c,r) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif (c==2) && any(contains(cingulateNamesSimple(2:3),templateBrain.regionList{r}))
        gamma(c,r) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif (c==3) && any(contains(cingulateNamesSimple(4:5),templateBrain.regionList{r}))
        gamma(c,r) = nan;% set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        end

if sum(curRegionIDX) == 0
    storeNoCoverage(r) = 1;
else 
    storeNoCoverage(r) = 0;
end
end

% caluclate percentage of responses with significant gamma

percent(c) = sum(condition(c,:) & ~significant & significantG)/sum(condition(c,:) & significant & significantG);

count(c,1) = sum(condition(c,:) & ~significant & significantG);
count(c,2) = sum(condition(c,:) & significant & significantG);


Alphas = gamma(c,:);
Nan = isnan(Alphas);
noCover = logical(storeNoCoverage);

%Colors = mapEffectSizesToColors(Alphas, getColors('modern blue to muted brick gradient'), 'to range', [-.4 .4]);
Colors = mapEffectSizesToColors(Alphas, colormap('parula'), 'to range', [-.4 .4]);
Colors(Nan,:) = 0.8;
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

saveas(gcf,[saveDir conditionNames{c} '_GammaOnly.png'])


figure();
ax = axes;
colorbar(ax)
colormap('parula')
text(.5,.5,['longest = ' num2str(max(Alphas)) 'shortest = ' num2str(min(Alphas))],'Units','normalized')
axis off
clim([-.4 .4])
saveas(gcf,[saveDir conditionNames{c} '_GammaOnlyLegend.svg'])

figure('Position',[1440         818        1471         420]);
scatterDistribution1D(pooledData.responseDurationByAbruptChanges(condition(c,:) & significant),[],.1,.3,30,regionColorsCC(c,:)) %figure for whole distribution of channels
box off
saveas(gcf,[saveDir conditionNames{c} '_GammaOnlyChannels.svg'])

figure('Position',[1440         818        1471         420]);
scatterDistribution1D(Alphas,[],.1,.3,30,regionColorsCC(c,:))
box off
saveas(gcf,[saveDir conditionNames{c} '_GammaOnlyRegions.svg'])

end


%% bar plot to compare percentages
figure();
b = bar(count,'EdgeColor','none');

% Set face color to flat for both bars
for ii = 1:2
    b(ii).FaceColor = 'flat';
end

% Set alpha values
b(1).FaceAlpha = 1.0;  
b(2).FaceAlpha = 0.5;  

% Map condition names to colors for both bars
for ii = 1:2
    for i = 1:3
        switch conditionNames{i}
            case 'ACC'
                b(ii).CData(i,:) = getColors('lush lilac');
            case 'MCC'
                b(ii).CData(i,:) = getColors('celadon porcelain');
            case 'PCC'
                b(ii).CData(i,:) = getColors('lago blue');
        end
    end
end
box off
title('non-significant with gamma vs significant with gamma')
saveas(gcf,[saveDir '_channelComparisonNoCCEPGamma.svg'])


%% show exemplar spectrogram and gamma trace.

length_samples = 3800;
% Sampling rate
fs = 2000; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

[M,IList] = sort(pooledData.gammaRho,'descend');

gammaOnly = IList(~significant & significantG);
gammaCCEP = IList(significant & significantG);


%%
iG = gammaOnly(1);
iCG = gammaCCEP(3);

% preprocessed files to load:
gammaOnlyFile = load(pooledData.dataFileName{iG},'spesSmallLaplace');
gammaCCEPFile = load(pooledData.dataFileName{iCG},'spesSmallLaplace');
gammaChan = pooledData.channelNumber(iG);
gammaCCEPChan = pooledData.channelNumber(iCG);

%
gammaOnlySig = squeeze(gammaOnlyFile.spesSmallLaplace(gammaChan,:,:))';
gammaCCEPSig = squeeze(gammaCCEPFile.spesSmallLaplace(gammaCCEPChan,:,:))';

[tf, times, freqs] = computeTimeFreq(gammaOnlySig, 2000, 1:2:200);

% compute power and average across trials
power   = abs(tf).^2;                 
avgP    = squeeze(mean(power,1));   

% convert to dB
avgPdB  = 10*log10(avgP);

% plot
figure;
imagesc(times, freqs, avgPdB);         
axis xy;                               
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Average TFR (dB)');
colorbar;                              
colormap parula;                 

%% check hemispheric differences for gamma, Supplemental Fig 8

set(0, 'DefaultFigureRenderer', 'painters')
%format data for plotting functions
datIn = pooledData.gammaRho(sigChannelsIDX);
datIn(datIn == 0) = nan;
dataToPlot = groupData(datIn,idx);

%for violinplot function
colors = [aColor;mColor;pColor];
%generate offset of violin plots
offset = 0.05;
groups = [1-offset,1+offset,2-offset,2+offset,3-offset,3+offset];
medianLine = [];

left = [1,3,5];
right = [2,4,6];

figure('position',[72   805   935   479])

leftRightViolin(dataToPlot,groups,left,right,colors,offset)

xticklabels({'ACC','MCC','PCC'})
set(gca,'linewidth',.75, 'FontSize',24,'FontName','Helvetica')
ylabel('Gamma Response (Rho)')
box off
saveas(gcf,[saveDir '_gammaViolin_.svg'])

% run statistics on groups and display
a = dataToPlot(:,1:2);
m = dataToPlot(:,3:4);
p = dataToPlot(:,5:6);

am = ranksum(a(:),m(:))
ap = ranksum(a(:),p(:))
mp = ranksum(m(:),p(:))

aa = ranksum(dataToPlot(:,1),dataToPlot(:,2))
mm = ranksum(dataToPlot(:,3),dataToPlot(:,4))
pp = ranksum(dataToPlot(:,5),dataToPlot(:,6))

%% compare gamma statistics between regions

%% First, extract necessary data to feed into the figure generating engine, similar to the network figure in figure 2

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
regionsIDX = contains([pooledData.electrodeRegionLabel{:}],curRegions{r});
tempDistances(r) = mean(pooledData.electrodeCoordinates(2,regionsIDX));
end

%oranize and resort by rank, then amend table as needed 
[~,idx] = sort(tempDistances,'descend');
curRegions = curRegions(idx);
figureRegions.Name(curRegionsIDX) = curRegions;
end

%% remove any table entries where the region does not exist in the dataset.
close all
regions = unique([pooledData.electrodeRegionLabel{:}]);

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

% here, generate a set of tables that contain the information required for generating inner and outter circles
%figureRegions contains the necessary region names and region classes, the
%function that generates the circles will double all of the labels 
outerTable = figureRegions(~ismember(figureRegions.Name,cingulateNamesSimple),:);
innerTable = figureRegions(contains(figureRegions.Name,cingulateNamesSimple),:);

%change class labels for innerTable for stimulation conditions
innerTable.Class = {'ACC';'MCC';'MCC';'PCC';'PCC'};

%% create wiring figure
%generate necessary geometric resources to create the wiring figure
[outer, inner] = generateCircleNetworkPoints(15,3, 4, 12, outerTable, innerTable); %use a full circle diagram, then prune it to a half circle in the next few lines to ensure that indexing is consistent)

%%
removeIDXOuter = outer.rHemisphere == 0;
removeIDXInner = inner.rHemisphere == 0;
outer(removeIDXOuter,:) = [];
inner(removeIDXInner,:) = [];
inner = flip(inner);

%
[a,b,c] = generateNetworkPlotHalfCircle(outer, inner, pooledData, 'gammaRho', significant,'ipsi','jitter','jitterMagnitude',.02); %'offset',  'offsetStep', 0.005);
saveas(a,[saveDir 'ipsiLateralizationPlot.svg'])
saveas(b,[saveDir 'ipsiLateralizationPlotLegendBlue.svg'])
saveas(c,[saveDir 'ipsiLateralizationPlotLegendRed.svg'])

%
[a,b,c] = generateNetworkPlotHalfCircle(outer, inner, pooledData, 'gammaRho', significant,'contra','jitter','jitterMagnitude',.02); %'offset',  'offsetStep', 0.005);
saveas(a,[saveDir 'contraLateralizationPlot.svg'])
saveas(b,[saveDir 'contraLateralizationPlotLegendBlue.svg'])
saveas(c,[saveDir 'contraLateralizationPlotLegendRed.svg'])

%% generate statistical comparisons between major region groups, based on the figureRegions classes

lateralizationTableGamma = getHemiStats(outer, inner,pooledData, 'gammaRho', significant);
T = struct2table(lateralizationTableGamma);

writetable(T, [saveDir 'lateralizationTableGamma.xlsx'])

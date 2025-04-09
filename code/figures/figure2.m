%% for  figure components of figure 2
close all
clear
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

hipAmyg = [listAmyg,listHip];

regionSort = readtable('code/dependencies/regionCategories.xlsx');
saveDir = 'figures/main/figure2/dependencies/';
mkdir(saveDir);
% initialize variables
leftHStim = contains([pooledData.stimulatedRegion{:}],'_lh_');
rightHStim = contains([pooledData.stimulatedRegion{:}],'_rh_');

leftHRec = pooledData.electrodeCoordinates(1,:) < 0;
rightHRec = pooledData.electrodeCoordinates(1,:) > 0;

% get logical array for significant responses
alpha = calculateAlphaThreshold(pooledData.pValue, 0.0001);
significant = (pooledData.pValue < alpha) & (pooledData.cohensD > 0);

stimulated = logical(pooledData.stimulatedChannels);

%create logical arrays for the stimulation conditions
condition.AStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(1));
condition.MStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(2:3));
condition.PStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(4:5));

brainFieldnames = fieldnames(templateBrain.regions);

sigChannelsIDX = find(pooledData.pValue < alpha);
stimRegion = [pooledData.stimulatedRegion{sigChannelsIDX}]; 

%index groups for each subregion of the cingulate
idx.lACC = find(ismember(stimRegion,leftACC));
idx.rACC = find(ismember(stimRegion,rightACC));
idx.lMCC = find(ismember(stimRegion,leftMCC));
idx.rMCC = find(ismember(stimRegion,rightMCC));
idx.lPCC = find(ismember(stimRegion,leftPCC));
idx.rPCC = find(ismember(stimRegion,rightPCC));

%initialize colors
aColor = getColors('lush lilac');
mColor = getColors('celadon porcelain');
pColor = getColors('lago blue');

%% Figure 2b-2c %%%%%%%
%methods and exempar distributions of connectivity factor (cohen's D) note
%that Figure 2a was generated manually using illustrator and a few exemplar
%CCEPs plotted from pooledData.cceps

%% This section of code generates the histogram plots in Figure 2. Each plot can be generated

%first, generate a set of exemplars using the largest effect sizes:
sigIDX = [];
count = 0;
while length(sigIDX) < 30
count = count + 1;
sigIDX = intersect(find(pooledData.pValue < 0.05/length(pooledData.pValue)), find(pooledData.cohensD > min(maxk(pooledData.cohensD,count)))); %find significant channels
end
% for exemplars, sigIDX used = 6 for ACC, 20 for MCC, 14 for PCC

exemplarIDX = [1,6,20,14]; %these are exemplar indexes corresponding to:
exemplarNames = {'Method','ACC','MCC','PCC'};
exemplarColors = {'modern orange','lush lilac','celadon porcelain','lago blue'};

for i = 1:length(exemplarIDX)

testData = pooledData.CCEPs(:,sigIDX(exemplarIDX(i)));
channelNum = pooledData.channelNumber(sigIDX(exemplarIDX(i)));
import = load(pooledData.dataFileName{sigIDX(exemplarIDX(i))});
%
import2 = load(pooledData.coherenceFileName{sigIDX(exemplarIDX(i))});
%
data = import.spesSmallLaplaceZScore;
%
cohB = import2.coherenceStruct.baseline;
cohT = import2.coherenceStruct.task;
%
figure('Position',[2346         575         740         601]);
histogram(cohB(channelNum,:),25,'FaceColor','k','FaceAlpha',0.5,'BinWidth',0.025)
hold on
histogram(cohT(channelNum,:),25,'FaceColor',getColors(exemplarColors{i}),'FaceAlpha',0.7,'BinWidth',0.025)

ylabel('Count')

ylim([0 60])
yticks([0,20,40,60])
xlim([-.75 1])

set(gca,'fontsize',18,'FontName','Helvetica','XColor','k','YColor','k','LineWidth',0.75)
box off

saveas(gcf,[saveDir exemplarNames{i} '_coherenceDistribution_.svg'])
end
%% FIGURE 2d %%%%%%%%%%%%%%%%
%General plot showing the relationship between coherence and RMS, and the
%one-dimensional scatter plot showing significant vs non-significant
%responses 

%%

figure('position',[452         697        1157         297]);
scatterDistribution1D(pooledData.cohensD(~significant),pooledData.cohensD,.1,.3,0.05,[0,0,0])
hold on
scatterDistribution1D(pooledData.cohensD(significant & ~stimulated),pooledData.cohensD,.1,.3,0.05,[1,0,0])
xlabel('Cohen''s D');
set(gca,'ytick',[]);
set(gca,'ycolor','none')
box off
[X,Y,T,AUC] = perfcurve(significant & ~stimulated, pooledData.cohensD,1);

% Compute Youden's index for each threshold
youdenIndex = Y - X;

% Find the index of the maximum Youden's index
[~, optimalIdx] = max(youdenIndex);

% Get the corresponding optimal threshold on the original score axis
O = T(optimalIdx);

title(['AUC ' num2str(AUC) ' ' 'OT ' num2str(O)])
saveas(gcf,[saveDir '_coherenceDistributionSignificantResponses_.svg'])


figure();
scatter(pooledData.cohensD,pooledData.RMS,'MarkerFaceColor','k','MarkerEdgeColor','none','MarkerFaceAlpha',0.1)
hold on
[r,p] = corr(pooledData.cohensD',pooledData.RMS','Type','Spearman');

pf = polyfit(pooledData.cohensD,pooledData.RMS, 1);
px = [min(pooledData.cohensD) max(pooledData.cohensD)];
py = polyval(pf, px);
plot(px, py, 'LineWidth', 1.5,'Color','r');
text(0,.75,['p = ' num2str(p) newline 'r = ' num2str(r)],'Units','normalized','LineWidth',2)
box off
axis square
xlabel('Cohens D')
ylabel('RMS')
saveas(gcf,[saveDir '_rmsCohDCorr_.svg'])

alphaRMS = calculateAlphaThreshold(pooledData.RMSP, 0.0001);
significantRMS = (pooledData.pValue < alpha) & (pooledData.cohensD > 0);

figure('position',[452         697        1157         297]);
scatterDistribution1D(pooledData.RMS(~significantRMS),pooledData.RMS,.1,.3,0.05,[0,0,0])
hold on
scatterDistribution1D(pooledData.RMS(significantRMS & ~stimulated),pooledData.RMS,.1,.3,0.05,[1,0,0])
xlabel('RMS');
set(gca,'ytick',[]);
set(gca,'ycolor','none')
box off
[X,Y,T,AUC] = perfcurve(significantRMS & ~stimulated, pooledData.RMS,1);
youdenIndex = Y - X;

% Find the index of the maximum Youden's index
[~, optimalIdx] = max(youdenIndex);

% Get the corresponding optimal threshold on the original score axis
O = T(optimalIdx);
title(['AUC ' num2str(AUC) ' ' 'OT ' num2str(O)])
saveas(gcf,[saveDir '_rmsDistributionSignificantResponses_.svg'])


%% FIGURE 2e %%%%%%%%%%%%%%%%
%violin plots showing the distributions of data for coherence and for
%variance. Note that these plot functions require the violinplot matlab
%commmunity package downloaded from :https://github.com/bastibe/Violinplot-Matlab

%% First visualize violin plots of coherence and Variance

set(0, 'DefaultFigureRenderer', 'painters')
%format data for plotting functions
datIn = pooledData.cohensD(sigChannelsIDX);
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
ylabel('Coherence (Rho)')
box off
saveas(gcf,[saveDir '_coherenceViolin_.svg'])

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

%format data for plotting functions

figure('position',[72   805   935   479])
datIn = pooledData.variance(sigChannelsIDX);
datIn(datIn == 0) = nan;
dataToPlot = groupData(datIn,idx);

leftRightViolin(dataToPlot,groups,left,right,colors,offset)

xticklabels({'ACC','MCC','PCC'})

set(gca,'linewidth',.75, 'FontSize',24,'FontName','Helvetica')
ylabel('Variance')
box off

saveas(gcf,[saveDir '_coherenceVarViolin_.svg'])

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


%% Figure 2f %%%%%%%%%
%network wiring plot showing the wiring diagram of each subregion of the cingulate
%cortex

%% First, extract necessary data to feed into the figure generating engine

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

regions = unique([pooledData.electrodeRegionLabel{:}]);

%since data labels contain more characters than table labels, we will have
%to loop through and use the contains function for each individual element.
%Also, do not include the cingul-Marginalis as part of this divergent
%connectivity figure since it is not one of the regions of interest.
count = 1;
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
[outer, inner] = generateCircleNetworkPoints(15,3, 4, 12, outerTable, innerTable);
generateNetworkPlot(outer, inner, pooledData, 'cohensD', significant,'jitter','jitterMagnitude',.02); %'offset',  'offsetStep', 0.005);

saveas(gcf,'/Volumes/Samsung_T5/cingulateConnectivity/figures/main/figure2/dependencies/network.svg')

%% Figure 2g %%%%%%%%
% 3d brain models of all regions that have known shared connectivity with
% all 3 subregions, and their relative connectivity to each subregion

%% color coding each region by relative and absolute connectivity-> for each region, store the color of the region

%using Cohen's D, generate a set of colors and triangular coordinates that
%correspond to the geometric mean of each region given the 3 above
%conditions
colors = [];
coordinates = [];
numSubjects = [];
includedRegion = logical([]);
percentSignficant = [];
equalRegionColors = [];

for i = 1:length(templateBrain.regionList)
    %find all channels within the brain region
    curRegion = contains([pooledData.electrodeRegionLabel{:}],templateBrain.regionList{i});

    %check number of subjects with coverage in this region
    numSubjects(i) = length(unique(pooledData.subjectID(curRegion)));

    %generate logical arrays for each condition, meeting significance,
    %within current region
    if ~any(curRegion)% check to see if any coverage exists (white if there is no color)
    colors(i,:) = hex2rgb('74C9B5'); %use a distinct color to mark no-coverage areas to turn into cross-hatch in illustrator
    coordinates(i,:) = [nan,nan]; 
    includedRegion(i) = 0;
    
    else
    tempACC = condition.AStim & curRegion & significant & ~stimulated;
    tempMCC = condition.MStim & curRegion & significant & ~stimulated;
    tempPCC = condition.PStim & curRegion & significant & ~stimulated;

    %get logical array for condition, but without a significant response.
    %Use this to determine whether there is coverage in all conditions
    tempACCns = condition.AStim & curRegion & ~significant & ~stimulated;
    tempMCCns = condition.MStim & curRegion & ~significant & ~stimulated;
    tempPCCns = condition.PStim & curRegion & ~significant & ~stimulated;

    percentSignificant(1,i) = sum(tempACC)/(sum(tempACC) + sum(tempACCns)); %percentage of singificant observations
    percentSignificant(2,i) = sum(tempMCC)/(sum(tempMCC) + sum(tempMCCns)); %percent of significant observations
    percentSignificant(3,i) = sum(tempPCC)/(sum(tempPCC) + sum(tempPCCns));

    % check to make sure at least one value exists for each of the three
    % above groups, for other regions of the singulate check the other two
    % regions, and ignore
    if all([any(tempACC),any(tempMCC),any(tempPCC)]) && ~any(contains(cingulateNamesSimple,templateBrain.regionList{i}))
    % generate a triangular geometric mean to assign color
    a = nanmean(pooledData.cohensD(tempACC));
    m = nanmean(pooledData.cohensD(tempMCC));
    p = nanmean(pooledData.cohensD(tempPCC));

        if any(contains(cingulateNamesSimple(1),templateBrain.regionList{i}))
        a = 0;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif any(contains(cingulateNamesSimple(2:3),templateBrain.regionList{i}))
        m = 0;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif any(contains(cingulateNamesSimple(4:5),templateBrain.regionList{i}))
        p = 0;% set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        end
        values = [a,m,p];
        [colors(i,:),coordinates(i,:)] = triangularGeoMean(values,'off',getColors('cyan magenta yellow'));
        includedRegion(i) = 1;
    
    % for conditions where at least one region is significant and the
    % others are not
    elseif any([any(tempACC), any(tempMCC), any(tempPCC)]) && ~any(contains(cingulateNamesSimple,templateBrain.regionList{i})) && all([any(tempACC | tempACCns), any(tempMCC | tempMCCns), any(tempPCC | tempPCCns)])

        %if any of the regions contain significant responses, check to make
        %sure that the other two 
        a = nanmean(pooledData.cohensD(tempACC));
        m = nanmean(pooledData.cohensD(tempMCC));
        p = nanmean(pooledData.cohensD(tempPCC));

        values = [a,m,p];
        values(isnan(values)) = 0;
        [colors(i,:),coordinates(i,:)] = triangularGeoMean(values,'off',getColors('cyan magenta yellow'));
        includedRegion(i) = 1;
        
    %condition where current region is ACC, MCC, or PCC, check if coverage
    %exists for the other two regions
    elseif any(contains(cingulateNamesSimple(1),templateBrain.regionList{i})) && all([any(tempMCC),any(tempPCC)])
        a = 0;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        m = nanmean(pooledData.cohensD(tempMCC));
        p = nanmean(pooledData.cohensD(tempPCC));
        values = [a,m,p];
        [colors(i,:),coordinates(i,:)] = triangularGeoMean(values,'off',getColors('cyan magenta yellow'));
        includedRegion(i) = 1;
    elseif any(contains(cingulateNamesSimple(2:3),templateBrain.regionList{i})) && all([any(tempACC),any(tempPCC)])
        a = nanmean(pooledData.cohensD(tempACC));%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        m = 0;
        p = nanmean(pooledData.cohensD(tempPCC));
        values = [a,m,p];
        [colors(i,:),coordinates(i,:)] = triangularGeoMean(values,'off',getColors('cyan magenta yellow'));
        includedRegion(i) = 1;
    elseif any(contains(cingulateNamesSimple(4:5),templateBrain.regionList{i})) && all([any(tempACC),any(tempMCC)])
        a = nanmean(pooledData.cohensD(tempACC));%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        m = nanmean(pooledData.cohensD(tempMCC));
        p = 0;
        values = [a,m,p];
        [colors(i,:),coordinates(i,:)] = triangularGeoMean(values,'off',getColors('cyan magenta yellow'));
        includedRegion(i) = 1;
    
    %condition where coverage in at least one stim condition, but not all
    elseif any([any(tempACC | tempACCns), any(tempMCC | tempMCCns), any(tempPCC | tempPCCns)]) && ~all([any(tempACC | tempACCns), any(tempMCC | tempMCCns), any(tempPCC | tempPCCns)])
    % assign grey as the color
    colors(i,:) = [0.85,0.85,0.85];
    coordinates(i,:) = [nan,nan];
    includedRegion(i) = 0;
    
    %condition where no significant responses occur
    elseif ~any([tempACC, tempMCC, tempPCC])
    colors(i,:) = [0,0,0];
    coordinates(i,:) = [nan,nan];
    includedRegion(i) = 0;
    end


    end

        %check to see if coordinate is in the center of the triangle- ie
    %equally connected to all 3 subregions

    centroid = mean([0 0; 1 0; 0.5 (sqrt(3)/2)],1);

    d = sqrt(sum((coordinates(i,:)-centroid).^2));
    
    if d <= .08
        equalRegionColors(i,:) = getColors('modern orange');
    else
        equalRegionColors(i,:) = [0.8,0.8,0.8];
    end

end

%%
%plot figure using colors
figure('Position',[281          32        3060        1260]);
templateBrainLeft = getOneSide(templateBrain,'left');
% adjust model to remove parts from a midsection so that they do not appear
% on the sagital figure
templateBrainLeft = isolatePortionOfModel(templateBrainLeft,'x','less',-15);
[surface] = plotProjectedRegionsOnly(templateBrainLeft,colors);
view([270,0])

saveas(gcf,[saveDir 'relativeConnectivity1.svg'])
saveas(gcf,[saveDir 'relativeConnectivity1.png'])

%
figure('Position',[281          32        3060        1260]);

% generate brain without a hippocampus
hipAmygBool = contains(templateBrain.regionList,hipAmyg);%hip/amyg fieldnames already exist in a separate .mat file
brainFieldnames2 = brainFieldnames(~hipAmygBool);
rightColors = colors(~hipAmygBool,:);
included = includedRegion(~hipAmygBool);

for i = 1:length(brainFieldnames2)

    templateBrain2.regions.(brainFieldnames2{i}) = templateBrain.regions.(brainFieldnames2{i});

end

%for using a right brain model, show the midsection and remove regions from
%sagittal view
templateBrainRight = getOneSide(templateBrain2,'right');
templateBrainRight = isolatePortionOfModel(templateBrainRight,'x','less',27);
[surface] = plotProjectedRegionsOnly(templateBrainRight,rightColors);
view([270,0])
saveas(gcf,[saveDir 'relativeConnectivity2.svg'])
saveas(gcf,[saveDir 'relativeConnectivity2.png'])

%

%Get view of insula
%get insula colors 
insulaBool = contains(templateBrain.regionList,regionSort{strcmp(regionSort{:,3},'Insula'),1}); %extract insula fieldnames from table
insulaColors = colors(insulaBool,:);
insulaFieldnames = brainFieldnames(insulaBool); %ensure that fieldnames are ordered accordingly 
%index insula subregions and generate an insula struct
for i = 1:length(insulaFieldnames)
   insulaTemplate.regions.(insulaFieldnames{i}) = templateBrain.regions.(insulaFieldnames{i});
end
insulaTemplateLeft = getOneSide(insulaTemplate,'left');
figure('Position',[281          32        3060        1260]);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulaColors);
view([270,0])
saveas(gcf,[saveDir 'relativeConnectivityIns.svg'])
saveas(gcf,[saveDir 'relativeConnectivityIns.png'])

% generate model of the hippocampus 
hipAmygBool = contains(templateBrain.regionList,hipAmyg);%hip/amyg fieldnames already exist in a separate .mat file
hipAmygFieldnames = brainFieldnames(hipAmygBool);
hipAmygColors = colors(hipAmygBool,:);
includedHA = includedRegion(hipAmygBool);

%make new struct for hipp and amyg
for i = 1:length(hipAmygFieldnames)

    hipAmygTemplate.regions.(hipAmygFieldnames{i}) = templateBrain.regions.(hipAmygFieldnames{i});

end
hipAmygTemplate = getOneSide(hipAmygTemplate,'left');
figure('Position',[281          32        3060        1260]);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
alphaIDXHA = find(includedHA == 0);
view([-176.4 -90.0])
saveas(gcf,[saveDir 'relativeConnectivityHip1.svg'])
saveas(gcf,[saveDir 'relativeConnectivityHip1.png'])
view([-180.8 73.9])
saveas(gcf,[saveDir 'relativeConnectivityHip2.svg'])
saveas(gcf,[saveDir 'relativeConnectivityHip2.png'])

% generate color legend and pointset 
figure('Position',[281          32        3060        1260]);
% Define vertices of the triangle
vertices = [0 0; 1 0; 0.5 (sqrt(3)/2)];
faces = [1 2 3];
vertexColors = getColors('cyan magenta yellow');
hold on;
% Plot the triangle with interpolated colors
h = patch('Faces', faces, 'Vertices', vertices, 'FaceVertexCData', vertexColors, ...
          'FaceColor', 'interp', 'EdgeColor', 'none');
for i = 1:length(coordinates)
hold on;
plot(coordinates(i,1), coordinates(i,2), 'ko', 'MarkerFaceColor', [0,0,0],'MarkerSize',15);
end
axis equal
axis off
saveas(gcf,[saveDir 'relativeConnectivityLegend.svg'])
saveas(gcf,[saveDir 'relativeConnectivityLegend.png'])


%% Now repeat for supplemental brain maps -> these will require 3 colors and an alpha value

%conditions
effectSizes = [];
effectVariation = [];
numSubjects = [];
includedRegion = logical([]);
percentSignificant = [];

%normalize cohens D across conditions


for i = 1:length(templateBrain.regionList)
    %find all channels within the brain region
    curRegion = contains([pooledData.electrodeRegionLabel{:}],templateBrain.regionList{i});
    
    if sum(curRegion) == 0
    
        storeZeros(i) = 1;

    else
        storeZeros(i) = 0;
    end
    %check number of subjects with coverage in this region
    numSubjects(i) = length(unique(pooledData.subjectID(curRegion)));

    %generate logical arrays for each condition, meeting significance,
    %within current region

    tempACC = condition.AStim & curRegion & significant & ~stimulated;
    tempMCC = condition.MStim & curRegion & significant & ~stimulated;
    tempPCC = condition.PStim & curRegion & significant & ~stimulated;

    effectSizes(i,1) = nanmean(pooledData.cohensD(tempACC));
    effectSizes(i,2) = nanmean(pooledData.cohensD(tempMCC));
    effectSizes(i,3) = nanmean(pooledData.cohensD(tempPCC));

    effectVariation(i,1) = nanstd(pooledData.cohensD(tempACC));
    effectVariation(i,2) = nanstd(pooledData.cohensD(tempMCC));
    effectVariation(i,3) = nanstd(pooledData.cohensD(tempPCC));

        if any(contains(cingulateNamesSimple(1),templateBrain.regionList{i}))
        effectSizes(i,1) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif any(contains(cingulateNamesSimple(2:3),templateBrain.regionList{i}))
        effectSizes(i,2) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif any(contains(cingulateNamesSimple(4:5),templateBrain.regionList{i}))
        effectSizes(i,3) = nan;% set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        end

        storeNoCoverage(i,:) = [0,0,0];

        if sum(condition.AStim & curRegion & ~stimulated) == 0
        storeNoCoverage(i,1) = 1;
        end
        if sum(condition.MStim & curRegion & ~stimulated) == 0
        storeNoCoverage(i,2) = 1;
        end
        if sum(condition.PStim & curRegion & ~stimulated) == 0
        storeNoCoverage(i,3) = 1;
        end

end

%%
%normalize each row so that maximum alpha can be assigned as between 0.2 and .7
aAlphas = effectSizes(:,1);
aNan = isnan(aAlphas); %store nan values to adjust to grey
storeZeros = logical(storeZeros);
noCover = logical(storeNoCoverage(:,1));

[~,~,aColors] = electrodeEffectSizes(aAlphas,getColors('lush lilac gradient'),1.5,4,[0.8,0.8,0.8]);
aColors(aNan,:) = 0.8;
aColors(noCover,:) = 0.4;
aColors(storeZeros,:) = 0.4;

%First Plot everything for ACC
figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainLeft,aColors);
view([270,0])

saveas(gcf,[saveDir 'connectivityACCCortex1.svg'])
saveas(gcf,[saveDir 'connectivityACCCortex1.png'])

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainRight,aColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityACCCortex2.svg'])
saveas(gcf,[saveDir 'connectivityACCCortex2.png'])

figure('Position',[281          32        3060        1260]);
insulaColors = aColors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulaColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityACCInsula.svg'])
saveas(gcf,[saveDir 'connectivityACCInsula.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = aColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])
saveas(gcf,[saveDir 'connectivityACCHip1.svg'])
saveas(gcf,[saveDir 'connectivityACCHip1.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = aColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])
saveas(gcf,[saveDir 'connectivityACCHip2.svg'])
saveas(gcf,[saveDir 'connectivityACCHip2.png'])

figure();
ax = axes;
colorbar(ax)
colormap(getColors('lush lilac gradient'))
axis off
saveas(gcf,[saveDir 'connectivityACCLegend.svg'])
saveas(gcf,[saveDir 'connectivityACCLegend.png'])

%MCC
mAlphas = effectSizes(:,2);
mNan = isnan(mAlphas);

noCover = logical(storeNoCoverage(:,2));
[~,~,mColors] = electrodeEffectSizes(mAlphas,getColors('celadon porcelain gradient'),1.5,4,[0.8,0.8,0.8]);
mColors(mNan,:) = 0.8;
mColors(noCover,:) = 0.4;
mColors(storeZeros,:) = 0.4;

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainLeft,mColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityMCCCortex1.svg'])
saveas(gcf,[saveDir 'connectivityMCCCortex1.png'])

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainRight,mColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityMCCCortex2.svg'])
saveas(gcf,[saveDir 'connectivityMCCCortex2.png'])

figure('Position',[281          32        3060        1260]);
insulmColors = mColors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulmColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityMCCInsula.svg'])
saveas(gcf,[saveDir 'connectivityMCCInsula.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = mColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])

saveas(gcf,[saveDir 'connectivityMCCHip1.svg'])
saveas(gcf,[saveDir 'connectivityMCCHip1.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = mColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])
saveas(gcf,[saveDir 'connectivityMCCHip2.svg'])
saveas(gcf,[saveDir 'connectivityMCCHip2.png'])

figure();
ax = axes;
colorbar(ax)
colormap(getColors('celadon porcelain gradient'))
axis off
saveas(gcf,[saveDir 'connectivityMCCLegend.svg'])
saveas(gcf,[saveDir 'connectivityMCCLegend.png'])

%PCC
pAlphas = effectSizes(:,3);
pNan = isnan(pAlphas);
noCover = logical(storeNoCoverage(:,3));

[~,~,pColors] = electrodeEffectSizes(pAlphas,getColors('lago blue gradient'),1.5,4,[0.8,0.8,0.8]);
pColors(pNan,:) = 0.8;
pColors(noCover,:) = 0.4;
pColors(storeZeros,:) = 0.4;

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainLeft,pColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityPCCCortex1.svg'])
saveas(gcf,[saveDir 'connectivityPCCCortex1.png'])

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainRight,pColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityPCCCortex2.svg'])
saveas(gcf,[saveDir 'connectivityPCCCortex2.png'])

figure('Position',[281          32        3060        1260]);
insulpColors = pColors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulpColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityPCCInsula.svg'])
saveas(gcf,[saveDir 'connectivityPCCInsula.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = pColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])
saveas(gcf,[saveDir 'connectivityPCCHip1.svg'])
saveas(gcf,[saveDir 'connectivityPCCHip1.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = pColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])
saveas(gcf,[saveDir 'connectivityPCCHip2.svg'])
saveas(gcf,[saveDir 'connectivityPCCHip2.png'])

figure();
ax = axes;
colorbar(ax)
colormap(getColors('lago blue gradient'))
axis off
saveas(gcf,[saveDir 'connectivityPCCLegend.svg'])
saveas(gcf,[saveDir 'connectivityPCCLegend.png'])

%all 3 cingulate regions
equalRegionColors(storeZeros,:) = 0.4;

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainLeft,equalRegionColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityEqualCortex1.svg'])
saveas(gcf,[saveDir 'connectivityEqualCortex1.png'])

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainRight,equalRegionColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityEqualCortex2.svg'])
saveas(gcf,[saveDir 'connectivityEqualCortex2.png'])

figure('Position',[281          32        3060        1260]);
insulpColors = equalRegionColors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulpColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityEqualInsula.svg'])
saveas(gcf,[saveDir 'connectivityEqualInsula.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = equalRegionColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])
saveas(gcf,[saveDir 'connectivityEqualHip1.svg'])
saveas(gcf,[saveDir 'connectivityEqualHip1.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = equalRegionColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])
saveas(gcf,[saveDir 'connectivityEqualHip2.svg'])
saveas(gcf,[saveDir 'connectivityEqualHip2.png'])

figure('Position',[281          32        3060        1260]);
% Define vertices of the triangle
vertices = [0 0; 1 0; 0.5 (sqrt(3)/2)];
faces = [1 2 3];
vertexColors = getColors('cyan magenta yellow');
hold on;
% Plot the triangle with interpolated colors
h = patch('Faces', faces, 'Vertices', vertices, 'FaceVertexCData', vertexColors, ...
          'FaceColor', [0.4,0.4,0.4], 'EdgeColor', 'none');
for i = 1:length(coordinates)
hold on;
if equalRegionColors(i,1) == 1
plot(coordinates(i,1), coordinates(i,2), 'ko', 'MarkerFaceColor', getColors('modern orange'),'MarkerEdgeColor','none', 'MarkerSize',40);
else
plot(coordinates(i,1), coordinates(i,2), 'ko', 'MarkerFaceColor', [0,0,0],'MarkerEdgeColor','none','MarkerSize',40);
end
end
axis equal
axis off
saveas(gcf,[saveDir 'connectivityEqualLegend.svg'])
saveas(gcf,[saveDir 'connectivityEqualLegend.png'])
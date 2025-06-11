%% for  figure components of figure 2
clear
addpath(genpath(cd))

%add PEABrain to handle 3dd modeling
addpath(genpath('/Volumes/Samsung_T5/PEABrain'));

pooledData = load('data/pooledData.mat');
load('data/compiledData.mat');
load('code/dependencies/templateBrain.mat');
load('code/dependencies/listHip.mat');
load('code/dependencies/listAmyg.mat');
load('code/dependencies/cingulateNames.mat');

hipAmyg = [listAmyg,listHip];

regionSort = readtable('code/dependencies/regionCategories.xlsx');
saveDir = 'figures/main/figure2/dependencies/rmsConnectivity/';
mkdir(saveDir);
% initialize variables
leftHStim = contains([pooledData.stimulatedRegion{:}],'_lh_');
rightHStim = contains([pooledData.stimulatedRegion{:}],'_rh_');

leftHRec = pooledData.electrodeCoordinates(1,:) < 0;
rightHRec = pooledData.electrodeCoordinates(1,:) > 0;

% get logical array for significant responses
alpha = calculateAlphaThreshold(pooledData.RMSP, 0.0001);
significant = (pooledData.RMSP < alpha) & (pooledData.RMS > 0);

stimulated = logical(pooledData.stimulatedChannels);

%create logical arrays for the stimulation conditions
condition.AStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(1));
condition.MStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(2:3));
condition.PStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(4:5));

brainFieldnames = fieldnames(templateBrain.regions);

sigChannelsIDX = find(pooledData.RMSP < alpha);
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
    a = nanmean(pooledData.RMS(tempACC));
    m = nanmean(pooledData.RMS(tempMCC));
    p = nanmean(pooledData.RMS(tempPCC));

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
        a = nanmean(pooledData.RMS(tempACC));
        m = nanmean(pooledData.RMS(tempMCC));
        p = nanmean(pooledData.RMS(tempPCC));

        values = [a,m,p];
        values(isnan(values)) = 0;
        [colors(i,:),coordinates(i,:)] = triangularGeoMean(values,'off',getColors('cyan magenta yellow'));
        includedRegion(i) = 1;
        
    %condition where current region is ACC, MCC, or PCC, check if coverage
    %exists for the other two regions
    elseif any(contains(cingulateNamesSimple(1),templateBrain.regionList{i})) && all([any(tempMCC),any(tempPCC)])
        a = 0;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        m = nanmean(pooledData.RMS(tempMCC));
        p = nanmean(pooledData.RMS(tempPCC));
        values = [a,m,p];
        [colors(i,:),coordinates(i,:)] = triangularGeoMean(values,'off',getColors('cyan magenta yellow'));
        includedRegion(i) = 1;
    elseif any(contains(cingulateNamesSimple(2:3),templateBrain.regionList{i})) && all([any(tempACC),any(tempPCC)])
        a = nanmean(pooledData.RMS(tempACC));%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        m = 0;
        p = nanmean(pooledData.RMS(tempPCC));
        values = [a,m,p];
        [colors(i,:),coordinates(i,:)] = triangularGeoMean(values,'off',getColors('cyan magenta yellow'));
        includedRegion(i) = 1;
    elseif any(contains(cingulateNamesSimple(4:5),templateBrain.regionList{i})) && all([any(tempACC),any(tempMCC)])
        a = nanmean(pooledData.RMS(tempACC));%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        m = nanmean(pooledData.RMS(tempMCC));
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
%% 
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

    effectSizes(i,1) = nanmean(pooledData.RMS(tempACC));
    effectSizes(i,2) = nanmean(pooledData.RMS(tempMCC));
    effectSizes(i,3) = nanmean(pooledData.RMS(tempPCC));

    effectVariation(i,1) = nanstd(pooledData.RMS(tempACC));
    effectVariation(i,2) = nanstd(pooledData.RMS(tempMCC));
    effectVariation(i,3) = nanstd(pooledData.RMS(tempPCC));

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

saveResults.regions = templateBrain.regionList;
saveResults.ACCCoherence = effectSizes(:,1);
saveResults.MCCCoherence = effectSizes(:,2);
saveResults.PCCCoherence = effectSizes(:,3);

appendLog('Sup Fig 3 RMS Across Conditions', 'average RMS across conditions', saveResults)
clear saveResults;

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
figure('Position',[38         188        3397         946]);
subplot(1,5,1)
[surface] = plotProjectedRegionsOnly(templateBrainLeft,aColors);
view([270,0])

subplot(1,5,2);
[surface] = plotProjectedRegionsOnly(templateBrainRight,aColors);
view([270,0])


subplot(1,5,3);
insulaColors = aColors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulaColors);
view([270,0])


subplot(1,5,4);
hipAmygColors = aColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])


subplot(1,5,5);
hipAmygColors = aColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])

saveas(gcf,[saveDir 'connectivityACC.png'])

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

figure('Position',[38         188        3397         946]);
subplot(1,5,1)
[surface] = plotProjectedRegionsOnly(templateBrainLeft,mColors);
view([270,0])

subplot(1,5,2);
[surface] = plotProjectedRegionsOnly(templateBrainRight,mColors);
view([270,0])

subplot(1,5,3);
insulmColors = mColors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulmColors);
view([270,0])

subplot(1,5,4);
hipAmygColors = mColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])

subplot(1,5,5);
hipAmygColors = mColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])
saveas(gcf,[saveDir 'connectivityMCC.png'])

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

figure('Position',[38         188        3397         946]);
subplot(1,5,1)
[surface] = plotProjectedRegionsOnly(templateBrainLeft,pColors);
view([270,0])

subplot(1,5,2);
[surface] = plotProjectedRegionsOnly(templateBrainRight,pColors);
view([270,0])

subplot(1,5,3);
insulpColors = pColors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulpColors);
view([270,0])

subplot(1,5,4);
hipAmygColors = pColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])

subplot(1,5,5);
hipAmygColors = pColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])
saveas(gcf,[saveDir 'connectivityPCC.png'])

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

%% Use this to identify the different hippocampus regions
figure('Position',[281          32        3060        1260]);
hipAmygColors = aColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])
fns = fieldnames(hipAmygTemplate.regions);

for i = 1:length(hipAmygColors)
    
    hipAmygColors(i,:) = [1,0,0];
    [surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
    hipAmygColors(i,:) = [.5,.5,.5];
    disp(fns(i))

end

%% show example cceps and their RMS vs COh's D, using HP_tail as an example

hipTail = contains([pooledData.electrodeRegionLabel{:}],hipAmyg);
%% for  figure components of figure 1
clear all
addpath(genpath(cd))
%%
load('data/pooledBrain.mat');
pooledData = load('data/pooledData.mat');
saveDir = 'figures/main/figure1/';
mkdir(saveDir);
%%
stimIDX = pooledData.stimulatedChannels == 1;

stimulatedChans = pooledData.electrodeCoordinates(:,stimIDX);
uniqueChans = unique(pooledData.electrodeCoordinates','rows','stable');

regionColors = [getColors('lush lilac');
    getColors('lago blue');
    getColors('celadon porcelain');
    getColors('celadon porcelain');
    getColors('lago blue');
    0.2,0.2,0.2;
    0.2,0.2,0.2];

electrodeColors = [1,0,0;
    1,0,0;
    1,0,0;
    1,0,0;
    1,0,0;
    0,0,0];

cingulateNamesSimple = {'G_and_S_cingul-Ant'
'G_and_S_cingul-Mid-Ant'
'G_and_S_cingul-Mid-Post'
'G_cingul-Post-dorsal'
'G_cingul-Post-ventral'};

whiteMatterNames = {'unknown','CSF','Right-Cerebral-White-Matter','Left-Cerebral-White-Matter','Right-Lateral-Ventricle','Left-Lateral-Ventricle','Unknown','WM-hypointensities'};
whiteMatterIDX = contains([pooledData.electrodeRegionLabel{:}],whiteMatterNames);
whiteMatterChans = pooledData.electrodeCoordinates(:,whiteMatterIDX)';
uniqueWMChans = unique(whiteMatterChans,'rows','stable');

cingulateChansIDX = contains([pooledData.electrodeRegionLabel{:}],cingulateNamesSimple);
cingulateChans = pooledData.electrodeCoordinates(:,cingulateChansIDX)';
uniqueCingulateChans = unique(cingulateChans,'rows','stable');

greyMatterChans = pooledData.electrodeCoordinates(:,(~whiteMatterIDX & ~cingulateChansIDX))';
uniqueGMChans = unique(greyMatterChans,'rows','stable');

cingulateRegions.regions = rmfield(cortOut.regions,'otherRegions');
%% plot whole brian coverage and electrode coverage

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(cortOut,regionColors);
for i = 1:length(surface)
surface(i).FaceAlpha = 0.5;
end
surface(6).FaceAlpha = 0.03;

hold on
plotBallsOnVolume(gca,uniqueCingulateChans,[1,0,0],1.5)
hold on
plotBallsOnVolume(gca,uniqueWMChans,[0.2,0.2,0.2],1.5)
hold on
plotBallsOnVolume(gca,uniqueGMChans,[0,0,0],1.5)

set(gca,'CameraViewAngleMode','Manual')
axis equal

zoom(1)
view([180 0])%for anterior view
saveas(gcf,[saveDir '_anterior.svg'])
saveas(gcf,[saveDir '_anterior.png'])

view([270,0])%for sagital
saveas(gcf,[saveDir '_sagital.svg'])
saveas(gcf,[saveDir '_sagital.png'])

view([-180,90])%for under coronal
saveas(gcf,[saveDir '_superior.svg'])
saveas(gcf,[saveDir '_superior.png'])

%% plot only the cingulate subregions with electrodes from this area

figure('Position',[281          32        3060        1260]);
[CCsurface] = plotProjectedRegionsOnly(cingulateRegions,regionColors);
for i = 1:length(CCsurface)
CCsurface(i).FaceAlpha = 0.3;
end

hold on

plotBallsOnVolume(gca,uniqueCingulateChans,[0,0,0],1.5)

hold on

plotBallsOnVolume(gca,stimulatedChans',[1,0,0],1.5)

set(gca,'CameraViewAngleMode','Manual')
axis equal

zoom(1)
view([180 0])%for anterior view
saveas(gcf,[saveDir '_CCanterior.svg'])
saveas(gcf,[saveDir '_CCanterior.png'])

view([270,0])%for sagital
saveas(gcf,[saveDir '_CCsagital.svg'])
saveas(gcf,[saveDir '_CCsagital.png'])

view([-180,90])%for under coronal
saveas(gcf,[saveDir '_CCsuperior.svg'])
saveas(gcf,[saveDir '_CCsuperior.png'])


%% plot 3D models with color corresponding to each region:
regionSort = readtable('code/dependencies/regionCategories.xlsx');
regionOrdered = {'Orbitofrontal cortex','Frontal Lobe','Cingulate cortex','Motor Cortex','Somatosensory Cortex','Operculum','Temporal Lobe','Hippocampus','Amygdala','Insula','Parietal Lobe','Occipital Lobe','Thalamus','White matter','Other'};

% sort table by brain region
[~,idx] = ismember(regionSort.Class, regionOrdered);
[~,sortIdx] = sort(idx);
sortedTable = regionSort(sortIdx,:);
regions = [sortedTable.Name];

for i = 1:length(regionOrdered)
currentRegion = regionOrdered(i);

currentListIDX = contains(sortedTable.Class,currentRegion);
currentList = sortedTable.Name(currentListIDX);

findChannels = contains([pooledData.electrodeRegionLabel{:}],currentList);
currentChannels = unique(pooledData.electrodeCoordinates(:,findChannels)','rows');
e{i} = currentChannels;
end

chanColorsTemp = getColors('vivid greyscale');

chanColors = [chanColorsTemp(1,:);
    chanColorsTemp(2,:);
    getColors('modern orange');
    chanColorsTemp(3,:);
    chanColorsTemp(3,:);
    chanColorsTemp(4,:);
    getColors('muted brick');
    chanColorsTemp(6,:);
    chanColorsTemp(7,:);
    chanColorsTemp(8,:);
    chanColorsTemp(10,:);
    chanColorsTemp(10,:);
    chanColorsTemp(14,:);
    [0.2,0.2,0.2];
    [0.2,0.2,0.2]];

regionColors2 = [getColors('modern blue');
    getColors('modern blue');
    getColors('modern blue');
    getColors('modern blue');
    getColors('modern blue');
    0.2,0.2,0.2];

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(cortOut,regionColors2);
for i = 1:length(surface)
surface(i).FaceAlpha = 0.1;
end
surface(6).FaceAlpha = 0.03;
    hold on
for i = 1:length(e)-1
curChans = e{i};
curColor = chanColors(i,:);
plotBallsOnVolume(gca,curChans,curColor,1.5);
end

set(gca,'CameraViewAngleMode','Manual')
axis equal

zoom(1)
view([180 0])%for anterior view
saveas(gcf,[saveDir '_anteriorColors.svg'])
saveas(gcf,[saveDir '_anteriorColors.png'])

view([270,0])%for sagital
saveas(gcf,[saveDir '_sagitalColors.svg'])
saveas(gcf,[saveDir '_sagitalColors.png'])

view([-180,90])%for under coronal
saveas(gcf,[saveDir '_superiorColors.svg'])
saveas(gcf,[saveDir '_superiorColors.png'])
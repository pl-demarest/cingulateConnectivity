%% for  all figures in figure 1
% Figure 1 will outline the methodology of the experiemntt, the coverage of
% electrodes within the subject population, the area of stimulation across
% the region of interest( cingulate cortex), and provide exemplar plots of
% CCEPs

clear all
addpath(genpath(cd))
load('data/pooledBrain.mat');
pooledData = load('data/pooledData.mat');
saveDir = 'figures/main/figure1/dependencies/';
mkdir(saveDir);
%% Initialize Variables
% identify datapoints of sitmulating channels
stimIDX = pooledData.stimulatedChannels == 1;
stimulatedChans = pooledData.electrodeCoordinates(:,stimIDX); 

% obtain all unique channels, as for the same subject, mulitiple channes
% exist across multiple stimulation locations, only return a list of unique
% channels across patient population
uniqueChans = unique(pooledData.electrodeCoordinates','rows','stable');

% view pooledBrain variable and select colors of each region
regionColorsCC = [getColors('lush lilac');
    getColors('lago blue');
    getColors('celadon porcelain');
    getColors('celadon porcelain');
    getColors('lago blue');
    0.2,0.2,0.2;
    0.2,0.2,0.2];

% view pooledBrain variable and select colors of electrodes within each
% region
electrodeColors = [1,0,0;
    1,0,0;
    1,0,0;
    1,0,0;
    1,0,0;
    0,0,0];

%initialize names of cingulate cortex for downstream indexing
cingulateNamesSimple = {'G_and_S_cingul-Ant'
'G_and_S_cingul-Mid-Ant'
'G_and_S_cingul-Mid-Post'
'G_cingul-Post-dorsal'
'G_cingul-Post-ventral'};

% identify channels within white matter 
whiteMatterNames = {'unknown','CSF','Right-Cerebral-White-Matter','Left-Cerebral-White-Matter','Right-Lateral-Ventricle','Left-Lateral-Ventricle','Unknown','WM-hypointensities'};
whiteMatterIDX = contains([pooledData.electrodeRegionLabel{:}],whiteMatterNames);
whiteMatterChans = pooledData.electrodeCoordinates(:,whiteMatterIDX)';
uniqueWMChans = unique(whiteMatterChans,'rows','stable');

% identify channels in the cingulate cortex, and return a unique list of
% channels in the cingulate cortex
cingulateChansIDX = contains([pooledData.electrodeRegionLabel{:}],cingulateNamesSimple);
cingulateChans = pooledData.electrodeCoordinates(:,cingulateChansIDX)';
uniqueCingulateChans = unique(cingulateChans,'rows','stable');

% identify and return all other channels
greyMatterChans = pooledData.electrodeCoordinates(:,(~whiteMatterIDX & ~cingulateChansIDX))';
uniqueGMChans = unique(greyMatterChans,'rows','stable');

% create a new structure that only contains the cingulate regions 
cingulateRegions.regions = rmfield(cortOut.regions,'otherRegions');

% SOrt and initialize order of brain regions for color assignment
regionSort = readtable('code/dependencies/regionCategories.xlsx');
regionOrdered = {'Orbitofrontal cortex','Frontal Lobe','Cingulate cortex','Motor Cortex','Somatosensory Cortex','Operculum','Temporal Lobe','Hippocampus','Amygdala','Insula','Parietal Lobe','Occipital Lobe','Thalamus','White matter','Other'};

%generate colors corresponding to each major brain region (colors selected
%manually)
chanColorsTemp = getColors('smartest');
chanColors = [chanColorsTemp(1,:);
    chanColorsTemp(11,:);
    getColors('modern orange');
    chanColorsTemp(4,:);
    chanColorsTemp(4,:);
    chanColorsTemp(5,:);
    chanColorsTemp(6,:);
    chanColorsTemp(7,:);
    chanColorsTemp(8,:);
    chanColorsTemp(9,:);
    chanColorsTemp(10,:);
    chanColorsTemp(10,:);
    chanColorsTemp(12,:);
    [0.2,0.2,0.2];
    [0.2,0.2,0.2]];

%generate colors of brain regions (in this case, cingulate is red, the rest
%is light gray)
regionColorsAll = [[.8,0,0.1];
    [.8,0,0.1];
    [.8,0,0.1];
    [.8,0,0.1];
    [.8,0,0.1];
    0.2,0.2,0.2];


%% FIGURE 1b%%

% Consists of an average brain volume, and averaged cingulate cortex, and
% all channels, each colored with a respective region from saggital, axial,
% and superior views. Also contains a bar graph showing total number of
% channels across all brain regions

%% plot 3D models with electrode color corresponding to each region:

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

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(cortOut,regionColorsAll);
for i = 1:length(surface)
surface(i).FaceAlpha = 0.05;
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

%% create bar graph with channel density
regionOrdered = {'Orbitofrontal cortex','Frontal Lobe','Cingulate cortex','Somato-Motor Cortex','Operculum','Temporal Lobe','Hippocampus','Amygdala','Insula','Parietal Lobe','Occipital Lobe','Thalamus','White matter'};

%pool motor and somatomotor regions
for i = 1:length(e)
tempL = size(e{i},1);
if i == 4
    tempL = size(e{i},1) + size(e{i+1},1); % pool motor and somatomotor
elseif i == 15
    tempL = 0;
end
chanCount(i) = tempL;
end
chanCount(15) = [];
chanCount(5) = [];

chanColors2 = chanColors([1:4,6:14],:);

countTable = table(regionOrdered',chanCount',chanColors2(:,1),chanColors2(:,2),chanColors2(:,3));
countTableSorted = sortrows(countTable,'Var2','ascend');

figure('Position',[1440          34         535        1204]);
for i = 1:13
    b = barh(i,countTable.Var2(i),0.6);
    hold on
    b.EdgeColor = 'none';
    b.FaceColor = [countTable.Var3(i), countTable.Var4(i), countTable.Var5(i)];

end
box off
saveas(gcf,[saveDir '_channelCount.svg'])
saveas(gcf,[saveDir '_channelCount.png'])

%% FIGURE 1c%%

% Consists of an averaged cingulate cortex, with subregions colored, and
% electrode density across this region. The electrodes are colored
% depending on whether or not they were stimulated. The percentage of
% data acquired from stimulating each subregion on the left and right side
% is visualized using a stacked box plot.
%% plot only the cingulate subregions with electrodes from this area

figure('Position',[281          32        3060        1260]);
[CCsurface] = plotProjectedRegionsOnly(cingulateRegions,regionColorsCC);
for i = 1:length(CCsurface)
CCsurface(i).FaceAlpha = 0.3; %change alpha of all generated surfaces
end

hold on

plotBallsOnVolume(gca,uniqueCingulateChans,[0,0,0],1.5) %plot non stimulated channels in black

hold on

plotBallsOnVolume(gca,stimulatedChans',[1,0,0],1.5) %plot stimulated channels in red

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

%% get counts for number of stimulations at each subregion and create a stacked barplot for the left and right cingulate

stimConditions = unique([pooledData.stimulatedRegion{:}]);
for i = 1:length(stimConditions)
curCondition = stimConditions(i);
tempAmount = contains([pooledData.stimulatedRegion{:}],curCondition);
tempSum = sum(tempAmount);
tempPercent = tempSum/length(pooledData.stimulatedRegion);
storePercentage(i) = tempPercent;
end

leftA = storePercentage(1);
leftM = storePercentage(2) + storePercentage(3);
leftP = storePercentage(4);
rightA = storePercentage(5);
rightM = storePercentage(6) + storePercentage(7);
rightP = storePercentage(8) + storePercentage(9);

compiled = [leftA,leftM,leftP;rightA,rightM,rightP];
barColors = [
    getColors('lush lilac');
    getColors('celadon porcelain');
    getColors('lago blue')];

figure('Position',[1440         108         560        1130]);
b = bar(compiled,'stacked','EdgeColor','none');
for i = 1:length(b)
b(i).FaceColor = barColors(i,:);
b(i).FaceAlpha = 0.6;
end
box off

saveas(gcf,[saveDir '_CCStimCount.svg'])
saveas(gcf,[saveDir '_CCStimCount.png'])

%% plot exemplar CCEPs from OFC

length_samples = 3800;
% Sampling rate
fs = 2000; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

currentRegion = regionOrdered(1);
currentListIDX = contains(sortedTable.Class,currentRegion);
currentList = sortedTable.Name(currentListIDX);
findChannels = contains([pooledData.electrodeRegionLabel{:}],currentList);
findACC = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(1));
findMCC = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(2:3));
findPCC = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(4:5));
findSignificant = pooledData.pValue < 0.0000001;
indexA = find((findSignificant & findACC & findChannels) == 1);
indexM = find((findSignificant & findMCC & findChannels) == 1);
indexP = find((findSignificant & findPCC & findChannels) == 1);

figure('Position',[1441          44         231         899]);
for ch = 1:3

    curA = pooledData.CCEPs(:,indexA(ch))';

    subplot(3,1,ch)

    plot(timeVector, curA,'Color',getColors('lush lilac'),'LineWidth',1);
    hold on
    plot([0 0], [-10 10],'--','color','k','linewidth',1) 
    ylabel('z-score')
    xlabel('Time (ms)')
    ylim([-10 10])
    xlim([-250 500])
    box off
    set(gca,'LineWidth',0.75,'XColor','k','YColor','k')
end


saveas(gcf,[saveDir '_exemplarCCEPACC_OFC.svg'])
saveas(gcf,[saveDir '_exemplarCCEPACC_OFC.png'])

figure('Position',[1441          44         231         899]);
for ch = 1:3


    curM = pooledData.CCEPs(:,indexM(ch))';


    subplot(3,1,ch)

    plot(timeVector, curM,'Color',getColors('celadon porcelain'),'LineWidth',1);
    hold on
    plot([0 0], [-10 10],'--','color','k','linewidth',1) 
    ylabel('z-score')
    xlabel('Time (ms)')
    ylim([-10 10])
    xlim([-250 500])
    box off
    set(gca,'LineWidth',0.75,'XColor','k','YColor','k')
end

saveas(gcf,[saveDir '_exemplarCCEPMCC_OFC.svg'])
saveas(gcf,[saveDir '_exemplarCCEPMCC_OFC.png'])

figure('Position',[1441          44         231         899]);
for ch = 1:3


    curP = pooledData.CCEPs(:,indexP(ch))';

    subplot(3,1,ch)

    plot(timeVector, curP,'Color',getColors('lago blue'),'LineWidth',1);
    hold on
    plot([0 0], [-10 10],'--','color','k','linewidth',1) 
    ylabel('z-score')
    xlabel('Time (ms)')
    ylim([-10 10])
    xlim([-250 500])
    box off
    set(gca,'LineWidth',0.75,'XColor','k','YColor','k')
end

saveas(gcf,[saveDir '_exemplarCCEPPCC_OFC.svg'])
saveas(gcf,[saveDir '_exemplarCCEPPCC_OFC.png'])

%% plot exemplar CCEPs from Hippocampus

length_samples = 3800;
% Sampling rate
fs = 2000; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

currentRegion = regionOrdered(8);
currentListIDX = contains(sortedTable.Class,currentRegion);
currentList = sortedTable.Name(currentListIDX);
findChannels = contains([pooledData.electrodeRegionLabel{:}],currentList);
findACC = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(1));
findMCC = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(2:3));
findPCC = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(4:5));
findSignificant = pooledData.pValue < 0.0000001;
indexA = find((findSignificant & findACC & findChannels) == 1);
indexM = find((findSignificant & findMCC & findChannels) == 1);
indexP = find((findSignificant & findPCC & findChannels) == 1);

figure('Position',[1441          44         231         899]);
for ch = 1:3

    curA = pooledData.CCEPs(:,indexA(ch))';

    subplot(3,1,ch)

    plot(timeVector, curA,'Color',getColors('lush lilac'),'LineWidth',1);
    hold on
    plot([0 0], [-10 10],'--','color','k','linewidth',1) 
    ylabel('z-score')
    xlabel('Time (ms)')
    ylim([-10 10])
    xlim([-250 500])
    box off
    set(gca,'LineWidth',0.75,'XColor','k','YColor','k')
end

saveas(gcf,[saveDir '_exemplarCCEPACC_Hip.svg'])
saveas(gcf,[saveDir '_exemplarCCEPACC_Hip.png'])

figure('Position',[1441          44         231         899]);
for ch = 1:3


    curM = pooledData.CCEPs(:,indexM(ch))';


    subplot(3,1,ch)

    plot(timeVector, curM,'Color',getColors('celadon porcelain'),'LineWidth',1);
    hold on
    plot([0 0], [-10 10],'--','color','k','linewidth',1) 
    ylabel('z-score')
    xlabel('Time (ms)')
    ylim([-10 10])
    xlim([-250 500])
    box off
    set(gca,'LineWidth',0.75,'XColor','k','YColor','k')
end

saveas(gcf,[saveDir '_exemplarCCEPMCC_Hip.svg'])
saveas(gcf,[saveDir '_exemplarCCEPMCC_Hip.png'])

figure('Position',[1441          44         231         899]);
for ch = 1:3


    curP = pooledData.CCEPs(:,indexP(ch))';

    subplot(3,1,ch)

    plot(timeVector, curP,'Color',getColors('lago blue'),'LineWidth',1);
    hold on
    plot([0 0], [-10 10],'--','color','k','linewidth',1) 
    ylabel('z-score')
    xlabel('Time (ms)')
    ylim([-10 10])
    xlim([-250 500])
    box off
    set(gca,'LineWidth',0.75,'XColor','k','YColor','k')
end

saveas(gcf,[saveDir '_exemplarCCEPPCC_Hip.svg'])
saveas(gcf,[saveDir '_exemplarCCEPPCC_Hip.png'])

%% plot exemplar CCEPs from Insula

length_samples = 3800;
% Sampling rate
fs = 2000; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

currentRegion = regionOrdered(10);
currentListIDX = contains(sortedTable.Class,currentRegion);
currentList = sortedTable.Name(currentListIDX);
findChannels = contains([pooledData.electrodeRegionLabel{:}],currentList);
findACC = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(1));
findMCC = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(2:3));
findPCC = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(4:5));
findSignificant = pooledData.pValue < 0.0000001;
indexA = find((findSignificant & findACC & findChannels) == 1);
indexM = find((findSignificant & findMCC & findChannels) == 1);
indexP = find((findSignificant & findPCC & findChannels) == 1);

figure('Position',[1441          44         231         899]);
for ch = 1:3

    curA = pooledData.CCEPs(:,indexA(ch))';

    subplot(3,1,ch)

    plot(timeVector, curA,'Color',getColors('lush lilac'),'LineWidth',1);
    hold on
    plot([0 0], [-10 10],'--','color','k','linewidth',1) 
    ylabel('z-score')
    xlabel('Time (ms)')
    ylim([-10 10])
    xlim([-250 500])
    box off
    set(gca,'LineWidth',0.75,'XColor','k','YColor','k')
end

saveas(gcf,[saveDir '_exemplarCCEPACC_Ins.svg'])
saveas(gcf,[saveDir '_exemplarCCEPACC_Ins.png'])

figure('Position',[1441          44         231         899]);
for ch = 1:3


    curM = pooledData.CCEPs(:,indexM(ch))';


    subplot(3,1,ch)

    plot(timeVector, curM,'Color',getColors('celadon porcelain'),'LineWidth',1);
    hold on
    plot([0 0], [-10 10],'--','color','k','linewidth',1) 
    ylabel('z-score')
    xlabel('Time (ms)')
    ylim([-10 10])
    xlim([-250 500])
    box off
    set(gca,'LineWidth',0.75,'XColor','k','YColor','k')
end

saveas(gcf,[saveDir '_exemplarCCEPMCC_Ins.svg'])
saveas(gcf,[saveDir '_exemplarCCEPMCC_Ins.png'])

figure('Position',[1441          44         231         899]);
for ch = 1:3


    curP = pooledData.CCEPs(:,indexP(ch))';

    subplot(3,1,ch)

    plot(timeVector, curP,'Color',getColors('lago blue'),'LineWidth',1);
    hold on
    plot([0 0], [-10 10],'--','color','k','linewidth',1) 
    ylabel('z-score')
    xlabel('Time (ms)')
    ylim([-10 10])
    xlim([-250 500])
    box off
    set(gca,'LineWidth',0.75,'XColor','k','YColor','k')
end

saveas(gcf,[saveDir '_exemplarCCEPPCC_Ins.svg'])
saveas(gcf,[saveDir '_exemplarCCEPPCC_Ins.png'])

clear 
addpath(genpath(cd))
eeglab
close all

%% colors
set(0, 'defaultFigureRenderer', 'painters')
colorsGreen = {'#44c895', '#45c694', '#45c494', '#46c293', '#47c093', '#48bd92', '#49bb92', '#49b991', '#4ab790', '#4bb590', '#4cb38f', '#4db18e', '#4daf8d', '#4ead8c', '#4faa8c', '#50a88b', '#51a68a', '#51a489', '#52a288', '#53a087', '#549e86', '#549c85', '#559a84', '#569883', '#569582', '#579381', '#589180', '#588f7f', '#598d7e', '#5a8b7d', '#5a897c', '#5b877a', '#5b8579', '#5c8378', '#5d8077', '#5d7e75', '#5e7c74', '#5e7a73', '#5f7871', '#5f7670', '#617570', '#62746f', '#64736f', '#66726f', '#67716e', '#69706e', '#6a6f6e', '#6c6e6d', '#6d6d6d', '#595959'};
ACCGradient = {'#7617B2', '#791FB3', '#7C25B3', '#7E2BB4', '#8131B5', '#8336B5', '#863BB6', '#8940B7', '#8B45B7', '#8D49B8', '#904EB9', '#9252B9', '#9457BA', '#975BBB', '#9960BB', '#9B64BC', '#9D68BD', '#9F6CBD', '#A071BE', '#A475BF', '#A679BF', '#A87DC0', '#AA81C1', '#AC85C1', '#AE89C2', '#B08DC3', '#B291C3', '#B496C4', '#B69AC5', '#B89EC5', '#BAA2C6', '#BCA6C7', '#BEAAC7', '#C0AEC8', '#C2B2C9', '#C4B6C9', '#C5BACA', '#C7BECA', '#C9C2CB', '#CBC6CB', '#CDCACC', '#CFCFCC', '#C8C8C8', '#CCCCCC', '#CFCFCF', '#D3D3D3', '#D7D7D7', '#DADADA', '#DEDEDE', '#E2E2E2', '#E5E5E5', '#E9E9E9'};
PCCGradient = {'#22AFC2', '#2EB0D2', '#37B0D2', '#3FB1D1', '#46B2D1', '#4CB2D1', '#52B3D1', '#57B4D0', '#5CB4D0', '#61B5D0', '#66B6D0', '#6AB6CF', '#6FB7CF', '#73B8CF', '#77B8CF', '#7BB9CE', '#7FBACE', '#83BACE', '#86BBCE', '#8ABBCE', '#8DBCCD', '#91BDCD', '#94BDCE', '#97BECD', '#99BFCD', '#9CBFCD', '#9EC0CD', '#A1C1CC', '#A4C1CC', '#A7C2CC', '#AAC3CC', '#ADC3CB', '#B0C4CB', '#B3C5CB', '#B6C5CB', '#B9C6CA', '#BCC7CA', '#BEC7CA', '#C1C8CA', '#C4C9C9', '#C8C9C9', '#CBCAC9', '#CECBC9', '#D1CBC8', '#D4CCC8', '#D7CDC8', '#DACDC8', '#DDCEC7', '#E0CFC7', '#C8C8C8', '#CCCCCC', '#CFCFCF', '#D3D3D3', '#D7D7D7', '#DADADA', '#DEDEDE', '#E2E2E2', '#E5E5E5', '#E9E9E9'};

ACCRGB = hex2rgb(ACCGradient);
PCCRGB = hex2rgb(PCCGradient);

colors = [
    143, 82, 182; % Original Purple
    82, 182, 143; % Green
    182, 143, 82; % Orange
    182, 82, 143; % Pink
    82, 143, 182; % Sky Blue
    69, 185, 214; % Original Cyan/Teal
    185, 69, 214; % Magenta
    214, 185, 69; % Gold/Yellow
    185, 214, 69; % Lime Green
    214, 69, 185; % Hot Pink
    255, 0, 0;    % Pure Red
    0, 255, 0;    % Pure Green
    0, 0, 255;    % Pure Blue
    255, 255, 0;  % Yellow
    0, 255, 255;  % Aqua
    255, 0, 255;  % Magenta
    128, 0, 0;    % Dark Red
    0, 128, 0;    % Dark Green
    0, 0, 128;    % Dark Blue
    128, 128, 0   % Olive
];

%% Load 
ACCColor = [1,0,0];
PCCColor = [69,185,214]/256;
[ACCSig, ACCStates, ACCParams] = load_bcidat('data/raw/BJH024/ElectricalStimulation_1HzStim/ECOG001/ECOGS001R50.dat');
sr = ACCParams.SamplingRate.NumericValue;

%%
ACCStim = (ACCStates.DC04);

ACCStimIndex = findStimulusOnset(ACCStim, 4e4);
ACCCode = zeros(length(ACCSig),1);
ACCCode(ACCStimIndex) = 1;

%remove artifacts
ACCSig = double(ACCSig);
ACCSigClean = getCleanData(ACCSig,sr,ACCStimIndex,15);
%% Clean up the data, remove unqanted electrodes, etc. modify the relevant data from the Vera import to delete corresponding channels we do not have
load('data/raw/BJH024/BJH024_APARC2009_MNIbrain.mat')
rACC = smallLaplace(ACCSigClean,tala.electrodes,5,[]);
%lowpass data for visualization purposes- CCEPs are low freq component
lpACC = getLowPassData(rACC,25,5,sr);

%% format data by trials
data.ACCMain = epochData(rACC,ACCCode,{'SixmA'},.95,.95,sr);
data.lpACCTrials = epochData(lpACC,ACCCode,{'SixmA'},.95,.95,sr);

%% zscore each matrix
%Baseline window
baselineWindow = 1:.9*sr;
taskWindow = .95*sr:(.95*sr + (0.6*sr));
data.zScoredACC = getZScore(data.ACCMain,baselineWindow);
data.zScoredPCC = getZScore(data.PCCMain,baselineWindow);
data.lpZScoreACC = getZScore(data.lpACCTrials,baselineWindow);
data.lpZScorePCC = getZScore(data.lpPCCTrials,baselineWindow);
data.ACCTrials = size(data.ACCMain.SixmA,3);
data.PCCTrials = size(data.PCCMain.SixmA,3);


%% group matrices by region, then color the 3d plot based on each electrode
VERA.labels = cellfun(@(x)x{end},VERA.SecondaryLabel,'UniformOutput',false); %return the last element of each array since the first will contain the term "unknown"
uniqueLabels = unique(VERA.labels);
countEachREgion = countStrings(VERA.labels,uniqueLabels);


uniqueLabels = erase(uniqueLabels,'ctx-');
uniqueLabels = erase(uniqueLabels,'_');
uniqueLabels = replace(uniqueLabels, '-', ' ');
uniqueLabels = replace(uniqueLabels, '_', ' ');



% Capitalize the first letter of each label
uniqueLabels = cellfun(@capitalizeFirstLetter, uniqueLabels, 'UniformOutput', false);

%%
normACCRegions = organizeDataByRegions(data.lpZScoreACC.SixmA,uniqueLabels,VERA.labels);
normPCCRegions = organizeDataByRegions(data.lpZScorePCC.SixmA,uniqueLabels,VERA.labels);
baseACCRegions = organizeDataByRegions(data.zScoredACC.SixmA,uniqueLabels,VERA.labels);
basePCCRegions = organizeDataByRegions(data.zScoredPCC.SixmA,uniqueLabels,VERA.labels);
%% perform coherence analysis within subregions- use AMin/Markus' method
%What I will need to do is creat a trial to trial coherence histogrram for
%each trial either within electrodes, or between electrodes. Then, using a
%simple rank-0sum test, determine whether or not each distirbution is
%significantly different from one another- If they are significantly
%different from each  other, then do not treat them as the same response
%within the same region. .

data.ACCCoherence = getCoherenceR(data.ACCMain.SixmA,@(x,y)corr(x,y,'Type','spearman'),baselineWindow,taskWindow);
data.PCCCoherence = getCoherenceR(data.PCCMain.SixmA,@(x,y)corr(x,y,'Type','spearman'),baselineWindow,taskWindow);

save('data/processed/data.mat','data','-mat')
%% perform RMS analysis and rank by response magnitude

ACCRMS = getRMS(data.ACCMain.SixmA,baselineWindow,taskWindow);
PCCRMS = getRMS(data.PCCMain.SixmA,baselineWindow,taskWindow);

meanACCRMS = mean(AverageResponseByRegions(ACCRMS,unique(VERA.labels),VERA.labels),2);
meanPCCRMS = mean(AverageResponseByRegions(PCCRMS,unique(VERA.labels),VERA.labels),2);


%% EEG analysis
lpACCEEG = getLowPassData(ACCEEG,30,5,sr);
lpPCCEEG = getLowPassData(PCCEEG,30,5,sr);

carACCEEG = commonAverageData(ACCEEG);
carPCCEEG = commonAverageData(PCCEEG);

data.ACCEEGMain = epochData(lpACCEEG,ACCCode,{'SixmA'},.95,.95,sr);
data.PCCEEGMain = epochData(lpPCCEEG,PCCCode,{'SixmA'},.95,.95,sr);

length_samples = 3800;
% Sampling rate
fs = sr; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

meanEEGACC = squeeze(mean(data.ACCEEGMain.SixmA,3));
meanEEGPCC = squeeze(mean(data.PCCEEGMain.SixmA,3));
sdACCEEG = squeeze(std(data.ACCEEGMain.SixmA,0,3));
sdPCCEEG = squeeze(std(data.PCCEEGMain.SixmA,0,3));
seACCEEG = squeeze(std(data.ACCEEGMain.SixmA,0,3))./ sqrt(size(data.ACCEEGMain.SixmA,3));
sePCCEEG = squeeze(std(data.PCCEEGMain.SixmA,0,3))./ sqrt(size(data.PCCEEGMain.SixmA,3));

%%


[rows,columns,channelNumber] = getSubplotDimensions(22);
for ch = 1:size(meanEEGACC,1)

figure('Position',[-1402         611         835         509]);

plot([0 0], [-100 200],'--','color',[1,0,0],'linewidth',2)
hold on
plot(timeVector,meanEEGACC(ch,:),'Color',ACCColor,'linewidth',2);
hold on
jbfill(timeVector, meanEEGACC(ch,:)+seACCEEG(ch,:),meanEEGACC(ch,:)-seACCEEG(ch,:), ACCColor,ACCColor, 1, 0.2);
hold on


plot(timeVector,meanEEGPCC(ch,:),'Color',PCCColor,'linewidth',2);
hold on
jbfill(timeVector, meanEEGPCC(ch,:)+sePCCEEG(ch,:),meanEEGPCC(ch,:)-sePCCEEG(ch,:), PCCColor,PCCColor, 1, 0.2);
hold on


ylabel('\muV')
xlabel('time(ms)')
box off
ylim([-600 600])
set(gca,'fontsize',14,'FontName','Source Sans Variable')
title(EEGChans(ch).labels)
box off
saveas(gcf,['figures/EEGResponses/' EEGChans(ch).labels '.svg']);
end


%%

peakIDX = find(meanEEGACC(11,:)==max(meanEEGACC(11,:)));
listIDX = [1601; 1981; peakIDX;  2901];

for i = 1:length(listIDX)

curIDX = listIDX(i);

figure();
topoplot(meanEEGACC(:,curIDX),EEGChans,'shading','interp','whitebk','on','conv','on')
colormap(brewermap([],"Purples"));
caxis([-150 150])
colorbar('fontsize',12,'color','black')

saveas(gcf,['figures/EEGResponses/' num2str(curIDX) 'EEGACC.svg']);

figure();
topoplot(meanEEGPCC(:,curIDX),EEGChans,'shading','interp','whitebk','on','conv','on')
colormap(brewermap([],"Blues"));
caxis([-150 150])
colorbar('fontsize',12,'color','black')

saveas(gcf,['figures/EEGResponses/' num2str(curIDX) 'EEGPCC.svg']);

end

%% make a video
ch = 2;
vidObj = VideoWriter('figures/EEGVideo.mp4')
vidObj.FrameRate = 100;
open(vidObj)
purpleMap = brewermap([],"Purples");
blueMap = brewermap([],"Blues");

figure('Position',[ 83         110        1146         819]);

for time = 1:3800
clf

subplot(2,2,1);
ax1 = gca;
topoplot(meanEEGACC(:,time),EEGChans,'shading','interp','whitebk','on','conv','on')
colormap(ax1,purpleMap)
caxis([-150 150])
colorbar('fontsize',12,'color','black')

subplot(2,2,2);
ax2 = gca;
topoplot(meanEEGPCC(:,time),EEGChans,'shading','interp','whitebk','on','conv','on')
colormap(ax2, blueMap)
caxis([-50 50])
colorbar('fontsize',12,'color','black')


subplot(2,2,[3 4])
plot([0 0], [-400 300],'--','color',[0.5,0.5,0.5,0.5],'linewidth',2)
hold on
plot([timeVector(time) timeVector(time)], [-400 300],'--','color','r','linewidth',2)
hold on
plot(timeVector,meanEEGACC(ch,:),'Color',ACCColor,'linewidth',2);
hold on
jbfill(timeVector, meanEEGACC(ch,:)+seACCEEG(ch,:),meanEEGACC(ch,:)-seACCEEG(ch,:), ACCColor,ACCColor, 1, 0.2);
hold on


plot(timeVector,meanEEGPCC(ch,:),'Color',PCCColor,'linewidth',2);
hold on
jbfill(timeVector, meanEEGPCC(ch,:)+sePCCEEG(ch,:),meanEEGPCC(ch,:)-sePCCEEG(ch,:), PCCColor,PCCColor, 1, 0.2);
hold on

ylabel('\muV')
xlabel('time(ms)')
box off

writeVideo(vidObj,getframe(gcf));
end

close(vidObj);


%% repeat with gamma

%% Let's bin our data by unique regions, here we need to find all unique instances of a particular region in the secondaryLabels



%%Create z-score matrixes, where each trial is z-scored to its own
%%baseline, use this to visualilze aftert low poassing to show individual
%%locations, next, group regions and visualize the responses by electrodes
%%within regions and ask the question- how confident am I that these are
%%the same responses- we can the use coherence to qualify whether the
%%responses are the same or not. From here, we can then see how consisten
%%the responses are, and quantify overall response magnitude (via RMS) and
%%response consistency(via amin's method).

%From here, we can visualize gamma within regions as well, following a
%similar analysis structure

%Finally, perform EEG cleanup, and qualify how stimulation of different
%regions of the cingulate leads to qualifiable responses on surface eeg. 
%% you are here do this for low pass data


%% Create Figure of the Brain
unknownLabels = find(strcmp(VERA.labels, 'unknown'));

figure('color','white','Position',[1000         243        1304        1095]);
surf = plot3DModel(gca,VERA.cortex);
surf.FaceColor = [100,126,146]/256;
alpha(0.02)
hold on
plotBallsOnVolume(gca,VERA.tala.electrodes,[0,0,0],0.8)
hold on
plotBallsOnVolume(gca,VERA.tala.electrodes(109:111,:),ACCColor,2)
hold on
plotBallsOnVolume(gca,VERA.tala.electrodes(125:127,:),PCCColor,2)


view([180 0] )
saveas(gcf,'figures/brainFront.png')

view([-93.0402,-1])
saveas(gcf,'figures/brainSide.png')

view([-2,90])
saveas(gcf,'figures/brainTop.png')

view([ -494.1925 60.3828] )
saveas(gcf,'figures/brainDiag.png')
%% Create a bargraph showing the number of electrodes within each region



%%
% Assuming the variable of values and labels are 'values' and 'labels' respectively
values = countEachREgion; % Replace this with your actual values
labels = uniqueLabels'; % Replace this with your actual labels

% Create a table from the values and labels
T = table(values', labels, 'VariableNames', {'values', 'labels'});

% Sort the table by values in descending order
T = sortrows(T, 'values', 'descend');

% Plot the bar chart
figure('position',[ -1426          59        1106        1730]);
hold on;
for i = 1:numel(T.values)
    if i == 1
        barh(i, T.values(i), 'FaceColor', 'r','EdgeColor','none'); 
    else

    barh(i, T.values(i), 'FaceColor', colorsGreen{i},'EdgeColor','none'); 

    end

end
hold off;
set(gca, 'YDir','reverse'); % To have the largest at the top
set(gca, 'YTick', 1:numel(T.values), 'YTickLabel', T.labels);
set(gca, 'XAxisLocation', 'top'); % To set the x-axis at the top
xlabel('Number of Electrodes');
set(gca,'TickLength', [0.01 0])
set(gca,'fontsize',18,'FontName','Source Sans Variable')
box off

saveas(gcf,'figures/electrodesInEachRegion.png')
saveas(gcf,'figures/electrodesInEachRegion.svg')


%% plot a few exemplars channels
length_samples = 3800;
% Sampling rate
fs = sr; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

meanACC = squeeze(mean(data.ACCMain.SixmA,3));
meanPCC = squeeze(mean(data.PCCMain.SixmA,3));
sdACC = squeeze(std(data.ACCMain.SixmA,0,3));
sdPCC = squeeze(std(data.PCCMain.SixmA,0,3));
seACC = squeeze(std(data.ACCMain.SixmA,0,3))./ sqrt(size(data.ACCMain.SixmA,3));
sePCC = squeeze(std(data.PCCMain.SixmA,0,3))./ sqrt(size(data.PCCMain.SixmA,3));
ch2plot = find(contains(VERA.labels, 'ctx-rh-lateralorbitofrontal'));




for i = 1:length(ch2plot)

ch = ch2plot(i);

figure('position', [857         772        1148         464]);
plot([0 0], [-100 200],'--','color',[0.5,0.5,0.5,0.5],'linewidth',2)
hold on
plot(timeVector,meanACC(ch,:),'Color',ACCColor,'linewidth',2);
hold on
jbfill(timeVector, meanACC(ch,:)+sdACC(ch,:),meanACC(ch,:)-sdACC(ch,:), ACCColor,ACCColor, 1, 0.2);
hold on


plot(timeVector,meanPCC(ch,:),'Color',PCCColor,'linewidth',2);
hold on
jbfill(timeVector, meanPCC(ch,:)+sdPCC(ch,:),meanPCC(ch,:)-sdPCC(ch,:), PCCColor,PCCColor, 1, 0.2);
hold on


ylabel('\muV')
xlabel('time(ms)')
box off
xlim([-949.75 949.75])
ylim([-100 200])
xticks([-900,-500,0,500,900])
set(gca,'fontsize',24,'FontName','Source Sans Variable')
end

%% generate Waterfall plot of all average traces and rank them. 

ACCWaterfall = AverageResponseByRegions(squeeze(nanmean(data.lpZScoreACC.SixmA,3)),unique(VERA.labels),VERA.labels);
ACCRemove = [26,50];
ACCLabels = uniqueLabels;
ACCLabels(ACCRemove) = [];
ACCWaterfall(ACCRemove,:) = [];

PCCWaterfall = AverageResponseByRegions(squeeze(nanmean(data.lpZScorePCC.SixmA,3)),unique(VERA.labels),VERA.labels);
PCCRemove = [10,11,32,50];
PCCLabels = uniqueLabels;
PCCLabels(PCCRemove) = [];
PCCWaterfall(PCCRemove,:) = [];
%YOU ARE HERE

%RANK RESPONSES BY AMPLITUDE AND PLOT
maxValuesACC = max(abs(ACCWaterfall), [], 2);
maxValuesPCC = max(abs(PCCWaterfall), [], 2);

% Get the sorted order of the maximum absolute values (in descending order)
% and the corresponding indices
[maxAbsValuesSortedACC, sortIndicesACC] = sort(maxValuesACC, 'ascend');
[maxAbsValuesSortedPCC, sortIndicesPCC] = sort(maxValuesPCC, 'descend');

% Use the sort indices to reorder your matrix and labels
ACCSorted = ACCWaterfall(sortIndicesACC, :);
ACClabelsSorted = ACCLabels(sortIndicesACC);
PCCSorted = PCCWaterfall(sortIndicesPCC, :);
PCClabelsSorted = ACCLabels(sortIndicesPCC);

flipACCGradient = flip(ACCGradient);

ACCWaterfallChannelCount = countEachREgion;
ACCWaterfallChannelCount(ACCRemove) = [];

PCCWaterfallChannelCount = countEachREgion;
PCCWaterfallChannelCount(PCCRemove) = [];

colorsSort = flip(colorsGreen);


PCCWaterfallChannelCount = PCCWaterfallChannelCount(sortIndicesPCC);
ACCWaterfallChannelCount = ACCWaterfallChannelCount(sortIndicesACC);

%FOR ACC, Remove stimulation locations, do ther same for PCC before ranking them. 

figure('position' , [901         118        1421        1214]);
time = downsample(timeVector,10);
responseWindow = time(190:250);

for ch = 1:size(ACCWaterfall,1)
    Response = downsample(ACCSorted(ch,:),10);
    if (min(Response) <= 200) && (max(abs(min(Response))) > max(Response))

        Response = Response*-1;

    end

    plot3(time,ch*ones(size(time)),Response,'color',flipACCGradient{ch},'LineWidth',.4)
    hold on
    plot3(responseWindow,ch*ones(size(responseWindow)),Response(190:250),'color',flipACCGradient{ch},'LineWidth',1.5)

end

hold on
for ch = 1:size(PCCWaterfall,1)
    Response = downsample(PCCSorted(ch,:),10);
    if (min(Response) <= 200) && (max(abs(min(Response))) > max(Response))

        Response = Response*-1;

    end
    plot3(time,(ch+size(ACCWaterfall,1))*ones(size(time)),Response,'color',PCCGradient{ch},'LineWidth',.4)
    hold on
    plot3(responseWindow,(ch+size(ACCWaterfall,1))*ones(size(responseWindow)),Response(190:250),'color',PCCGradient{ch},'LineWidth',1.5)

end

hold on
grid off
ax = gca;
zlim([-1 9]);
%ax.ZAxis.Visible = 'off';
view([-64.7603 37.2646])

set(gca,'fontsize',18,'FontName','Source Sans Variable')
box off

saveas(gcf,'figures/waterfall.png')
saveas(gcf,'figures/waterfall.svg')


%% RMS Figures

%Calculate RMS for each trial, each channel, in each region

ACCRMS = getRMS(data.ACCMain.SixmA,baselineWindow,taskWindow);
PCCRMS = getRMS(data.PCCMain.SixmA,baselineWindow,taskWindow);

meanACCRMS = mean(AverageResponseByRegions(ACCRMS,unique(VERA.labels),VERA.labels),2);
meanPCCRMS = mean(AverageResponseByRegions(PCCRMS,unique(VERA.labels),VERA.labels),2);

meanACCRMS(ACCRemove) = nan;
meanPCCRMS(PCCRemove) = nan;


% Assuming the variable of values and labels are 'values' and 'labels' respectively
values = meanACCRMS;
values2 = meanPCCRMS;% Replace this with your actual values
labels = uniqueLabels; % Replace this with your actual labels

% Create a table from the values and labels
T = table(values, values2, labels, 'VariableNames', {'valuesA', 'valuesP', 'labels'});

% Sort the table by values in descending order
T = sortrows(T, 'valuesA', 'descend');

% Plot the bar chart
figure('position',[ -1426          59        1106        1730]);
hold on;
for i = 1:numel(T.valuesA)
    barh(i, T.valuesA(i), 'FaceColor', ACCGradient{i},'EdgeColor','none');
end
hold off;
set(gca, 'YDir','reverse'); % To have the largest at the top
set(gca, 'YTick', 1:numel(T.valuesA), 'YTickLabel', T.labels);
set(gca, 'XAxisLocation', 'top'); % To set the x-axis at the top
xlabel('Number of Electrodes');
set(gca,'TickLength', [0.01 0])
set(gca,'fontsize',18,'FontName','Source Sans Variable')
box off

saveas(gcf,'figures/RMSACCInEachRegion.png')
saveas(gcf,'figures/RMSACCInEachRegion.svg')

%%
values = PCCWaterfallChannelCount; % Replace this with your actual values
labels = PCClabelsSorted'; % Replace this with your actual labels

% Assuming the variable of values and labels are 'values' and 'labels' respectively
values = countEachREgion; % Replace this with your actual values
labels = uniqueLabels'; % Replace this with your actual labels

% Create a table from the values and labels
T = table(values', labels, 'VariableNames', {'values', 'labels'});

% Sort the table by values in descending order
T = sortrows(T, 'values', 'descend');

% Plot the bar chart
figure('position',[ -1426          59        1106        1730]);
hold on;
for i = 1:numel(T.values)
    if i == 1
        barh(i, T.values(i), 'FaceColor', 'r','EdgeColor','none'); 
    else

    barh(i, T.values(i), 'FaceColor', colorsGreen{i},'EdgeColor','none'); 

    end

end
hold off;
set(gca, 'YDir','reverse'); % To have the largest at the top
set(gca, 'YTick', 1:numel(T.values), 'YTickLabel', T.labels);
set(gca, 'XAxisLocation', 'top'); % To set the x-axis at the top
xlabel('Number of Electrodes');
set(gca,'TickLength', [0.01 0])
set(gca,'fontsize',18,'FontName','Source Sans Variable')
box off

saveas(gcf,'figures/RMSPCCInEachRegion.png')
saveas(gcf,'figures/RMSPCCInEachRegion.svg')


%%




ACCRMSGrouped = groupByRegions(ACCRMS,unique(VERA.labels),VERA.labels);
PCCRMSGrouped = groupByRegions(PCCRMS,unique(VERA.labels),VERA.labels);

for ch = 1:length(ACCRMSGrouped)

    countTrials(ch) = (length(ACCRMSGrouped{ch}));

end

violinPlotACC = nan(length(ACCRMSGrouped{ch}),max(countTrials));
violinPlotPCC = nan(length(PCCRMSGrouped{ch}),max(countTrials));

for ch = 1:length(ACCRMSGrouped)

violinPlotACC(ch,1:length(ACCRMSGrouped{ch})) = ACCRMSGrouped{ch};
violinPlotPCC(ch,1:length(PCCRMSGrouped{ch})) = PCCRMSGrouped{ch};

end

violinPlotACC(ACCRemove) = [];
violinPlotPCC(PCCRemove) = [];
%%
%
X = 1:length(ACCRMSGrouped);
figure('position',[72   541   935   743]);


vp = violinplot(violinPlotACC',X,'ViolinColor',[0 0 0],'ShowData',false,'HalfViolin','left','ShowMedian',false,'EdgeColor',[0 0 0],'ShowBox',false,'Width',0.5);
hold on

swarmchart(X,violinPlotACC,[],'k','filled');
hold on


set(gca,'linewidth',2, 'FontSize',12)
box off

% saveas(gcf,'figures/ViolinHisto.png')
% saveas(gcf,'figures/ViolinHisto.svg')


%% Coherence Distributions

%% EEG Figs

%% Create example plots of channels

figure();
[rows,columns,channelNumber] = getSubplotDimensions(229);
parfor ch = 1:229
    subplot(rows,columns,ch)
    curDat = data.spesSmallLaplaceZScore(ch,:,:);
    plot(squeeze(mean(curDat,3)))
    hold on
    title(num2str(ch))
end

figure();
ch = 124;
    curDat = ACCTrials.SixmA(ch,:,:);
    curDat2 = PCCTrials.SixmA(ch,:,:);
    plot(squeeze(mean(curDat,3)))
    hold on
    plot(squeeze(mean(curDat2,3)))
%% Function to capitalize the first letter of a string
function str = capitalizeFirstLetter(str)
    str = lower(str); % First make all letters lowercase
    str(1) = upper(str(1)); % Then capitalize the first letter
end

%%
function [RMSOut] = getRMS(signal, baselineWindow, taskWindow)

RMSOut = nan(size(signal,1),size(signal,3));

for ch = 1:size(signal,1)
    for trial = 1:size(signal,3)

        base = rms(signal(ch,baselineWindow,trial));
        task = rms(signal(ch,taskWindow,trial));

        RMSOut(ch,trial) = mean(task-base);


    end
end



end

%%
function [groupOut] = groupByRegions(dataIn,uniqueRegions,allChannels)
%input is struct with field dimensions chans x signal
%This function will generate a struct of nuqiue regions, where each struct
%field contains the name of each unique region. Each one of these unqiue
%regions will contain a cell, which contains a matrix of trialsxsignal and
%a channel number label.

groupOut = cell(size(uniqueRegions));

for i = 1:length(uniqueRegions)

currentRegion = uniqueRegions{i};
idx = find(contains(allChannels,currentRegion));

a = dataIn(idx,:);
groupOut{i} = a(:);

end


end
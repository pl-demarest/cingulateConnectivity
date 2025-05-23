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
saveDir = 'figures/main/figure5/dependencies/';
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
    getColors('celadon porcelain');
    getColors('lago blue')];

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


%% % Response latency


for c = 1:size(condition,1) % iterate through each condition

figure('Position',[38         188        3397         946]);

for r = 1:length(brainFieldnames)
    
curRegion = templateBrain.regionList{r};
curRegionIDX = contains([pooledData.electrodeRegionLabel{:}],curRegion);

curIDXSig = curRegionIDX & condition(c,:) & significant;

latency(c,r) = nanmean(pooledData.responseLatency(curIDXSig));

        if (c == 1 ) && any(contains(cingulateNamesSimple(1),templateBrain.regionList{r}))
        latency(c,r) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif (c == 2) && any(contains(cingulateNamesSimple(2:3),templateBrain.regionList{r}))
        latency(c,r) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif (c == 3) && any(contains(cingulateNamesSimple(4:5),templateBrain.regionList{r}))
        latency(c,r) = nan;% set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        end


if sum(curRegionIDX) == 0
    storeNoCoverage(r) = 1;
else 
    storeNoCoverage(r) = 0;
end
end

a = latency(c,:);
Alphas = a;
Nan = isnan(Alphas);
noCover = logical(storeNoCoverage);

if c ==1
    curMap = getColors('lush lilac gradient');%flip gradient for lower vs higher latencies
elseif c == 2
    curMap = getColors('celadon porcelain gradient');
else
    curMap = getColors('lago blue gradient');
end

[~,~,Colors] = electrodeEffectSizes(Alphas,curMap,1.5,4,[0.8,0.8,0.8]);

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
saveas(gcf,[saveDir conditionNames{c} '_ResponseLatency.png'])

figure();
ax = axes;
colorbar(ax)
colormap(curMap)
text(.5,.5,['latest = ' num2str(max(Alphas)) 'earliest = ' num2str(min(Alphas))],'Units','normalized')
axis off
saveas(gcf,[saveDir conditionNames{c} '_ResponseLatencyLegend.svg'])

figure('Position',[1440         818        1471         420]);
scatterDistribution1D(pooledData.responseLatency(condition(c,:) & significant),[],.1,.3,30,regionColorsCC(c,:)) %figure for whole distribution of channels
box off
saveas(gcf,[saveDir conditionNames{c} '_ResponseLatencyDistributionChannels.svg'])

figure('Position',[1440         818        1471         420]);
scatterDistribution1D(Alphas,[],.1,.3,30,regionColorsCC(c,:))
box off
saveas(gcf,[saveDir conditionNames{c} '_ResponseLatencyDistributionRegions.svg'])
end


%% % Response DUration

for c = 1:size(condition,1) % iterate through each condition


figure('Position',[38         188        3397         946]);
for r = 1:length(brainFieldnames)
curRegion = templateBrain.regionList{r};
curRegionIDX = contains([pooledData.electrodeRegionLabel{:}],curRegion);

curIDXSig = curRegionIDX & condition(c,:) & significant;
curIDXAll = curRegionIDX & condition(c,:);
duration(c,r) = nanmean(pooledData.responseDurationByAbruptChanges(curIDXSig));

        if (c==1) && any(contains(cingulateNamesSimple(1),templateBrain.regionList{r}))
        duration(c,r) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif (c==2) && any(contains(cingulateNamesSimple(2:3),templateBrain.regionList{r}))
        duration(c,r) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif (c==3) && any(contains(cingulateNamesSimple(4:5),templateBrain.regionList{r}))
        duration(c,r) = nan;% set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        end

if sum(curRegionIDX) == 0
    storeNoCoverage(r) = 1;
else 
    storeNoCoverage(r) = 0;
end
end

Alphas = duration(c,:);
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
saveas(gcf,[saveDir conditionNames{c} '_Duration.png'])


figure();
ax = axes;
colorbar(ax)
colormap(curMap)
text(.5,.5,['longest = ' num2str(max(Alphas)) 'shortest = ' num2str(min(Alphas))],'Units','normalized')
axis off
saveas(gcf,[saveDir conditionNames{c} '_DurationLegend.svg'])

figure('Position',[1440         818        1471         420]);
scatterDistribution1D(pooledData.responseDurationByAbruptChanges(condition(c,:) & significant),[],.1,.3,30,regionColorsCC(c,:)) %figure for whole distribution of channels
box off
saveas(gcf,[saveDir conditionNames{c} '_ResponseDurationDistributionChannels.svg'])

figure('Position',[1440         818        1471         420]);
scatterDistribution1D(Alphas,[],.1,.3,30,regionColorsCC(c,:))
box off
saveas(gcf,[saveDir conditionNames{c} '_ResponseDurationDistributionRegions.svg'])

end

%% create supplemental figure outlining response detection method

% get exemplar ccep, take broadband filtered response, perform hilbert
% transform, show changepoint detection, show spectral smearing 

%use highest cohensD as exemplar

[M,IList] = sort(pooledData.cohensD,'descend');

I = IList(2);

maxFile = pooledData.dataFileName{I}
loc = [pooledData.electrodeRegionLabel{I}]

%% load the hilbert transform of the signal as defined by the above index
load('data/hilbert/hilbertSEEG_BJH045_ECOGS001R04_ctx_lh_G_and_S_cingul-Ant.mat')

%%

length_samples = 3800;
% Sampling rate
fs = 2000; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

%plot the mean CCEP
ccep = pooledData.CCEPs(:,I)';


%bandpass the CCEP to show spectral smearing
ccepBP = bandPassData(ccep,5,40,3,2000);
responseMag = pooledData.responseMagnitude(:,I)';

figure;
plot(timeVector, ccep,'Color','k')
box off
hold on
xline(0,'r--')
saveas(gcf,[saveDir '_suppExampleCCEP.svg'])

figure();
plot(timeVector, ccepBP,'Color','k')
hold on
xline(0,'r--')
box off
saveas(gcf,[saveDir '_suppExampleCCEPfiltered.svg'])

%plot the detected changepoints along with the magnitude/diff magnitude
magPtsON = findchangepts(diff(responseMag),MaxNumChanges=2,Statistic="rms");
magPtsOFF = findchangepts(responseMag,MaxNumChanges=2,Statistic="linear");

figure();
plot(timeVector,[diff(responseMag),0],'Color','k')
box off
hold on
xline(timeVector(magPtsON(1)),'k--')
xline(timeVector(magPtsON(2)),'k--')
xline(0,'r--')
saveas(gcf,[saveDir '_suppExampleCCEPresponseMagRateChange.svg'])

figure();
plot(timeVector, responseMag, 'Color','k')
hold on
box off
xline(timeVector(magPtsOFF(1)),'k--')
xline(timeVector(magPtsOFF(2)),'k--')
xline(0,'r--')
saveas(gcf,[saveDir '_suppExampleCCEPresponseMag.svg'])

%% plot the spectral smearing

HP_cutoff = 5;
LP_cutoff = 40;
Type      = 'bandpass';
[b0_A,a0_A] = butter(3,2*[HP_cutoff LP_cutoff]/2000, Type);
[sos,g] = tf2sos(b0_A,a0_A);

% Step 0: Parameters
Fs = 2000; % e.g., 1000
t = 0:1/Fs:2; % 2 seconds
signalLength = length(t);

% Step 1: Create a step signal (change from 0 to 1 at 1s)
stepSignal = zeros(1, signalLength);
stepSignal(t >= 1) = 1;

% Step 2: Filter the step signal
filteredStep = filtfilt(sos, g, stepSignal);

% Step 3: Detect changepoints
pt_before = findchangepts(diff(stepSignal), MaxNumChanges=2, Statistic="rms");
pt_after = findchangepts(diff(filteredStep), MaxNumChanges=2, Statistic="rms");

% Step 4: Visualization
figure('Position',[1440         818        1471         420]);
plot(t, stepSignal, 'k--', 'LineWidth', 1.2); hold on;
plot(t, filteredStep, 'b', 'LineWidth', 1.5);
xline(t(pt_before+1), 'g--', 'LineWidth', 1.5, 'Label', 'True Changepoint');
xline(t(pt_after+1), 'r--', 'LineWidth', 1.5, 'Label', 'Detected After Filter');
title('Changepoint Detection on Step Signal');
xlabel('Time (s)'); ylabel('Amplitude');
legend('Original Step', 'Filtered Step', 'True Change', 'Detected (Filtered)');

% Step 5: Report smear
timeShift = (pt_after - pt_before) / Fs;
box off
legend box off
saveas(gcf,[saveDir '_spectralSmearing.svg'])

[smearingSamples, smearingTime] = estimateTemporalDistortion(2000,5,40,3);

%%
%estimate temporal distortion from an example response

changePointCCEP = findchangepts(diff(ccep), MaxNumChanges=2, Statistic="rms")
changePointFiltered = findchangepts(diff(ccepBP), MaxNumChanges=2, Statistic="rms")
changePointMag = findchangepts(diff(responseMag), MaxNumChanges=2, Statistic="rms")

%create plot showing onset detection

figure('Position',[1440         818        1239         420]);
plot(timeVector, responseMag,'Color','k')
box off
hold on
plot(timeVector, ccep,'--','Color','k')
xline(0,'r--')
xline(timeVector(changePointCCEP(1)),'Color',getColors('modern orange'))
xlim([-400 400])
saveas(gcf,[saveDir '_CCEPOnsetDetection1.svg'])


figure('Position',[1440         818        1239         420]);
box off
hold on
plot(timeVector, [diff(responseMag),0],'Color','k')
xline(0,'r--')
xline(timeVector(changePointMag(1)),'Color',getColors('modern orange'))
xlim([-400 400])
saveas(gcf,[saveDir '_CCEPOnsetDetection2.svg'])



changePointCCEP2 = findchangepts(ccep, MaxNumChanges=2, Statistic="linear")
changePointFiltered2 = findchangepts(ccepBP, MaxNumChanges=2, Statistic="linear")
changePointMag2 = findchangepts(responseMag, MaxNumChanges=2, Statistic="linear")

%create plot showing Duration Detection
figure('Position',[1440         818        1239         420]);
hold on
plot(timeVector, ccepBP,'Color','k')
xline(0,'r--')
xline(timeVector(changePointMag(1)),'Color',getColors('modern orange'))
xline(timeVector(changePointMag2(2)),'Color', getColors('modern orange'))
xlim([-400 400])
saveas(gcf,[saveDir '_CCEPDurationDetection1.svg'])

%create plot showing Duration Detection
figure('Position',[1440         818        1239         420]);
hold on
plot(timeVector, responseMag,'Color','k')
xline(0,'r--')
xline(timeVector(changePointMag(1)),'Color',getColors('modern orange'))
xline(timeVector(changePointMag2(2)),'Color', getColors('modern orange'))
xlim([-400 400])
saveas(gcf,[saveDir '_CCEPDurationDetection2.svg'])

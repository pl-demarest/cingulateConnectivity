clear
close all
addpath(genpath(cd))

fileNameDir = 'data/preprocessedHippocampus/';
saveDir = 'figures/limbicSystem/';
brainModels = 'data/limbicExemplars/';
files = dir(fileNameDir);
dataFiles = {files(3:end).name};

%%

chosenExemplarIDX = [45];
chosenFiles = dataFiles(chosenExemplarIDX);

%%
load('code/dependencies/listHip.mat');
load('code/dependencies/listCort.mat');
load('code/dependencies/listAmyg.mat');
rightACC = {'ctx_rh_G_and_S_cingul-Ant','wm_rh_G_and_S_cingul-Ant'};
leftACC = {'ctx_lh_G_and_S_cingul-Ant','wm_lh_G_and_S_cingul-Ant'};

rightMCC = {'ctx_rh_G_and_S_cingul-Mid-Ant','ctx_rh_G_and_S_cingul-Mid-Post','wm_rh_G_and_S_cingul-Mid-Ant','wm_rh_G_and_S_cingul-Mid-Post'};
leftMCC = {'ctx_lh_G_and_S_cingul-Mid-Ant','ctx_lh_G_and_S_cingul-Mid-Post','wm_lh_G_and_S_cingul-Mid-Ant','wm_lh_G_and_S_cingul-Mid-Post'};

rightPCC = {'ctx_rh_G_cingul-Post-dorsal', 'ctx_rh_G_cingul-Post-ventral' , 'wm_rh_G_cingul-Post-dorsal','wm_rh_G_cingul-Post-ventral'};
leftPCC = {'ctx_lh_G_cingul-Post-dorsal','ctx_lh_G_cingul-Post-ventral','wm_lh_G_cingul-Post-dorsal','wm_lh_G_cingul-Post-ventral'};

recorded = [listHip,listAmyg,rightACC,leftACC,rightMCC,leftMCC,rightPCC,leftPCC];
length_samples = 3800;
% Sampling rate
fs = 2000; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

%%
for i = 1:length(dataFiles)
currentFile = dataFiles{i};

try
data = load([fileNameDir currentFile],'VERA','subjectName','stimulatedRegion','lowPassSPESZScore','lowPassSPES','stimulatedChannels');

catch
    warning('could not load')
    continue
end

if ~isfield(data,'VERA')
    continue
end

chanNames = cellfun(@(x)x(end),data.VERA.electrodeDefinition.Label,'UniformOutput',false);

index = find(contains([chanNames{:}],recorded))';

figure('Position',[281          32        3060        1260]);
sgtitle([data.subjectName 'Stimulated: ' data.stimulatedRegion{1} ' and ' data.stimulatedRegion{2}],'Interpreter','none')

%name file
if any(contains([data.stimulatedRegion{:}],listHip))
    regionName = 'hipp';

elseif any(contains([data.stimulatedRegion{:}],listAmyg))
    regionName = 'amyg';

elseif any(contains([data.stimulatedRegion{:}],[rightACC,leftACC,rightMCC,leftMCC,rightPCC,leftPCC]))
    regionName = 'CC';

end

[rows,columns,channelNumber] = getSubplotDimensions(length(index));
count = 1;
for ch = 1:length(index)

    curChan = index(ch);
    subplot(rows,columns,ch)
    curDat = squeeze(data.lowPassSPESZScore(curChan,:,:));
    m = nanmean(curDat,2)';
    s = (nanstd(curDat,[],2)./size(curDat,2))';
    plot(timeVector, m);
    hold on
    jbfill(timeVector, m+s, m-s, 'r','r', 1, 0.3);
    
    ylim([-10 10])
    set(gca,'FontSize',14)
    title(chanNames{curChan},'Interpreter','none','FontSize',12)
    ylabel('z-score')
    xlabel('Time (ms)')
end

mkdir(saveDir)
saveas(gcf,[saveDir currentFile '_' regionName '.png'],'png')
close all
clear data
end
%% plot selected exemplars

exemplarDir = '/Users/Phil/Library/CloudStorage/Box-Box/cingulateConnectivity/figures/limbicSystem/selected';
exFiles = dir(exemplarDir);
exemplars = {exFiles(3:end).name};
remove = ["_hipp.png","_amyg.png","_CC.png"];

exemplars = cellfun(@(x)erase(x,remove),exemplars,'UniformOutput',false);
timeIDX = find(timeVector >=-250 & timeVector <= 500);

for i = 1:length(exemplars)
currentFile = exemplars{i};

try
data = load([fileNameDir currentFile],'VERA','subjectName','stimulatedRegion','lowPassSPESZScore','lowPassSPES','stimulatedChannels');

catch
    warning('could not load')
    continue
end

if ~isfield(data,'VERA')
    continue
end

chanNames = cellfun(@(x)x(end),data.VERA.electrodeDefinition.Label,'UniformOutput',false);

index = find(contains([chanNames{:}],recorded))';

figure('Position',[281          32        3060        1260]);
sgtitle([data.subjectName 'Stimulated: ' data.stimulatedRegion{1} ' and ' data.stimulatedRegion{2}],'Interpreter','none')

%name file
if any(contains([data.stimulatedRegion{:}],listHip))
    regionName = 'hipp';

elseif any(contains([data.stimulatedRegion{:}],listAmyg))
    regionName = 'amyg';

elseif any(contains([data.stimulatedRegion{:}],[rightACC,leftACC,rightMCC,leftMCC,rightPCC,leftPCC]))
    regionName = 'CC';

end

[rows,columns,channelNumber] = getSubplotDimensions(length(index));
count = 1;
for ch = 1:length(index)

    curChan = index(ch);
    subplot(rows,columns,ch)
    ylim([-10 10])
    xlim([-250 500])
    a = patch([10 10 70 70],[min(ylim) max(ylim) max(ylim) min(ylim)],[.5,.5,.5],'EdgeColor','None','FaceAlpha',0.3);
    hold on
    curDat = squeeze(data.lowPassSPESZScore(curChan,:,:));
    m = nanmean(curDat(timeIDX,:),2)';
    s = (nanstd(curDat(timeIDX,:),[],2))';
    plot(timeVector(timeIDX), m,'Color','r');
    hold on
    jbfill(timeVector(timeIDX), m+s, m-s, 'r','r', 1, 0.2);
    set(gca,'FontSize',14)
    title(chanNames{curChan},'Interpreter','none','FontSize',12)
    ylabel('z-score')
    xlabel('Time (ms)')
end


mkdir([saveDir 'selected/'])
saveas(gcf,[saveDir 'selected/' currentFile '_' regionName '.png'],'png')
close all
clear data
end

%% extract latency of N1 from selected exemplars

window = find(timeVector > 10 & timeVector < 100);%n1 window
windowShift = window(1);

ACCColor = getColors('lush lilac');
MCCColor = [0,.5,0];
PCCColor = [0,0,0.5];
amygdalaColor = [103 255 255]/255;
hippColor = [220 216 20]/255;

regionColors = [ACCColor;[0.5,0.5,0.5];[0.5,0.5,0.5];hippColor];

map = [ ...
    0, 0, 0; ...
    7, 0, 0; ...
    13, 0, 0; ...
    20, 0, 0; ...
    26, 0, 0; ...
    33, 0, 0; ...
    39, 0, 0; ...
    46, 0, 0; ...
    52, 0, 0; ...
    59, 0, 0; ...
    65, 0, 0; ...
    72, 0, 0; ...
    78, 0, 0; ...
    85, 0, 0; ...
    92, 0, 0; ...
    98, 0, 0; ...
    105, 0, 0; ...
    111, 0, 0; ...
    118, 0, 0; ...
    124, 0, 0; ...
    131, 0, 0; ...
    137, 0, 0; ...
    144, 0, 0; ...
    150, 0, 0; ...
    157, 0, 0; ...
    163, 0, 0; ...
    170, 0, 0; ...
    177, 0, 0; ...
    183, 0, 0; ...
    190, 0, 0; ...
    196, 0, 0; ...
    203, 0, 0; ...
    209, 0, 0; ...
    216, 0, 0; ...
    222, 0, 0; ...
    229, 0, 0; ...
    235, 0, 0; ...
    242, 0, 0; ...
    248, 0, 0; ...
    255, 0, 0 ...
]/255;


for i = 1:length(chosenFiles)

    data = load([fileNameDir chosenFiles{i}]);
    subject = data.subjectName;
    channels = data.VERA.tala.electrodes;
    channelNames = cellfun(@(x)x(end),data.VERA.electrodeDefinition.Label,'UniformOutput',false);
    meanResponses = nanmean(data.lowPassSPESZScore,3);
    stdResponses = nanstd(data.lowPassSPESZScore,[],3);
    threshold = 6*nanstd(nanstd(data.lowPassSPESZScore(:,1:1500,:),[],3),[],2);
    stimulated = zeros(1,length(channelNames));
    stimulated(data.stimulatedChannels) = 1;


    [latencies, peaks, prominences] = getN1Latency(meanResponses,window,threshold);

index = find(contains([channelNames{:}],recorded))';

figure('Position',[281          32        3060        1260]);
sgtitle([data.subjectName 'Stimulated: ' data.stimulatedRegion{1} ' and ' data.stimulatedRegion{2}],'Interpreter','none')

[rows,columns,channelNumber] = getSubplotDimensions(length(index));
count = 1;
for ch = 1:length(index)

    curChan = index(ch);
    m = meanResponses(curChan,:);
    s = stdResponses(curChan,:);
    subplot(rows,columns,ch)
    ylim([-10 10])
    xlim([-250 500])
    a = patch([10 10 100 100],[min(ylim) max(ylim) max(ylim) min(ylim)],[.5,.5,.5],'EdgeColor','None','FaceAlpha',0.3);
    hold on
    plot(timeVector, m,'Color','r');
    hold on
    jbfill(timeVector, m+s, m-s, 'r','r', 1, 0.2);
    hold on
    if peaks(curChan) ~= 0
    plot(timeVector(latencies(curChan)+windowShift),peaks(curChan),'o','Color','k','MarkerFaceColor','k')
    end
    set(gca,'FontSize',14)
    title([channelNames{curChan} ' ' curChan],'Interpreter','none','FontSize',12)
    ylabel('z-score')
    xlabel('Time (ms)')
end

mkdir([saveDir 'limbicN1/'])
saveas(gcf,[saveDir 'limbicN1/' chosenFiles{i} '.png'],'png')

% end of latency calculation

clear data

load([brainModels subject '.mat'])



normalized = (latencies- min(latencies)) / (max(latencies) - min(latencies));
storeZeros = find(normalized == 0);
normalized = 1-normalized;
normalized(storeZeros) = 0;
numColors = size(map, 1);
colorIndices = ceil(normalized * numColors);
colorIndices(colorIndices < 1) = 1;  % Ensure indices are within the valid range
rgbArray = map(colorIndices, :);

radiusSizes = (normalized*3)+1;
radiusSizes(storeZeros) = 1.5;

legends = [1.5:0.4604:3.8020];
legendAxis = [100,0,-20;100,0,-10;100,0,0;100,0,10;100,0,20;100,0,30];
legendColor = [0,0,0;51,0,0;102,0,0;153,0,0;204,0,0;255,0,0]/255;

indexedChans = channels(index,:);
indexedColors = rgbArray(index,:);
indexedRadiuses = radiusSizes(index);
indexedStimulated = stimulated(index);


figure('Position',[ 480          10        2596        1327]);

for ii = 1:length(indexedStimulated)
if indexedStimulated(ii) == 1
    plotBallsOnVolume(gca,indexedChans(ii,:),[1,0,1],1.5)
else
    plotBallsOnVolume(gca,indexedChans(ii,:),indexedColors(ii,:),indexedRadiuses(ii))
end
hold on
end

[surface] = plotProjectedRegions(out,regionColors);
set(gca,'CameraViewAngleMode','Manual')
axis equal
for ii = 1:length(surface)
surface(ii).FaceAlpha = 0.3;
end
surface(2).FaceAlpha = 0.03;
surface(3).FaceAlpha = 0.03;
zoom(1)


%create legend

mkdir([saveDir 'limbicGlassBrains/']);
view([180 0])%for anterior view
saveas(gcf,[saveDir 'limbicGlassBrains/' chosenFiles{i} '_anterior.svg'])
curAxis = [xlim;ylim;zlim];

view([270,0])%for sagital
saveas(gcf,[saveDir 'limbicGlassBrains/' chosenFiles{i} '_sagital.svg'])

view([-180,-90])%for under coronal
saveas(gcf,[saveDir 'limbicGlassBrains/' chosenFiles{i} '_coronal.svg'])

close all

figure('Position',[ 480          10        2596        1327])
for ii = 1:length(legends)
h{ii} = plotBallsOnVolume(gca,legendAxis(ii,:),legendColor(ii,:),legends(ii));
end
zoom(1)
axis equal
xlim(curAxis(1,:))
ylim(curAxis(2,:))
zlim(curAxis(3,:))
view([180 0])
saveas(gcf,[saveDir 'limbicGlassBrains/' chosenFiles{i} '_legend.svg'])
close all

end

%% exxample CCEPS
selChanIDX = [201:205];
set(0,'DefaultFigureRenderer','painters')

 for i = 1:length(chosenFiles)

    data = load([fileNameDir chosenFiles{i}]);
    subject = data.subjectName;
    channels = data.VERA.tala.electrodes;
    channelNames = cellfun(@(x)x(end),data.VERA.electrodeDefinition.Label,'UniformOutput',false);
    meanResponses = nanmean(data.lowPassSPESZScore,3);
    stdResponses = nanstd(data.lowPassSPESZScore,[],3);

    curDat = meanResponses(selChanIDX(i,:),:);
    curVar = stdResponses(selChanIDX(i,:),:);

for ii = 1:length(selChanIDX)
m = curDat(ii,:);
s= curVar(ii,:);

figure('position',[       -2068         544         888         713]);
    ylim([-10 10])
    xlim([-250 500])
     a = patch([10 10 100 100],[min(ylim) max(ylim) max(ylim) min(ylim)],[.25,.25,.25],'EdgeColor','None','FaceAlpha',0.15);
     hold on
    plot(timeVector, m,'Color','r','LineWidth',1);
    hold on
    plot([0 0], [-10 10],'--','color','k','linewidth',1) 
    jbfill(timeVector, m+s, m-s, 'r','r', 1, 0.2);

    ylabel('z-score')
    xlabel('Time (ms)')
    ylim([-10 10])
    xlim([-250 500])
    box off
    set(gca,'LineWidth',0.75,'XColor','k','YColor','k')

    mkdir([saveDir 'exemplarCCEPs/']);
    saveas(gcf,[saveDir 'exemplarCCEPs/' chosenFiles{i} 'chan' num2str(selChanIDX(i,ii)) '.svg'])
    close all
end
 end



%% Chose exemplars
currentFile = dataFiles{21};
load([fileNameDir currentFile]);
recorded = {'G_and_S_frontomargin'
'G_and_S_transv_frontopol'
'G_front_inf-Opercular'
'G_front_inf-Orbital'
'G_front_inf-Triangul'
'G_front_middle'
'G_front_sup'
'S_calcarine'
'S_front_inf'
'S_front_middle'
'S_front_sup'
'G_orbital'
'G_rectus'
'S_orbital_lateral'
'S_orbital_med-olfact'
'S_orbital-H_Shaped'
'S_suborbital'};


recorded = [listHip,recorded'];

index = find(contains([data.VERA.SecondaryLabel{:}],recorded))';

length_samples = 3800;
% Sampling rate
fs = data.samplingRate; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

ch1IDX = index(3);
ch2IDX = index(4);
%%
dat1 = data.lowPassSPES(ch1IDX,:,:);
dat2 = data.lowPassSPES(ch2IDX,:,:);
m1 = squeeze(mean(dat1,3));
m2 = squeeze(mean(dat2,3));
s1 = squeeze(std(dat1,0,3));%./size(dat1,3);
s2 = squeeze(std(dat2,0,3));%./size(dat2,3);

%% individual trials + mean

figure('position',[       -2068         544         888         713]);
plot([0 0], [-40 40],'--','color','k','linewidth',1) 
hold on
for trial = 1:size(dat1,3)


plot(timeVector,squeeze(dat1(:,:,trial)),'Color',[0.5,0.5,0.5,0.3],'linewidth',.75);
hold on

end

plot(timeVector,m1,'Color','r','linewidth',2);

ylim([-40 40])
yticks([-40:20:40])
xticks([-1000:500:1000])
ylabel(['\muV'])
xlabel('Time to Stimulation (ms)')
box off
set(gca,'LineWidth',0.75,'XColor','k','YColor','k','FontSize',24)

%% shading for se
figure('position',[       -2068         544         888         713]);
plot([0 0], [-40 40],'--','color','k','linewidth',1) 
hold on

plot(timeVector,m1,'Color','r','linewidth',2);
hold on
jbfill(timeVector, m1+s1, m1-s1, 'r','r', 1, 0.3);
hold on

ylim([-40 40])
yticks([-40:20:40])
xticks([-1000:500:1000])
ylabel(['\muV'])
xlabel('Time to Stimulation (ms)')
box off
set(gca,'LineWidth',0.75,'XColor','k','YColor','k','FontSize',24)
%% no shading
figure('position',[       -2068         544         888         713]);
plot([0 0], [-40 40],'--','color','k','linewidth',1) 
hold on

plot(timeVector,m1,'Color','r','linewidth',2);
hold on

ylim([-40 40])
yticks([-40:20:40])
xticks([-1000:500:1000])
ylabel(['\muV'])
xlabel('Time to Stimulation (ms)')
box off

set(gca,'LineWidth',0.75,'XColor','k','YColor','k','FontSize',24)


%% shading for se

chanIDX = [200:205];

for ch = 1:length(chanIDX)

dat = data.lowPassSPES(chanIDX(ch),:,:);
m1 = squeeze(mean(dat,3));
s1 = squeeze(std(dat,0,3));

figure('position',[       -2068         544         888         713]);
plot([0 0], [-40 40],'--','color','k','linewidth',1) 
hold on

plot(timeVector,m1,'Color','r','linewidth',2);
hold on
jbfill(timeVector, m1+s1, m1-s1, 'r','r', 1, 0.2);
hold on

ylim([-40 40])
yticks([-40:20:40])
xticks([-1000:500:1000])
ylabel(['\muV'])
xlabel('Time to Stimulation (ms)')
box off
set(gca,'LineWidth',0.75,'XColor','k','YColor','k','FontSize',24,'FontName','Arial')

saveas(gcf,['/Volumes/Samsung_T5/cingulateConnectivity/figures/hippocampusFrontalLobe/' data.VERA.channelNames{chanIDX(ch)} '.svg'])

end






clear
close all
addpath(genpath(cd))

fileNameDir = 'data/preprocessedHippocampus/';
files = dir(fileNameDir);
dataFiles = {files(24:end).name};

%
for i = 1:length(dataFiles)
currentFile = dataFiles{i};

load([fileNameDir currentFile]);
% find target channels
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

index = find(contains([data.VERA.SecondaryLabel{:}],recorded))';

length_samples = 3800;
% Sampling rate
fs = data.samplingRate; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

figure();

[rows,columns,channelNumber] = getSubplotDimensions(length(index));
count = 1;
parfor ch = 1:length(index)

    curChan = index(ch)
    subplot(rows,columns,ch)
    curDat = data.lowPassSPES(curChan,:,:);
    plot(timeVector, squeeze(mean(curDat,3)))
    hold on
    title([data.VERA.channelNames{curChan} ' : ' [data.VERA.SecondaryLabel{curChan}]])
    ylim([-40 40])
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






%% analyze EEG
clear
addpath(genpath(cd))
load('data/pooledData.mat')
load("code/dependencies/SEEGClinical22ChanLoc_xyz.mat") % EEG Channel Info

%% Group data by region stimulated (ACC, MCC, PCC)
rightACC = {'ctx_rh_G_and_S_cingul-Ant','wm_rh_G_and_S_cingul-Ant'};
leftACC = {'ctx_lh_G_and_S_cingul-Ant','wm_lh_G_and_S_cingul-Ant'};

rightMCC = {'ctx_rh_G_and_S_cingul-Mid-Ant','ctx_rh_G_and_S_cingul-Mid-Post','wm_rh_G_and_S_cingul-Mid-Ant','wm_rh_G_and_S_cingul-Mid-Post'};
leftMCC = {'ctx_lh_G_and_S_cingul-Mid-Ant','ctx_lh_G_and_S_cingul-Mid-Post','wm_lh_G_and_S_cingul-Mid-Ant','wm_lh_G_and_S_cingul-Mid-Post'};

rightPCC = {'ctx_rh_G_cingul-Post-dorsal', 'ctx_rh_G_cingul-Post-ventral' , 'wm_rh_G_cingul-Post-dorsal','wm_rh_G_cingul-Post-ventral'};
leftPCC = {'ctx_lh_G_cingul-Post-dorsal','ctx_lh_G_cingul-Post-ventral','wm_lh_G_cingul-Post-dorsal','wm_lh_G_cingul-Post-ventral'};

ACC = [rightACC, leftACC];
MCC = [rightMCC, leftMCC];
PCC = [rightPCC, leftPCC];

aColor = getColors('lush lilac');
mColor = getColors('celadon porcelain');
pColor = getColors('lago blue');

colors = [aColor;mColor;pColor];

colors2 = [aColor;aColor;mColor;mColor;pColor;pColor];

stimRegion = [pooledData.EEGStimulatedRegion{:}];

%index groups

idx.lACC = find(ismember(stimRegion,leftACC));
idx.rACC = find(ismember(stimRegion,rightACC));

idx.lMCC = find(ismember(stimRegion,leftMCC));
idx.rMCC = find(ismember(stimRegion,rightMCC));

idx.lPCC = find(ismember(stimRegion,leftPCC));
idx.rPCC = find(ismember(stimRegion,rightPCC));

length_samples = 3800;
% Sampling rate
fs = 2000; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

%% compile groups

fns = fieldnames(idx);

for g = 1:length(fns)

    curDat = pooledData.EEG(:,idx.(fns{g}));
    curChans = pooledData.EEGChannelNumber(idx.(fns{g}));

    uniqueChans = unique(curChans);

for ch = 1:length(uniqueChans)
curIDX = find(curChans == uniqueChans(ch));

curMean = nanmean(curDat(:,curIDX),2);
curSE = nanstd(curDat(:,curIDX),0,2)./length(curIDX);

storeMean(ch,:) = curMean;
storeSE(ch,:) = curSE;

end
groups.(fns{g}).mean = storeMean;
groups.(fns{g}).se = storeSE;

clear storeMean storeSE

end

%% plot time traces of each channel for each group
groupFNS = fieldnames(groups);

for g = 1:length(groupFNS)

    if g == 1 || g == 2

        curColor = aColor;
    elseif g == 3 || g == 4

        curColor = mColor;

    elseif g == 5 || g == 6
        curColor = pColor;
    end

    curMean = groups.(groupFNS{g}).mean;
    curSE = groups.(groupFNS{g}).se;
    
    [r, c , num] = getSubplotDimensions(size(curMean,1));

    figure('Position',[268         631        1183         547]);
    for ch = 1:size(curMean,1)
    subplot(r,c,ch)

    plot(timeVector, curMean(ch,:),'Color',curColor,'LineWidth',2)
    title(EEGChans(ch).labels)
    ylim([-2 2])
    box off
    ylabel('\muV')
    xlabel('Time (ms)')
    end

    sgtitle(groupFNS{g})

end

%% make a video
ch = 2;
vidObj = VideoWriter('figures/EEGVideolowFR')
vidObj.FrameRate = 60;
open(vidObj)
purpleMap = brewermap([],"Purples");
greenMap = brewermap([],"Greens");
blueMap = brewermap([],"Blues");

figure('Position',[345           1        1987        1336]);

for time = 1:20:3800
clf

%left topo ACC
subplot(3,4,1);
ax1 = gca;
topoplot(groups.lACC.mean(:,time),EEGChans,'shading','interp','whitebk','on','conv','on')

caxis([-2 2])
colorbar('fontsize',12,'color','black')

%right topo ACC
subplot(3,4,2);
ax2 = gca;
topoplot(groups.rACC.mean(:,time),EEGChans,'shading','interp','whitebk','on','conv','on')

caxis([-2 2])
colorbar('fontsize',12,'color','black')

% time series ACC
subplot(3,4,[3 4])

curMeanL = std(groups.lACC.mean,0,1);
curMeanR = std(groups.rACC.mean,1);

plot([0 0], [-2 2],'--','color',[0.5,0.5,0.5,0.5],'linewidth',2)
hold on
plot([timeVector(time) timeVector(time)], [-2 2],'--','color','r','linewidth',2)
hold on
plot(timeVector,curMeanL,'Color',aColor,'linewidth',3);
plot(timeVector,curMeanR,'--','Color',aColor,'linewidth',3);
box off
ylabel('Global Field Power (STD)')
xlabel('Time (ms)')
ylim([-0 2])
set(gca,'Fontsize',24,'linewidth',0.75,'FontName','Helvetica')


subplot(3,4,5);
ax3 = gca;
topoplot(groups.lMCC.mean(:,time),EEGChans,'shading','interp','whitebk','on','conv','on')

caxis([-2 2])
colorbar('fontsize',12,'color','black')

subplot(3,4,6);
ax4 = gca;
topoplot(groups.rMCC.mean(:,time),EEGChans,'shading','interp','whitebk','on','conv','on')

caxis([-2 2])
colorbar('fontsize',12,'color','black')

subplot(3,4,[7 8])
curMeanL = std(groups.lMCC.mean,0,1);
curMeanR = std(groups.rMCC.mean,0,1);

plot([0 0], [-2 2],'--','color',[0.5,0.5,0.5,0.5],'linewidth',2)
hold on
plot([timeVector(time) timeVector(time)], [-2 2],'--','color','r','linewidth',2)
hold on
plot(timeVector,curMeanL,'Color',mColor,'linewidth',3);
plot(timeVector,curMeanR,'--','Color',mColor,'linewidth',3);
box off
ylabel('Global Field Power (STD)')
xlabel('Time (ms)')
set(gca,'Fontsize',24,'linewidth',0.75,'FontName','Helvetica')
ylim([-0 2])

subplot(3,4,9);
ax5 = gca;
topoplot(groups.lPCC.mean(:,time),EEGChans,'shading','interp','whitebk','on','conv','on')

caxis([-2 2])
colorbar('fontsize',12,'color','black')

subplot(3,4,10);
ax6 = gca;
topoplot(groups.rPCC.mean(:,time),EEGChans,'shading','interp','whitebk','on','conv','on')

caxis([-2 2])
colorbar('fontsize',12,'color','black')

subplot(3,4,[11 12])
curMeanL = std(groups.lPCC.mean,0,1);

curMeanR = std(groups.rPCC.mean,0,1);

plot([0 0], [-2 2],'--','color',[0.5,0.5,0.5,0.5],'linewidth',2)
hold on
plot([timeVector(time) timeVector(time)], [-2 2],'--','color','r','linewidth',2)
hold on
plot(timeVector,curMeanL,'Color',pColor,'linewidth',3);
plot(timeVector,curMeanR,'--','Color',pColor,'linewidth',3);
box off
ylabel('Global Field Power (STD)')
xlabel('Time (ms)')
set(gca,'Fontsize',24,'linewidth',0.75,'FontName','Helvetica')
ylim([-0 2])

colormap(ax1,purpleMap)
colormap(ax2, purpleMap)
colormap(ax3, greenMap)
colormap(ax4, greenMap)
colormap(ax5, blueMap)
colormap(ax6, blueMap)

writeVideo(vidObj,getframe(gcf));
end

close(vidObj);


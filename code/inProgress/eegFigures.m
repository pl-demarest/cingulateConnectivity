%% analyze EEG
clear
addpath(genpath(cd))
pooledData = load('data/pooledData.mat');
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

fns = fieldnames(idx);

%includedChannels = [2,3,4,7,8,9,20,21,22];

%EEGChans = EEGChans(includedChannels);

%% compile groups for median traces 


for g = 1:length(fns)

    curDat = pooledData.EEG(:,idx.(fns{g}));
    curChans = pooledData.EEGChannelNumber(idx.(fns{g}));
    uniqueChans = unique(curChans);

for ch = 1:length(uniqueChans)
curIDX = find(curChans == uniqueChans(ch));

curMean = nanmedian(curDat(:,curIDX),2);
curSE = nanstd(curDat(:,curIDX),0,2)./length(curIDX);

storeMean(ch,:) = curMean;
storeSE(ch,:) = curSE;

end
groups.(fns{g}).mean = storeMean;
groups.(fns{g}).se = storeSE;

clear storeMean storeSE

end

%% Global Field Power Figures


figure("Position",[ 916         280        1072         876]);
curMeanL = std(groups.lACC.mean,0,1);
curMeanR = std(groups.rACC.mean,0,1);
plot([0 0], [-2 2],'--','color',[0.5,0.5,0.5,0.5],'linewidth',2)
hold on
hold on
plot(timeVector,curMeanL,'Color',aColor,'linewidth',3);
plot(timeVector,curMeanR,'--','Color',aColor,'linewidth',3);
box off
ylabel('Global Field Power (STD)')
xlabel('Time (ms)')
set(gca,'Fontsize',24,'linewidth',0.75,'FontName','Helvetica')
ylim([-0 0.75])
saveas(gcf,'/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/GFPACC.svg')

figure('Position',[ 916         280        1072         876]);
curMeanL = std(groups.lMCC.mean,0,1);
curMeanR = std(groups.rMCC.mean,0,1);
plot([0 0], [-2 2],'--','color',[0.5,0.5,0.5,0.5],'linewidth',2)
hold on
hold on
plot(timeVector,curMeanL,'Color',mColor,'linewidth',3);
plot(timeVector,curMeanR,'--','Color',mColor,'linewidth',3);
box off
ylabel('Global Field Power (STD)')
xlabel('Time (ms)')
set(gca,'Fontsize',24,'linewidth',0.75,'FontName','Helvetica')
ylim([-0 0.75])
saveas(gcf,'/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/GFPMCC.svg')

figure('Position',[ 916         280        1072         876]);
curMeanL = std(groups.lPCC.mean,0,1);
curMeanR = std(groups.rPCC.mean,0,1);
plot([0 0], [-2 2],'--','color',[0.5,0.5,0.5,0.5],'linewidth',2)
hold on
hold on
plot(timeVector,curMeanL,'Color',pColor,'linewidth',3);
plot(timeVector,curMeanR,'--','Color',pColor,'linewidth',3);
box off
ylabel('Global Field Power (STD)')
xlabel('Time (ms)')
set(gca,'Fontsize',24,'linewidth',0.75,'FontName','Helvetica')
ylim([-0 0.75])
saveas(gcf,'/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/GFPPCC.svg')

%% compile and extract erp features
storeAmp = [];
storeLatency = [];
storeGroupID = [];
storeChan = [];
storeDuration = [];
count = 1;

for g = 1:length(fns)

    if g == 1 || g == 2

        curColor = aColor;
    elseif g == 3 || g == 4

        curColor = mColor;

    elseif g == 5 || g == 6
        curColor = pColor;
    end

    curDat = getZScore(pooledData.EEGERP(:,idx.(fns{g})),1:1700);
    curChans = pooledData.EEGChannelNumber(idx.(fns{g}));

    uniqueChans = unique(curChans);

    figure();
    [r, c, num] = getSubplotDimensions(length(uniqueChans));

    for ch = 1:length(uniqueChans)
    subplot(r,c,ch)
    curIDX = find(curChans == uniqueChans(ch));
    tempDat = curDat(:,curIDX);
    temp=[];
        for i = 1:size(curIDX,2)
        %unitNormalize
        temp(i,:) = tempDat(:,i)/norm(tempDat(:,i));
        
        plot(timeVector, temp(i,:),'Color',[.8,.8,.8,0.5])

        hold on
        end
       storeERP(ch,:) = nanmean(temp,1);
       plot(timeVector,storeERP(ch,:),'Color',curColor,'LineWidth',1.5)

       erpON = findchangepts(diff(storeERP(ch,:)),MaxNumChanges=2,Statistic="rms"); %use first index of changepoints of the slope
       erpOFF = findchangepts(storeERP(ch,:),MaxNumChanges=2,Statistic='linear'); %use second index for offset by mean and slope

       if ~isempty(erpON)
           if (erpON(1) < 1700) || (erpON(1) > 2300)
           erpON = [];
           end
       end
       
       if isempty(erpON) && isempty(erpOFF)

        erpDetection(g,ch,:) = [nan,nan];
       
       elseif isempty(erpON) && ~isempty(erpOFF)
        
        if ~isscalar(erpOFF)
        erpDetection(g,ch,:) = erpOFF;
        elseif isscalar(erpOFF) && (erpOFF > 2300 || erpOFF <1700)
        erpDetection(g,ch,:) = [nan,nan];
        else
        erpDetection(g,ch,:) = [erpOFF, length(storeERP(ch,:))];
        end

       elseif isscalar(erpOFF) && ~isempty(erpON)

       erpDetection(g,ch,:) = [erpON(1), erpOFF(1)];
       %adjust depending on whether or not a response is detected:

       else
       erpDetection(g,ch,:) = [erpON(1), erpOFF(2)];

       end
        

       if ~any(isnan(erpDetection(g,ch,:)))
       storeAmplitude(count) = rms(groups.(fns{g}).mean(ch,erpDetection(g,ch,1):erpDetection(g,ch,2)));
       storeDuration(count) = erpDetection(g,ch,2) - erpDetection(g,ch,1);
       storeLatency(count) = erpDetection(g,ch,1);

       else
       storeAmplitude(count) = nan;
       storeDuration(count) = nan;
       storeLatency(count) = nan;
       end

    
    storeChan(count) = ch;
    storeGroupID(count) = g;
    count = count+1;

    end
    


    % using the detected changepoints and the latency, store vlaues, store
    % group label values to generate topoplots

    ERPMag.(fns{g}).mean = storeERP;
    ERPMag.(fns{g}).erpDetection = erpDetection;

end

%% Create a topoplot for each group

normAmp = normalize(storeAmplitude,'range',[.1,1]);
normDur = normalize(storeDuration,'range',[.1,1]);
normLat = normalize(storeDuration,'range',[.1,1]);

topoplotsettings={'style','fill','conv','on', 'shading','interp','whitebk','on','conv','on','interplimits','electrodes'};

uniqueGroups = unique(storeGroupID);

latencyRanks = [];

for g = uniqueGroups

    if g == 1 || g == 2

        curColor = getColors('lush lilac gradient');
        if g == 1
            title = 'l_ACC';
        else
            title = 'r_ACC';
        end

    elseif g == 3 || g == 4

        curColor = getColors('celadon porcelain gradient');

        if g == 3
            title = 'l_MCC';
        else
            title = 'r_MCC';
        end

    elseif g == 5 || g == 6
        curColor = getColors('lago blue gradient');

        if g == 5
            title = 'l_PCC';
        else
            title = 'r_PCC';
        end
    end

    groupIDX = (storeGroupID == g);

    %normalize everything, excluding values of 0
    
    %curAmp = normAmp(groupIDX);
    curAmp = normalize(storeAmplitude(groupIDX),'range',[0 1]);
    nanIDX = isnan(curAmp);
    curAmp(nanIDX) = 0;

    figure();
    topoplot(curAmp,EEGChans,topoplotsettings{:});
    caxis([0 1])
    colorbar('fontsize',12,'color','black')
    colormap(curColor)
    saveas(gcf,['/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/sfn2024/' title '_amplitude.svg'])
    
    %curDur = normDur(groupIDX);
    curDur = normalize(storeDuration(groupIDX),'range',[0,1]);
    nanIDX = isnan(curDur);
    curDur(nanIDX) = 0;

    figure();
    topoplot(curDur,EEGChans,topoplotsettings{:});
    caxis([0 1])
    colorbar('fontsize',12,'color','black')
    colormap(curColor)
    saveas(gcf,['/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/sfn2024/' title '_duration.svg'])


    %curLat = normLat(groupIDX);
    curLat = normalize(storeLatency(groupIDX),'range',[0,1]);
    
    [~,index] = sort(curLat);
    disp({EEGChans(index).labels})

    figure();
    topoplot(curLat,EEGChans,topoplotsettings{:});
    caxis([0 1])
    colorbar('fontsize',12,'color','black')
    colormap(flip(curColor))
    saveas(gcf,['/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/sfn2024/' title '_latency.svg'])
    



end

%% obtain data for amplitude


for g = 1:length(fns)

    curDat = pooledData.EEG(:,idx.(fns{g}));
    curChans = pooledData.EEGChannelNumber(idx.(fns{g}));
    uniqueChans = unique(curChans);

for ch = 1:length(uniqueChans)

    curPoints = erpDetection(g,ch,:);
    curIDX = find(curChans == uniqueChans(ch));
    

    storeDat = [];
    for  i = 1:length(curIDX)
    tempDat = curDat(:,curIDX(i));

    

       if ~any(isnan(erpDetection(g,ch,:)))
        storeDat(i) = rms(tempDat(curPoints(1):curPoints(2)));

       else
        storeDat(i) = nan;
       end


    end
    
    ampDat(g,ch) = nanmean(storeDat);
    ampSE(g,ch) = nanstd(storeDat)/sqrt(length(storeDat));

end

end


%% Create a bar graph with 

left = [1,3,5];
right = [2,4,6];

frontal = [2,20,7];

dat = ampDat(left,frontal)';
var = ampSE(left,frontal)';

figure('Position',[1140         308        1041         849]);
b = bar(dat,'EdgeColor','none');
hold on
% Calculate the number of groups and number of bars in each group
[ngroups,nbars] = size(dat);
% Get the x coordinate of the bars
x = nan(nbars, ngroups);
for i = 1:nbars
    x(i,:) = b(i).XEndPoints;
end
% Plot the errorbars
errorbar(x',dat,var,'k','linestyle','none');
hold off
xticklabels({'F3', 'Fz', 'F4'});
ylim([0 1.3])
box off
b(1).FaceColor = aColor;
b(2).FaceColor = mColor;
b(3).FaceColor = pColor;

saveas(gcf,'/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/sfn2024/amplitudeBarFrontalLeft.svg')

dat = ampDat(right,frontal)';
var = ampSE(right,frontal)';

figure('Position',[1140         308        1041         849]);
b = bar(dat,'EdgeColor','none');
hold on
% Calculate the number of groups and number of bars in each group
[ngroups,nbars] = size(dat);
% Get the x coordinate of the bars
x = nan(nbars, ngroups);
for i = 1:nbars
    x(i,:) = b(i).XEndPoints;
end
% Plot the errorbars
errorbar(x',dat,var,'k','linestyle','none');
hold off
xticklabels({'F3', 'Fz', 'F4'});
ylim([0 1.3])
box off
b(1).FaceColor = aColor;
b(2).FaceColor = mColor;
b(3).FaceColor = pColor;

saveas(gcf,'/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/sfn2024/amplitudeBarFrontalRight.svg')

%%

somato = [3,21,8];

dat = ampDat(left,somato)';
var = ampSE(left,somato)';

figure('Position',[1140         308        1041         849]);
b = bar(dat,'EdgeColor','none');
hold on
% Calculate the number of groups and number of bars in each group
[ngroups,nbars] = size(dat);
% Get the x coordinate of the bars
x = nan(nbars, ngroups);
for i = 1:nbars
    x(i,:) = b(i).XEndPoints;
end
% Plot the errorbars
errorbar(x',dat,var,'k','linestyle','none');
hold off
xticklabels({'S3', 'Sz', 'S4'});
ylim([0 1.3])
box off
b(1).FaceColor = aColor;
b(2).FaceColor = mColor;
b(3).FaceColor = pColor;

saveas(gcf,'/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/sfn2024/amplitudeBarSomatoLeft.svg')

dat = ampDat(right,somato)';
var = ampSE(right,somato)';

figure('Position',[1140         308        1041         849]);
b = bar(dat,'EdgeColor','none');
hold on
% Calculate the number of groups and number of bars in each group
[ngroups,nbars] = size(dat);
% Get the x coordinate of the bars
x = nan(nbars, ngroups);
for i = 1:nbars
    x(i,:) = b(i).XEndPoints;
end
% Plot the errorbars
errorbar(x',dat,var,'k','linestyle','none');
hold off
xticklabels({'S3', 'Sz', 'S4'});
ylim([0 1.3])
box off
b(1).FaceColor = aColor;
b(2).FaceColor = mColor;
b(3).FaceColor = pColor;

saveas(gcf,'/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/sfn2024/amplitudeBarSomatoRight.svg')


%%

parietal = [4,22,9];


dat = ampDat(left,parietal)';
var = ampSE(left,parietal)';

figure('Position',[1140         308        1041         849]);
b = bar(dat,'EdgeColor','none');
hold on
% Calculate the number of groups and number of bars in each group
[ngroups,nbars] = size(dat);
% Get the x coordinate of the bars
x = nan(nbars, ngroups);
for i = 1:nbars
    x(i,:) = b(i).XEndPoints;
end
% Plot the errorbars
errorbar(x',dat,var,'k','linestyle','none');
hold off
xticklabels({'P3', 'Pz', 'P4'});
ylim([0 1.3])
box off
b(1).FaceColor = aColor;
b(2).FaceColor = mColor;
b(3).FaceColor = pColor;

saveas(gcf,'/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/sfn2024/amplitudeBarParietalLeft.svg')

dat = ampDat(right,parietal)';
var = ampSE(right,parietal)';

figure('Position',[1140         308        1041         849]);
b = bar(dat,'EdgeColor','none');
hold on
% Calculate the number of groups and number of bars in each group
[ngroups,nbars] = size(dat);
% Get the x coordinate of the bars
x = nan(nbars, ngroups);
for i = 1:nbars
    x(i,:) = b(i).XEndPoints;
end
% Plot the errorbars
errorbar(x',dat,var,'k','linestyle','none');
hold off
xticklabels({'P3', 'Pz', 'P4'});
ylim([0 1.3])
box off
b(1).FaceColor = aColor;
b(2).FaceColor = mColor;
b(3).FaceColor = pColor;

saveas(gcf,'/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/sfn2024/amplitudeBarParietalRight.svg')

%% resolve each individual trace across all participants for each channel

for g = 1:length(fns)


    if g == 1 || g == 2

        curColor = aColor;
    elseif g == 3 || g == 4

        curColor = mColor;

    elseif g == 5 || g == 6
        curColor = pColor;
    end

    curDat = pooledData.EEG(:,idx.(fns{g}));
    curChans = pooledData.EEGChannelNumber(idx.(fns{g}));

    uniqueChans = unique(curChans);

figure('Position',[268         631        1183         547]);
[r, c , num] = getSubplotDimensions(length(uniqueChans));

for ch = 1:length(uniqueChans)
curIDX = find(curChans == uniqueChans(ch));

subplot(r,c,ch)

for i = 1:length(curIDX)

plot(timeVector, curDat(:,curIDX(i)),'Color',[0.3,0.3,0.3,0.2],'LineWidth',.75)
hold on

end
hold on
curMean = nanmedian(curDat(:,curIDX),2);
plot(timeVector, curMean,'Color',curColor,'LineWidth',1.5)
hold off
ylim([-1 1])
end


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
    ylim([-1 1])
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

topoplotsettings={'style','map','conv','on', 'shading','interp','whitebk','on','conv','on','interplimits','electrodes'};

figure('Position',[345           1        1987        1336]);

for time = 1:20:3800
clf

%left topo ACC
subplot(3,4,1);
ax1 = gca;
topoplot(groups.lACC.mean(:,time),EEGChans,topoplotsettings{:})

caxis([-1 1])
colorbar('fontsize',12,'color','black')

%right topo ACC
subplot(3,4,2);
ax2 = gca;
topoplot(groups.rACC.mean(:,time),EEGChans,topoplotsettings{:})

caxis([-1 1])
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
ylim([-0 0.75])
set(gca,'Fontsize',24,'linewidth',0.75,'FontName','Helvetica')


subplot(3,4,5);
ax3 = gca;
topoplot(groups.lMCC.mean(:,time),EEGChans,topoplotsettings{:})

caxis([-1 1])
colorbar('fontsize',12,'color','black')

subplot(3,4,6);
ax4 = gca;
topoplot(groups.rMCC.mean(:,time),EEGChans,topoplotsettings{:})

caxis([-1 1])
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
ylim([-0 0.75])

subplot(3,4,9);
ax5 = gca;
topoplot(groups.lPCC.mean(:,time),EEGChans,topoplotsettings{:})

caxis([-1 1])
colorbar('fontsize',12,'color','black')

subplot(3,4,10);
ax6 = gca;
topoplot(groups.rPCC.mean(:,time),EEGChans,topoplotsettings{:})

caxis([-1 1])
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
ylim([-0 0.75])

colormap(ax1,purpleMap)
colormap(ax2, purpleMap)
colormap(ax3, greenMap)
colormap(ax4, greenMap)
colormap(ax5, blueMap)
colormap(ax6, blueMap)

writeVideo(vidObj,getframe(gcf));
end

close(vidObj);


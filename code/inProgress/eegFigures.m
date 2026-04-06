
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
            if erpOFF(1) < 1700 || erpOFF(1) > 2300
                erpDetection(g,ch,:) = [nan, nan];
            else
                erpDetection(g,ch,:) = erpOFF;
            end
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

%% Determine response progression across EEG scalp for each condition

%erpDetection organized as group x chan x [on off]

%get channel names

chanNames = pooledData.EEGChans(1:23);

%create a grid structure for spatial relationships between chans
chanGrid = {'F9','Fp1','FPz','Fp2','F10';'F7','F3','Fz','F4','F8';'T7','C3','Cz','C4','T8';'P7','P3','Pz','P4','P8';nan,'O1','Oz','O2',nan};

% Convert chanNames to cell array of label strings if stored as struct
if isstruct(chanNames)
    chanLabels = {chanNames.labels};
else
    chanLabels = chanNames;
end

% Build spatial adjacency matrix from channel grid layout (8-connected)
[adjMatrix, gridMap] = buildChanAdjacency(chanLabels, chanGrid);

% Compute and visualize propagation map for each group
nGroups = size(erpDetection, 1);

for g = 1:nGroups

    % Assign group color
    if g <= 2
        curColor = aColor;
    elseif g <= 4
        curColor = mColor;
    else
        curColor = pColor;
    end

    % Extract onset latencies for this group (first index of dim 3)
    onsetLat = erpDetection(g,:,1);
    onsetLat(onsetLat < 1700 | onsetLat > 2300) = NaN;

    % Compute propagation
    propagation(g) = computePropagation(onsetLat, adjMatrix);

    % Store latencies in ms for convenience
    if propagation(g).nValid > 0
        propagation(g).latenciesMs = timeVector(round(propagation(g).latencies));
    else
        propagation(g).latenciesMs = [];
    end

    % Display summary to console
    fprintf('\n=== %s: %d origins, %d responding channels ===\n', ...
        fns{g}, propagation(g).nOrigins, propagation(g).nValid);
    for i = 1:propagation(g).nValid
        ch = propagation(g).chanOrder(i);
        if propagation(g).isOrigin(i)
            fprintf('  [ORIGIN %d] #%d: %s (%.1f ms)\n', ...
                propagation(g).treeID(i), i, chanLabels{ch}, propagation(g).latenciesMs(i));
        else
            parentCh = propagation(g).parentChan(i);
            fprintf('  #%d: %s <- %s (%.1f ms)\n', ...
                i, chanLabels{ch}, chanLabels{parentCh}, propagation(g).latenciesMs(i));
        end
    end

    % Visualize propagation map
    plotPropagationMap(propagation(g), chanLabels, chanGrid, gridMap, ...
        fns{g}, curColor, timeVector);
    saveas(gcf, ['/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/' ...
        fns{g} '_propagation.svg'])

end

%% Generate Spectrograms (ERSP via newtimef)

fs = 2000;
nFramesERSP = size(pooledData.EEGERP, 1);
epochDurERSP = (nFramesERSP - 1) / fs * 1000;
tlimitsERSP = [-epochDurERSP/2, epochDurERSP/2];

for g = 1:nGroups

    curDat = pooledData.EEGERP(:, idx.(fns{g}));
    curChans = pooledData.EEGChannelNumber(idx.(fns{g}));
    uniqueChans = unique(curChans);

    for ch = 1:length(uniqueChans)
        curIDX = find(curChans == uniqueChans(ch));
        trialData = curDat(:, curIDX);

        [ersp, itc, ~, times, freqs] = newtimef( ...
            trialData, nFramesERSP, tlimitsERSP, fs, [2 0.5], ...
            'freqs', [4 40], ...
            'nfreqs', 100, ...
            'baseline', [tlimitsERSP(1) -10], ...
            'padratio', 4, ...
            'plotersp', 'off', ...
            'plotitc', 'off', ...
            'verbose', 'off');

        spectra.(fns{g}).ersp(ch,:,:) = ersp;
        spectra.(fns{g}).itc(ch,:,:) = itc;
    end

    spectra.(fns{g}).times = times;
    spectra.(fns{g}).freqs = freqs;
    fprintf('Completed ERSP: %s (%d channels)\n', fns{g}, length(uniqueChans));

end


%% Z-score ERSP to baseline at each frequency

for g = 1:nGroups
    curERSP = spectra.(fns{g}).ersp;
    curTimes = spectra.(fns{g}).times;
    baseIdx = curTimes < -50;
    nCh = size(curERSP, 1);

    for ch = 1:nCh
        for fi = 1:size(curERSP, 2)
            baseVals = curERSP(ch, fi, baseIdx);
            bMean = mean(baseVals(:));
            bStd = std(baseVals(:));
            if bStd > 0
                curERSP(ch, fi, :) = (curERSP(ch, fi, :) - bMean) / bStd;
            else
                curERSP(ch, fi, :) = curERSP(ch, fi, :) - bMean;
            end
        end
    end

    spectra.(fns{g}).erspZ = curERSP;
end


%% Visualize spectrograms (ERSP, z-scored)

globalMax = 0;
for g = 1:nGroups
    globalMax = max(globalMax, max(abs(spectra.(fns{g}).erspZ(:))));
end
cLim = [-5 5];

for g = 1:nGroups

    curERSP = spectra.(fns{g}).erspZ;
    curTimes = spectra.(fns{g}).times;
    curFreqs = spectra.(fns{g}).freqs;
    nCh = size(curERSP, 1);
    [rows, cols] = getSubplotDimensions(nCh);

    fig = figure('Position', [100 100 1600 900]);

    for ch = 1:nCh
        subplot(rows, cols, ch)
        imagesc(curTimes, curFreqs, squeeze(curERSP(ch,:,:)))
        set(gca, 'YDir', 'normal')
        caxis(cLim)
        hold on
        yline(15,'--','LineWidth',1)
        yline(30,'--','LineWidth',1)
        title(EEGChans(ch).labels, 'FontSize', 9)
        xlabel('Time (ms)')
        ylabel('Frequency (Hz)')
        set(gca, 'FontSize', 8, 'FontName', 'Helvetica')
        box off
    end

    sgtitle(fns{g}, 'FontSize', 16, 'FontWeight', 'bold', 'FontName', 'Helvetica')
    colormap(parula)

    cbAx = axes('Position', [0 0 1 1], 'Visible', 'off');
    caxis(cbAx, cLim);
    colormap(cbAx, parula);
    cb = colorbar(cbAx, 'Position', [0.94 0.06 0.015 0.88]);
    cb.FontSize = 10;
    cb.Label.String = 'Z-score';

    saveas(gcf, ['/Volumes/Samsung_T5/cingulateConnectivity/figures/legacy/' fns{g} '_spectrogram.svg'])

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

%% Helper Functions

function [adjMatrix, gridMap] = buildChanAdjacency(chanLabels, chanGrid)
%BUILDCHANADJACENCY Build adjacency matrix from channel grid layout.
%   Maps channel labels to their (row, col) positions in chanGrid and
%   determines 8-connected spatial adjacency between channels.
%
%   Inputs:
%       chanLabels - 1xN cell array of channel label strings
%       chanGrid   - RxC cell array defining spatial layout (NaN = empty)
%
%   Outputs:
%       adjMatrix  - NxN logical adjacency matrix
%       gridMap    - Nx2 matrix of [row, col] positions (NaN if unmapped)

    nChans = length(chanLabels);
    adjMatrix = false(nChans);
    gridMap = nan(nChans, 2);

    [nRows, nCols] = size(chanGrid);

    % Map each channel label to its grid position (case-insensitive)
    for ch = 1:nChans
        for r = 1:nRows
            for c = 1:nCols
                if ischar(chanGrid{r,c}) && strcmpi(chanGrid{r,c}, chanLabels{ch})
                    gridMap(ch,:) = [r, c];
                end
            end
        end
    end

    % Warn about unmapped channels
    unmapped = find(any(isnan(gridMap), 2));
    if ~isempty(unmapped)
        for u = 1:length(unmapped)
            warning('Channel "%s" (index %d) not found in chanGrid — excluded from adjacency.', ...
                chanLabels{unmapped(u)}, unmapped(u));
        end
    end

    % Build 8-connected adjacency matrix
    for i = 1:nChans
        if any(isnan(gridMap(i,:))); continue; end
        for j = i+1:nChans
            if any(isnan(gridMap(j,:))); continue; end
            rowDiff = abs(gridMap(i,1) - gridMap(j,1));
            colDiff = abs(gridMap(i,2) - gridMap(j,2));
            if rowDiff <= 1 && colDiff <= 1
                adjMatrix(i,j) = true;
                adjMatrix(j,i) = true;
            end
        end
    end
end

function prop = computePropagation(onsetLatencies, adjMatrix)
%COMPUTEPROPAGATION Determine ERP response propagation across scalp.
%   Uses a latency-ordered traversal with adjacency checking to identify
%   origin points and propagation paths.
%
%   Inputs:
%       onsetLatencies - 1xN vector of onset latencies (NaN = no response)
%       adjMatrix      - NxN logical adjacency matrix
%
%   Outputs:
%       prop - struct containing propagation results (see fields below)

    nChans = length(onsetLatencies);

    % Identify valid channels (non-NaN onset latency)
    validMask = ~isnan(onsetLatencies);
    validChans = find(validMask);
    validLats = onsetLatencies(validMask);

    % Sort by onset latency (ascending = earliest first)
    [sortedLats, sortIdx] = sort(validLats);
    chanOrder = validChans(sortIdx);
    nValid = length(chanOrder);

    % Initialize tracking arrays
    isOrigin = false(1, nValid);
    parentChan = nan(1, nValid);
    treeID = zeros(1, nValid);
    edges = [];
    visited = false(1, nChans);
    nTrees = 0;

    for i = 1:nValid
        ch = chanOrder(i);

        % Find all previously visited channels adjacent to current channel
        visitedChans = find(visited);
        adjacentVisited = visitedChans(adjMatrix(ch, visitedChans));

        if isempty(adjacentVisited)
            % No adjacent visited channel — mark as new origin
            nTrees = nTrees + 1;
            isOrigin(i) = true;
            treeID(i) = nTrees;
        else
            % Connect to the adjacent visited channel with the earliest onset
            adjLats = onsetLatencies(adjacentVisited);
            [~, minIdx] = min(adjLats);
            parentCh = adjacentVisited(minIdx);

            parentChan(i) = parentCh;
            edges = [edges; parentCh, ch]; %#ok<AGROW>

            % Inherit tree ID from parent
            parentOrderIdx = find(chanOrder == parentCh);
            treeID(i) = treeID(parentOrderIdx);
        end

        visited(ch) = true;
    end

    % Package results
    prop.chanOrder = chanOrder;
    prop.latencies = sortedLats;
    prop.latenciesMs = [];  % populated in main code with timeVector
    prop.isOrigin = isOrigin;
    prop.parentChan = parentChan;
    prop.treeID = treeID;
    prop.edges = edges;
    prop.nOrigins = nTrees;
    prop.nValid = nValid;

    % Create full-channel maps (NaN for non-responding channels)
    prop.fullTreeID = nan(1, nChans);
    prop.fullOrder = nan(1, nChans);
    for i = 1:nValid
        prop.fullTreeID(chanOrder(i)) = treeID(i);
        prop.fullOrder(chanOrder(i)) = i;
    end
end

function plotPropagationMap(prop, chanLabels, chanGrid, gridMap, groupName, baseColor, timeVector)
%PLOTPROPAGATIONMAP Visualize ERP propagation across the scalp grid.
%   Draws a grid-based map showing origin points, propagation arrows,
%   and temporal ordering of ERP responses.
%
%   Inputs:
%       prop       - propagation struct from computePropagation
%       chanLabels - 1xN cell array of channel label strings
%       chanGrid   - RxC cell array defining spatial layout
%       gridMap    - Nx2 matrix of [row, col] positions
%       groupName  - string label for the group (e.g. 'lACC')
%       baseColor  - 1x3 RGB color for the group
%       timeVector - 1xT time vector (samples to ms mapping)

    [nRows, nCols] = size(chanGrid);
    nChans = length(chanLabels);

    % Generate distinct colors for each propagation tree
    nTrees = max(prop.nOrigins, 1);
    if nTrees == 1
        treeColors = baseColor;
    else
        treeColors = zeros(nTrees, 3);
        baseHSV = rgb2hsv(baseColor);
        for t = 1:nTrees
            f = (t-1) / (nTrees-1);
            curHSV = baseHSV;
            curHSV(2) = baseHSV(2) * (1 - 0.5*f);
            curHSV(3) = min(1, baseHSV(3) + 0.3*f);
            treeColors(t,:) = hsv2rgb(curHSV);
        end
    end

    figure('Position', [100, 100, 650, 750]);
    hold on;

    % Draw each channel as a circle on the grid
    for ch = 1:nChans
        if any(isnan(gridMap(ch,:))); continue; end

        x = gridMap(ch, 2);
        y = nRows + 1 - gridMap(ch, 1);  % flip so row 1 is at top

        orderIdx = prop.fullOrder(ch);

        if isnan(orderIdx)
            % No detected response — gray circle
            scatter(x, y, 600, [0.85 0.85 0.85], 'filled', ...
                'MarkerEdgeColor', [0.6 0.6 0.6], 'LineWidth', 1);
            text(x, y, chanLabels{ch}, 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', 'FontSize', 8, ...
                'Color', [0.5 0.5 0.5]);
        else
            treeIdx = prop.fullTreeID(ch);
            curColor = treeColors(min(treeIdx, size(treeColors,1)), :);

            if prop.isOrigin(orderIdx)
                % Origin: double-ring border
                scatter(x, y, 900, curColor*0.6, 'filled', ...
                    'MarkerEdgeColor', 'k', 'LineWidth', 2.5);
                scatter(x, y, 600, curColor, 'filled', ...
                    'MarkerEdgeColor', curColor*0.6, 'LineWidth', 2);
            else
                % Propagated response
                scatter(x, y, 600, curColor, 'filled', ...
                    'MarkerEdgeColor', 'k', 'LineWidth', 1);
            end

            % Channel name
            text(x, y + 0.13, chanLabels{ch}, 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', 'FontSize', 8, 'FontWeight', 'bold');

            % Temporal rank and latency in ms
            latMs = timeVector(round(prop.latencies(orderIdx)));
            text(x, y - 0.08, sprintf('#%d', orderIdx), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontSize', 7.5, 'FontWeight', 'bold');
            text(x, y - 0.25, sprintf('%.0f ms', latMs), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontSize', 6.5, 'Color', [0.3 0.3 0.3]);
        end
    end

    % Draw propagation arrows
    for e = 1:size(prop.edges, 1)
        fromCh = prop.edges(e, 1);
        toCh = prop.edges(e, 2);

        x1 = gridMap(fromCh, 2);
        y1 = nRows + 1 - gridMap(fromCh, 1);
        x2 = gridMap(toCh, 2);
        y2 = nRows + 1 - gridMap(toCh, 1);

        dx = x2 - x1;
        dy = y2 - y1;
        len = sqrt(dx^2 + dy^2);

        if len > 0
            % Shorten arrow to avoid overlapping circles
            shrinkDist = 0.35;
            sx = x1 + shrinkDist * dx / len;
            sy = y1 + shrinkDist * dy / len;
            adx = dx - 2 * shrinkDist * dx / len;
            ady = dy - 2 * shrinkDist * dy / len;

            quiver(sx, sy, adx, ady, 0, ...
                'Color', [0.15 0.15 0.15], 'LineWidth', 2, ...
                'MaxHeadSize', 0.5);
        end
    end

    hold off;
    axis equal;
    xlim([0.3, nCols + 0.7]);
    ylim([0.3, nRows + 0.7]);
    axis off;

    if prop.nOrigins == 1
        originStr = 'origin';
    else
        originStr = 'origins';
    end
    title(sprintf('Response Propagation: %s (%d %s)', ...
        groupName, prop.nOrigins, originStr), ...
        'FontSize', 14, 'FontName', 'Helvetica');
end

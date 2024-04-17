% use this to find a few exemplar CCEPs, then determine the effect of
% lowpass on the waveform, also use this to test the order and window
% length used for the sgolayfilter.

clear
close all

addpath(genpath(cd))
load('data/pooledData.mat')
sigIDX = [];
count = 0;

while length(sigIDX) < 30
count = count + 1;
sigIDX = intersect(find(pooledData.pValue < 0.05/length(pooledData.pValue)), find(pooledData.cohensD > min(maxk(pooledData.cohensD,count)))); %find significant channels
end

length_samples = 3800;
% Sampling rate
fs = 2000; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

[r, c] = getSubplotDimensions(length(sigIDX));

figure;
for i = 1:length(sigIDX)

    subplot(r,c,i)

    data = pooledData.CCEPs(:,sigIDX(i));

    plot(timeVector, data,'LineWidth',3)
    title(pooledData.stimulatedRegion{sigIDX(i)})

end

%% test lowpass frequencies of different cutoffs
freqs = [100,60,40,20,10];
frames = [11,21,41,81,101];

window = [3800/2-100:3800/2+150];


%%
testData = pooledData.CCEPs(:,sigIDX(2));

baseIDX = [1:length(testData)/2];
baseDat = testData(baseIDX);
vari = std(baseDat)*5;
threshold = max(diff(baseDat));

visualizeLowpass(testData,freqs,timeVector,vari)
visualizeLowpass(testData(window),freqs,timeVector(window),vari)

%%
testData = pooledData.CCEPs(:,sigIDX(6));
baseDat = testData(baseIDX);
vari = std(baseDat);

visualizeLowpass(testData,freqs,timeVector,vari)
visualizeLowpass(testData(window),freqs,timeVector(window),vari);

%%
testData= pooledData.CCEPs(:,sigIDX(8));
baseDat = testData(baseIDX);
vari = std(baseDat);
visualizeLowpass(testData,freqs,timeVector,vari)
visualizeLowpass(testData(window),freqs,timeVector(window),vari);

%%
testData = pooledData.CCEPs(:,sigIDX(20));
baseDat = testData(baseIDX);
vari = std(baseDat);
visualizeLowpass(testData,freqs,timeVector,vari)
visualizeLowpass(testData(window),freqs,timeVector(window),vari);

%%
visualizeSGFilter(testData,frames,timeVector,vari)

%% for exemplars, sigIDX used = 6 for ACC, 20 for MCC, 14 for PCC
testData = pooledData.CCEPs(:,sigIDX(14));
channelNum = pooledData.channelNumber(sigIDX(14));
import = load(pooledData.dataFileName{sigIDX(14)});
%
import2 = load(pooledData.coherenceFileName{sigIDX(14)});
%
data = import.data.spesSmallLaplaceZScore;
%
cohB = import2.coherenceStruct.baseline;
cohT = import2.coherenceStruct.task;

%
figure;
histogram(cohB(channelNum,:),25,'FaceColor','k','FaceAlpha',0.5,'BinWidth',0.025)
hold on
histogram(cohT(channelNum,:),25,'FaceColor',getColors('lago blue'),'FaceAlpha',0.7,'BinWidth',0.025)

ylabel('Count')

ylim([0 60])
yticks([0,20,40,60])
xlim([-.75 1])

set(gca,'fontsize',18,'FontName','Helvetica','XColor','k','YColor','k','LineWidth',0.75)
box off

mkdir('figures/methods/coherenceMethods/exemplars')
saveas(gcf,['figures/methods/coherenceMethods/distributionPCC.svg'])

%% plot and save some exemplars
exemplar = squeeze(data(channelNum,:,:));

for t = 1:size(exemplar,2)
    curDat = exemplar(:,t);
    figure('position',[1000        1122         660         116]);
    plot(curDat,'Color',getColors('modern orange'))
    mkdir('figures/methods/coherenceMethods/exemplars')
    saveas(gcf,['figures/methods/coherenceMethods/exemplars/trace' num2str(t) '.svg'])
end


%%
baseIDX = [1:length(testData)/2];
baseDat = testData(baseIDX);
vari = std(baseDat)*5;
threshold = max(diff(baseDat));
n1Window = [3800/2-100:3800/2+150];

%%
%detect peaks and plot within the n1 window
windowData = squeeze(data(channelNum,n1Window,:));

n1Data = testData(n1Window);
timeVectorW = timeVector(n1Window);

[p,l,w,pp] = findpeaks(n1Data,timeVectorW,'MinPeakHeight',vari,'Annotate','extents');

peakWindow = [l-w/2:l+w/2];
peakWindowIDX = find(timeVectorW >= min(peakWindow) & timeVectorW <= max(peakWindow));
notWindowIDX = find(timeVectorW <= min(peakWindow) & timeVectorW >= max(peakWindow));
peakIDX = find(timeVectorW == l(2));



%calculate dispersion ratio along the window
n1Var = var(windowData,[],2);

disRatio = n1Var./n1Data;

%%


figure('Position',[746         391        1013         823]);

plot(timeVector([3800/2-1000:3800]),testData([3800/2-1000:3800]),'color','k','LineWidth',2)

mkdir('figures/methods/n1PeakDetection/')
saveas(gcf,'figures/methods/n1PeakDetection/n1DetectionExemplarCCEP.svg')

%%

figure('Position',[746         391        1013         823]);

for t = 1:size(windowData,2)

    curTrial = windowData(peakWindowIDX,t);
    curPeak = windowData(peakIDX,t);

    curPeakWindow = timeVectorW(peakWindowIDX);

    %plot(timeVectorW(peakWindowIDX),curTrial,'color',[0,0,0,0.3],'LineWidth',1)
    hold on

    plot(timeVectorW,windowData(:,t),'color',[0,0,0,0.15],'LineWidth',0.5)
    hold on

    scatter(timeVectorW(peakIDX),curPeak,50,'o','MarkerFaceColor',getColors('modern orange'),'MarkerFaceAlpha',0.8,'MarkerEdgeColor','none')
    hold on
    
end


plot(timeVector(n1Window),repmat(vari,1,length(n1Data)),'LineWidth',2,'LineStyle','--','Color','k')
hold on
plot(timeVector(n1Window),-repmat(vari,1,length(n1Data)),'LineWidth',2,'LineStyle','--','color','k')
plot(timeVector(n1Window),n1Data,'color','k','LineWidth',2)
yl = ylim;
shift = 0.02*abs(yl(2)-yl(1));


plot(l,p+shift,"Marker","v",'MarkerFaceColor','k','MarkerEdgeColor','none','LineStyle','none','MarkerSize',12);

title('N1 Peak Detection')
set(gca,'FontSize',24,'FontName','Helvetica','LineWidth',0.75)
box off
grid off
ylabel('z-score')
xlabel('time to stim (ms)')
%%xticks([0,50])
mkdir('figures/methods/n1PeakDetection/')
saveas(gcf,'figures/methods/n1PeakDetection/n1DetectionExemplar.svg')
%%
%baseDat = data(channelNum,baseIDX,:);
baseDat = testData(baseIDX);
baseDat = baseDat(:);

peakDat = windowData(peakIDX,:);
peakDat = peakDat(:);

allDat = [baseDat; peakDat];

figure('position',[746         391        1013         823]);

y = zeros(size(baseDat));

[f1,xi] = ksdensity(baseDat);

f = (f1- min(f1)) / ( max(f1) - min(f1) );
histogramOffset = f + 0.5;

% Plotting

line = plot([min(allDat)-.5, max(allDat)+.5], [0, 0], 'k'); % number line
hold on


points = scatter([min(baseDat) max(baseDat)], [0,0], 80, '|', 'filled','MarkerEdgeColor','k','MarkerFaceColor','k','MarkerFaceAlpha',1); % plot data with random offset
hold on;

% Create offset line y-values
offsetY = ones(1,length(histogramOffset)) * 0.5;

% Fill the area between histogram and offset line

fillAreaX = [xi, fliplr(xi)];  % Go forward in x, then reverse back
fillAreaY = [histogramOffset, fliplr(offsetY)];  % Upper boundary first, then reverse back along lower boundary
fill(fillAreaX, fillAreaY, 'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none');

y = zeros(size(peakDat));

[f1,xi] = ksdensity(peakDat);

f = (f1- min(f1)) / ( max(f1) - min(f1) );
histogramOffset = f + 0.5;


points = scatter(peakDat, y, 40, 'o', 'filled','MarkerEdgeColor','none','MarkerFaceColor',getColors('modern orange')); % plot data with random offset
hold on;
points = scatter([min(baseDat) max(baseDat)], [0,0], 80, '|','MarkerEdgeColor','k','Linewidth',3); % plot data with random offset
hold on;
% Create offset line y-values
offsetY = ones(1,length(histogramOffset)) * 0.5;

% Fill the area between histogram and offset line

fillAreaX = [xi, fliplr(xi)];  % Go forward in x, then reverse back
fillAreaY = [histogramOffset, fliplr(offsetY)];  % Upper boundary first, then reverse back along lower boundary
fill(fillAreaX, fillAreaY, getColors('modern orange'), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
ylim([-2 2])
box off
set(gca,'YColor','none','FontName','Helvetica')


saveas(gcf,'figures/methods/n1PeakDetection/n1DetectionExemplarDistribution.svg')
%%

function visualizeLowpass(testData,freqs,timeVector,var)

colors =     flip([0.5000    0.5000    0.5000;
    0.6250    0.3750    0.3750;
    0.7500    0.2500    0.2500;
    0.8750    0.1250    0.1250;
    1.0000         0         0]);

figure('Position',[95         115         641        1121]);

for i = 1:length(freqs)
curFreq = freqs(i);
curCol = colors(i,:);

curDat = getLowPassData(testData,curFreq,5,2000);

%get the difference of peaks in the baseline:


subplot(length(freqs),1,i)

plot(timeVector,curDat,'color',curCol,'LineWidth',3)
hold on
% 

plot(timeVector,repmat(var,1,length(curDat)),'LineWidth',2,'LineStyle','--')
plot(timeVector,-repmat(var,1,length(curDat)),'LineWidth',2,'LineStyle','--')
% get upper and lower shift for the peak markers
yl = ylim;
shift = 0.1*abs(yl(2)-yl(1));

[p , l, w, pp] = findpeaks(curDat,timeVector,'MinPeakHeight',var);

plot(l,p+shift,"Marker","v",'MarkerFaceColor','k','MarkerEdgeColor','k','LineStyle','none');

[n , lk, wn, pn] = findpeaks(-curDat,timeVector,'MinPeakHeight',var);
plot(lk,-n-shift,"Marker","^",'MarkerFaceColor','k','MarkerEdgeColor','k','LineStyle','none');

title([num2str(curFreq) ' Hz Lowpass'])
set(gca,'FontSize',24)
box off
grid off
ylabel('z-score')
xlabel('time to stim (ms)')
clear curDat
end

end

%%


function visualizeSGFilter(testData,frames,timeVector,var)

colors =     flip([0.5000    0.5000    0.5000;
    0.6250    0.3750    0.3750;
    0.7500    0.2500    0.2500;
    0.8750    0.1250    0.1250;
    1.0000         0         0 ;
    1.0000         0         0]);

figure('Position',[95         115         641        1121]);

for i = 1:length(frames)
curCol = colors(i,:);
curFrameLengths = frames(i);

curDat = sgolayfilt(testData,3,curFrameLengths);

%get the difference of peaks in the baseline:


subplot(length(frames),1,i)

plot(timeVector,curDat,'color',curCol,'LineWidth',3)
hold on
% 

plot(timeVector,repmat(var,1,length(curDat)),'LineWidth',2,'LineStyle','--')
plot(timeVector,-repmat(var,1,length(curDat)),'LineWidth',2,'LineStyle','--')
% get upper and lower shift for the peak markers
yl = ylim;
shift = 0.1*abs(yl(2)-yl(1));

[p , l, w, pp] = findpeaks(curDat,timeVector,'MinPeakHeight',var);

plot(l,p+shift,"Marker","v",'MarkerFaceColor','k','MarkerEdgeColor','k','LineStyle','none');

[n , lk, wn, pn] = findpeaks(-curDat,timeVector,'MinPeakHeight',var);

plot(lk,-n-shift,"Marker","^",'MarkerFaceColor','k','MarkerEdgeColor','k','LineStyle','none');

title([num2str(curFrameLengths) ' Frames'])
set(gca,'FontSize',24)
box off
grid off
ylabel('z-score')
xlabel('time to stim (ms)')
clear curDat
end

end
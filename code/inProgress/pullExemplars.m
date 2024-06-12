addpath(genpath(cd))

%%
p = load('data/pooledData.mat');

%%
load("code/dependencies/listAmyg.mat");
load("code/dependencies/listHip.mat");
load("code/dependencies/listCort.mat");

%%
files = unique(p.dataFileName);

for f = 1:length(files)
currentFile = files{f};

currentFileIDX = contains(p.dataFileName,currentFile);

d = load(currentFile);

%%
eLabels = cellfun(@(x) x{1}, p.electrodeRegionLabel(currentFileIDX), 'UniformOutput', false);
haChans = contains(eLabels,[listAmyg,listHip]);

%%

cceps = d.lowPassSPESZScore(haChans,:,:);
latency = p.n1Latency(currentFileIDX);

latency = latency(haChans);
chanNames = eLabels(haChans);

%%
length_samples = 3800;
% Sampling rate
fs = 2000; 
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

figure;
sgtitle([d.subjectName ' ' d.stimulatedRegion{1} ' ' d.stimulatedRegion{2}])
[r,c] = getSubplotDimensions(length(chanNames));
for ch = 1:length(chanNames)

    curDat = squeeze(cceps(ch,:,:));

    meanc = nanmean(curDat,2)';
    sec = (std(curDat,[],2)./size(curDat,2))';

    subplot(r,c,ch)
    plot(timeVector,meanc)
    hold on
    jbfill(timeVector, meanc+sec, meanc-sec, 'r','r', 1, 0.3);

    title([chanNames{ch} ' ' 'Latency:' num2str(latency(ch))])


end

end
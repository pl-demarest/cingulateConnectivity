clear 
addpath(genpath(cd))

fileNameDir = 'data/preprocessed/';
fileCohDir = 'data/coherence/';
fileGammaDir = 'data/gamma/';
fileFeatures = 'data/waveformFeatures/';
filePhase = 'data/phase/';

files = dir(fileNameDir);
filesidx = [files.isdir];
files = files(~filesidx);
dataFiles = {files.name};

load("code/dependencies/cingulateID.mat") % anatomical IDs of cingulate cortex channels
labelTable = readtable("code/dependencies/labelTable.txt"); % table containing all relevant info for anatomical atlas
load("code/dependencies/SEEGClinical22ChanLoc_xyz.mat") % EEG Channel Info
regionIDX = find(ismember(labelTable.Var1,cingulateID));
regionNames = {labelTable.Var2{regionIDX}}';
eeglabels = {EEGChans.labels};

cohD = [];
var = [];
pval = [];
rhoTask = [];
rhoBase = [];
subject = [];
electrodeLabel = [];
electrodeName = [];
electrodeCoord = [];
stimChannel = [];
cceps = [];
EEG = [];
EEGChans = [];
stimRegions = [];
fileName = [];
cohDistFileName = [];
cohFileName = [];
chanNumber = [];
eegChanNumber = [];
eegStimulatedRegion = [];

numN1 = [];
numN2 = [];
n1Polarity = [];
n1Amplitude = [];
n1Latency = [];
n1W = [];
n1Prom = [];
n2Polarity = [];
n2Amplitude = [];
n2Latency = [];
n2W = [];
n2Prom = [];
duration = [];
n1ratio = [];

angleChars = [];
angleCharTime = [];
angle = [];
magnitude = [];
responseStart = [];
responseEnd = [];
responseDuration = [];
responseLatency = [];
peakMagnitude = [];
peakMagLatency = [];

meanGamma = [];
stdGamma = [];
gammaRho = [];
gammaP = [];
gammaAmplitude = [];
gammaStart = [];
gammaEnd = [];
gammaDuration = [];
gammaPeak = [];
gammaPeakLatency = [];


for f = 1:length(dataFiles)

currentFile = dataFiles{f};

data = load([fileNameDir currentFile]);
load([fileCohDir 'distribution_' currentFile]);
load([fileFeatures 'features_' currentFile]);
phase = load([filePhase 'phase_' currentFile]);
gamma = load([fileGammaDir 'gamma_' currentFile]);

for i = 1:numel(data.stimulatedRegion)
    if isa(data.stimulatedRegion{i}, 'string')
        data.stimulatedRegion{i} = cellstr(data.stimulatedRegion{i});
    end
end

stimulatedRegionFlat = vertcat(data.stimulatedRegion{:});
[matchingStrings, ia, ib] = intersect(stimulatedRegionFlat, regionNames);

numChans = length(distributionStruct.cohensD);
numEEGChans = size(data.surfaceEEGZScore,1);
stimChans = zeros(1,numChans);
stimChans(data.stimulatedChannels) = 1;

cohD = [cohD, distributionStruct.cohensD];
var = [var, distributionStruct.variance];
pval = [pval, distributionStruct.pVal];
rhoTask = [rhoTask, distributionStruct.rhoTask];
rhoBase = [rhoBase, distributionStruct.rhoBase];
subject = [subject, repmat({data.subjectName},1,numChans)];
stimRegions = [stimRegions, repmat({matchingStrings(1)},1,numChans)];

fileName = [fileName, repmat({[fileNameDir currentFile]},1,numChans)];
cohDistFileName = [cohDistFileName, repmat({[fileCohDir 'distribution_' currentFile]},1,numChans)];
cohFileName = [cohFileName, repmat({[fileCohDir 'coherence_' currentFile]},1,numChans)];

electrodeLabel = [electrodeLabel, data.VERA.SecondaryLabel']; 
electrodeName = [electrodeName, data.VERA.channelNames'];
electrodeCoord = [electrodeCoord, data.VERA.tala.electrodes'];
stimChannel = [stimChannel, stimChans];
chanNumber = [chanNumber, 1:size(data.spesSmallLaplaceZScore,1)];

averageTraces = squeeze(nanmean(data.spesSmallLaplaceZScore,3));
averageEEG = squeeze(nanmean(data.surfaceEEGZScore,3));

cceps = [cceps, averageTraces'];
EEG = [EEG, averageEEG'];
EEGChans = [EEGChans, eeglabels(1:size(averageEEG,1))];
eegChanNumber = [eegChanNumber, 1:size(averageEEG,1)];
eegStimulatedRegion = [eegStimulatedRegion,repmat({matchingStrings(1)},1,numEEGChans)];

numN1 = [numN1, responseStruct.numPeaksN1];
numN2 = [numN2, responseStruct.numPeaksN2];
n1Polarity = [n1Polarity, responseStruct.n1Polarity];
n1Amplitude = [n1Amplitude, responseStruct.n1Amplitude];
n1Latency = [n1Latency, responseStruct.n1Latency];
n1W = [n1W, responseStruct.n1Width];
n1Prom = [n1Prom, responseStruct.n1Prominence];
n2Polarity = [n2Polarity, responseStruct.n2Polarity];
n2Amplitude = [n2Amplitude, responseStruct.n2Amplitude];
n2Latency = [n2Latency, responseStruct.n2Latency];
n2W = [n2W, responseStruct.n2Width];
n2Prom = [n2Prom, responseStruct.n2Prominence];
duration = [duration, responseStruct.responseDuration];
n1ratio = [n1ratio,     responseStruct.n1PeakToBaseline];

latencies = phase.magnitudeStart - 1900;

angleChars = [angleChars, phase.angleCharacterization'];
angleCharTime = [angleCharTime, phase.angleCharacterizationTime'];
angle = [angle, phase.angle'];
magnitude = [magnitude, phase.magnitude'];
responseStart = [responseStart, phase.magnitudeStart];
responseEnd = [responseEnd, phase.magnitudeStop];
responseDuration = [responseDuration, phase.magnitudeDuration];
responseLatency = [responseLatency, latencies];
peakMagnitude = [peakMagnitude, phase.peakMagnitude];
peakMagLatency = [peakMagLatency, phase.peakMagnitudeLatency];


meanGamma = [meanGamma, gamma.meanGamma'];
stdGamma = [stdGamma, gamma.stdGamma'];
gammaRho = [gammaRho, gamma.rho];
gammaP = [gammaP, gamma.p];
gammaAmplitude = [gammaAmplitude, gamma.amplitude];
gammaStart = [gammaStart, gamma.responseStart];
gammaEnd = [gammaEnd, gamma.responseStop];
gammaDuration = [gammaDuration, gamma.responseDuration];
gammaPeak = [gammaPeak, gamma.peakGamma];
gammaPeakLatency = [gammaPeakLatency, gamma.peakGammaLatency];


end

pooledData.cohensD = cohD;
pooledData.variance = var;
pooledData.pValue = pval;
pooledData.rhoCCEP = rhoTask;
pooledData.rhoBase = rhoBase;
pooledData.subjectID = subject;
pooledData.channelNumber = chanNumber;
pooledData.electrodeRegionLabel = electrodeLabel;
pooledData.electrodeName = electrodeName;
pooledData.electrodeCoordinates = electrodeCoord;
pooledData.stimulatedChannels = stimChannel;
pooledData.CCEPs = cceps;
pooledData.EEG = EEG;
pooledData.EEGChans = EEGChans;
pooledData.EEGChannelNumber =eegChanNumber;
pooledData.EEGStimulatedRegion = eegStimulatedRegion;
pooledData.stimulatedRegion = stimRegions;
pooledData.dataFileName = fileName;
pooledData.coherenceFileName = cohFileName;
pooledData.coherenceDistFileName = cohDistFileName;
pooledData.n1PeakNumber = numN1;
pooledData.n2PeakNumber = numN2;
pooledData.n1Polarity = n1Polarity;
pooledData.n1Amplitude = n1Amplitude;
pooledData.n1Latency = n1Latency;
pooledData.n1Width = n1W;
pooledData.n1Prominence = n1Prom;
pooledData.n2Polarity = n2Polarity;
pooledData.n2Amplitude = n2Amplitude;
pooledData.n2Latency = n2Latency;
pooledData.n2Width = n2W;
pooledData.n2Prominence = n2Prom;
pooledData.responseDurationByPeak = duration;
pooledData.RMS = rms(cceps(1920:3320,:));
pooledData.n1PeakToBaselineRatio = n1ratio;
pooledData.angleCharacteristics = angleChars;
pooledData.angleCharacteristicsTime = angleCharTime;
pooledData.responseAngles = angle;
pooledData.responseMagnitude = magnitude;
pooledData.responseStartTime = responseStart;
pooledData.responseEndTime = responseEnd;
pooledData.responseDurationByAbruptChanges = responseDuration;
pooledData.responseLatency = responseLatency;
pooledData.responsePeakMagnitude = peakMagnitude;
pooledData.responsePeakMagnitudeTime = peakMagLatency;
pooledData.gamma = meanGamma;
pooledData.stdGamma = stdGamma;
pooledData.gammaRho = gammaRho;
pooledData.gammaP = gammaP;
pooledData.gammaAmplitude = gammaAmplitude;
pooledData.gammaStart = gammaStart;
pooledData.gammaEnd = gammaEnd;
pooledData.gammaDuration = gammaDuration;
pooledData.gammaPeak = gammaPeak;
pooledData.gammaPeakLatency = gammaPeakLatency;


save('data/pooledData.mat','-struct','pooledData')

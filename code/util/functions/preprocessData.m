function [data, hilbertOutSPES, hilbertOutEEG] = preprocessData(filepath, baseline, EEGChannels, channelInspection, channelID, VERA, subject, stimAmplitude, stimChannels)

%First add info fields to data struct
data.subjectName = subject;
data.stimulatedRegion = channelID;

channelNums = [find(ismember(VERA.channelNames, stimChannels{1})), find(ismember(VERA.channelNames, stimChannels{2}))]; %get stimulating channel numbers
data.stimulatedChannels = channelNums;

data.stimulationAmplitude = stimAmplitude;

%load in the data file
[sig, states, params] = load_bcidat(filepath);
sig = double(sig);

%add sampling rate
data.samplingRate = params.SamplingRate.NumericValue;

%get stimulation indexes and make sure the threshold is appropriate
stimulation = states.DC04;
spesIndex = findStimulusOnset(stimulation, 4e4);%this threshold may need to be adjusted
data.numTrials = length(spesIndex);

%identify EEG channels
baselineEEG = baseline(:,channelInspection.eegElectrodes);
spesEEG = sig(:,channelInspection.eegElectrodes);

%remove unwanted channels
baseline(:,channelInspection.removeFromData) = [];
sig(:,channelInspection.removeFromData) = [];

% remove artifact and clean data
spesVec = zeros(length(sig),1); %create a binary vector of stimulation events
spesVec(spesIndex) = 1;

%remove artifacts
baseClean = getCleanData(baseline,data.samplingRate,[],0);
clear baseline
baseEegClean = getCleanData(baselineEEG,data.samplingRate,[],0);
clear baselineEEG

sigClean = getCleanData(sig,data.samplingRate,spesIndex,15);
clear sig
spesEegClean = getCleanData(spesEEG,data.samplingRate,spesIndex,15);
clear spesEEG

%re-reference Data
slSig= smallLaplace(sigClean,VERA.tala.electrodes,5,[]);
slBase = smallLaplace(baseClean,VERA.tala.electrodes,5,[]);

carSig = commonAverageData(sigClean);
carBase = commonAverageData(baseClean);

carSigEeg = commonAverageData(getLowPassData(spesEegClean,30,5,data.samplingRate));
carBaseEegClean = commonAverageData(getLowPassData(baseEegClean,30,5,data.samplingRate));

%lowpass data for visualization purposes- CCEPs are low freq component
lpSig = getLowPassData(slSig,25,5,data.samplingRate);
lpBase = getLowPassData(slBase,25,5,data.samplingRate);

%bandpass data for downstream analysis, epoch the data after bandpassing,
%to be saved in a separate file
hilbertOutSPES = getAllBandpassedData(slSig,data.samplingRate,spesVec,{},.95,.95);
hilbertOutEEG = getAllBandpassedData(carSigEeg,data.samplingRate,spesVec,{},.95,.95);

% epoch data
data.spesCAR = epochData(carSig,spesVec,{},.95,.95,data.samplingRate);
clear carSig
data.spesSmallLaplace = epochData(slSig,spesVec,{},.95,.95,data.samplingRate);
clear slSig
data.surfaceEEG = epochData(carSigEeg,spesVec,{}, .95, .95, data.samplingRate);
clear carSigEeg
data.lowPassSPES = epochData(lpSig,spesVec,{}, .95, .95, data.samplingRate);
clear lpSig

%zscore Data
baselineWindow = 1:.9*data.samplingRate;
data.spesCARZScore = getZScore(data.spesCAR,baselineWindow);
data.spesSmallLaplaceZScore = getZScore(data.spesSmallLaplace,baselineWindow);
data.surfaceEEGZScore = getZScore(data.surfaceEEG,baselineWindow);
data.lowPassSPESZScore = getZScore(data.lowPassSPES,baselineWindow);
data.spesBroadbandGamma = getZScore(abs(hilbertOutSPES.broadbandGamma),baselineWindow);

data.lowPassBaseline = lpBase;

data.VERA = VERA;

data.baseline.surfaceEEG = carBaseEegClean;
data.baseline.smallLaplace = slBase;
data.baseline.CAR = carBase;

end
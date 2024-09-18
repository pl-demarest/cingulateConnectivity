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
baselineWindow = 1:.9*data.samplingRate;

%get stimulation indexes and make sure the threshold is appropriate
stimulation = states.DC04;
spesIndex = findStimulusOnset(stimulation, 4e4);%this threshold may need to be adjusted
data.numTrials = length(spesIndex);

if isempty(spesIndex)
data.message = 'trigbox error';
return
end

% remove artifact and clean data
spesVec = zeros(length(sig),1); %create a binary vector of stimulation events
spesVec(spesIndex) = 1;

%check if first SPES occured too quickly
if spesIndex(1) < 2000
    spesIndex(1) = [];
end


%check if EEG channels exist, identify EEG channels, then create data
%struct for EEG accordingly, if no EEG channels exist, create nan values
%for output
if ~isempty(channelInspection.eegElectrodes)
baselineEEG = baseline(:,channelInspection.eegElectrodes);
spesEEG = sig(:,channelInspection.eegElectrodes);
baseEegClean = getCleanData(baselineEEG,data.samplingRate,[],0);
clear baselineEEG
spesEegClean = getCleanData(spesEEG,data.samplingRate,spesIndex,15);
clear spesEEG
carSigEeg = commonAverageData(getLowPassData(spesEegClean,30,5,data.samplingRate));
carBaseEegClean = commonAverageData(getLowPassData(baseEegClean,30,5,data.samplingRate));
hilbertOutEEG = getAllBandpassedData(carSigEeg,data.samplingRate,spesVec,{},.95,.95);
data.surfaceEEG = epochData(carSigEeg,spesVec,{}, .95, .95, data.samplingRate);
clear carSigEeg
data.surfaceEEGZScore = getZScore(data.surfaceEEG,baselineWindow);
data.baseline.surfaceEEG = carBaseEegClean;
else
    data.baseline.surfaceEEG = nan; 
    data.surfaceEEGZScore = nan;
    data.surfaceEEG = nan;
    hilbertOutEEG = struct;
end


%remove unwanted channels
baseline(:,channelInspection.removeFromData) = [];
sig(:,channelInspection.removeFromData) = [];


%remove artifacts
baseClean = getCleanData(baseline,data.samplingRate,[],0);
clear baseline



sigClean = getCleanData(sig,data.samplingRate,spesIndex,15);
clear sig

%re-reference Data
slSig= smallLaplace(sigClean,VERA.tala.electrodes,5,[]);
slBase = smallLaplace(baseClean,VERA.tala.electrodes,5,[]);

carSig = commonAverageData(sigClean);
carBase = commonAverageData(baseClean);

%lowpass data for visualization purposes- CCEPs are low freq component
lpSig = getLowPassData(slSig,40,5,data.samplingRate);
lpBase = getLowPassData(slBase,40,5,data.samplingRate);
%bandpass data for downstream analysis, epoch the data after bandpassing,
%to be saved in a separate file
hilbertOutSPES = getAllBandpassedData(slSig,data.samplingRate,spesVec,{},.95,.95);

% epoch data
data.spesCAR = epochData(carSig,spesVec,{},.95,.95,data.samplingRate);
clear carSig
data.spesSmallLaplace = epochData(slSig,spesVec,{},.95,.95,data.samplingRate);
clear slSig
data.lowPassSPES = epochData(lpSig,spesVec,{}, .95, .95, data.samplingRate);
clear lpSig
%zscore Data

data.spesCARZScore = getZScore(data.spesCAR,baselineWindow);
data.spesSmallLaplaceZScore = getZScore(data.spesSmallLaplace,baselineWindow);
data.lowPassSPESZScore = getZScore(data.lowPassSPES,baselineWindow);
data.spesBroadbandGamma = getZScore(abs(hilbertOutSPES.broadbandGamma),baselineWindow);
data.lowPassBaseline = lpBase;
data.VERA = VERA;
data.baseline.smallLaplace = slBase;
data.baseline.CAR = carBase;

end
function [data, hilbertOutSPES, hilbertOutEEG] = preprocessData(filepath, baseline, EEGChannels, channelInspection, channelID, VERA, subject, stimAmplitude, stimChannels, timeBefore, timeAfter)

% First add info fields to data struct
data.subjectName       = subject;
data.stimulatedRegion  = channelID;

channelNums = [find(ismember(VERA.channelNames, stimChannels{1})), ...
               find(ismember(VERA.channelNames, stimChannels{2}))];
data.stimulatedChannels   = channelNums;
data.stimulationAmplitude = stimAmplitude;

% Load data file
[sig, states, params] = load_bcidat(filepath);
sig = double(sig);

% Sampling rate and baseline window.
% Baseline uses the first 94.7% of the pre-stimulus window (preserving the
% original 0.9 s baseline at timeBefore=0.95 s; scales with timeBefore).
data.samplingRate = params.SamplingRate.NumericValue;
baselineWindow    = 1 : floor((0.9 / 0.95) * timeBefore * data.samplingRate);

% Find stimulus onsets
stimulation    = states.DC04;
spesIndex      = findStimulusOnset(stimulation, 4e4);
data.numTrials = length(spesIndex);

if isempty(spesIndex)
    data.message = 'trigbox error';
    return
end

% Create binary stimulus event vector
spesVec = zeros(length(sig), 1);
spesVec(spesIndex) = 1;

% Drop first stimulus if it occurred before the epoch start boundary
if spesIndex(1) < timeBefore * data.samplingRate
    spesIndex(1) = [];
end

% --- EEG channels ---
if ~isempty(channelInspection.eegElectrodes)
    baselineEEG     = baseline(:, channelInspection.eegElectrodes);
    spesEEG         = sig(:, channelInspection.eegElectrodes);
    baseEegClean    = getCleanData(baselineEEG, data.samplingRate, [], 0);
    clear baselineEEG
    spesEegClean    = getCleanData(spesEEG, data.samplingRate, spesIndex, 15);
    clear spesEEG
    carSigEeg       = commonAverageData(getLowPassData(spesEegClean, 30, 5, data.samplingRate));
    carBaseEegClean = commonAverageData(getLowPassData(baseEegClean, 30, 5, data.samplingRate));
    hilbertOutEEG   = getAllBandpassedData(carSigEeg, data.samplingRate, spesVec, {}, timeBefore, timeAfter);
    data.surfaceEEG = epochData(carSigEeg, spesVec, {}, timeBefore, timeAfter, data.samplingRate);
    clear carSigEeg
    data.surfaceEEGZScore    = getZScore(data.surfaceEEG, baselineWindow);
    data.baseline.surfaceEEG = carBaseEegClean;
else
    data.baseline.surfaceEEG = nan;
    data.surfaceEEGZScore    = nan;
    data.surfaceEEG          = nan;
    hilbertOutEEG            = struct;
end

% --- sEEG channels ---
baseline(:, channelInspection.removeFromData) = [];
sig(:,      channelInspection.removeFromData) = [];

baseClean = getCleanData(baseline, data.samplingRate, [], 0);
clear baseline

sigClean = getCleanData(sig, data.samplingRate, spesIndex, 15);
clear sig

% Re-reference
slSig  = smallLaplace(sigClean, VERA.tala.electrodes, 5, []);
slBase = smallLaplace(baseClean, VERA.tala.electrodes, 5, []);
carSig  = commonAverageData(sigClean);
carBase = commonAverageData(baseClean);

% Lowpass for visualization
lpSig  = getLowPassData(slSig,  40, 5, data.samplingRate);
lpBase = getLowPassData(slBase, 40, 5, data.samplingRate);

% Broadband Hilbert for downstream analysis
hilbertOutSPES = getAllBandpassedData(slSig, data.samplingRate, spesVec, {}, timeBefore, timeAfter);

% Epoch and z-score
data.spesCAR          = epochData(carSig, spesVec, {}, timeBefore, timeAfter, data.samplingRate);
clear carSig
data.spesSmallLaplace = epochData(slSig,  spesVec, {}, timeBefore, timeAfter, data.samplingRate);
clear slSig
data.lowPassSPES      = epochData(lpSig,  spesVec, {}, timeBefore, timeAfter, data.samplingRate);
clear lpSig

data.spesCARZScore          = getZScore(data.spesCAR,          baselineWindow);
data.spesSmallLaplaceZScore = getZScore(data.spesSmallLaplace, baselineWindow);
data.lowPassSPESZScore      = getZScore(data.lowPassSPES,      baselineWindow);
data.spesBroadbandGamma     = getZScore(abs(hilbertOutSPES.broadbandGamma), baselineWindow);
data.lowPassBaseline        = lpBase;
data.VERA                   = VERA;
data.baseline.smallLaplace  = slBase;
data.baseline.CAR           = carBase;

end

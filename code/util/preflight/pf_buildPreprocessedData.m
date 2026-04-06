function [data, hilbertOut] = pf_buildPreprocessedData(rawSignal, samplingRate, eventOnsets, subjectName, stimulatedRegion, options)
% PF_BUILDPREPROCESSEDDATA  Build a pipeline-compatible preprocessed data struct
%   from arbitrary time series data.
%
%   [data, hilbertOut] = pf_buildPreprocessedData(rawSignal, samplingRate, ...
%                           eventOnsets, subjectName, stimulatedRegion)
%   [data, hilbertOut] = pf_buildPreprocessedData(..., options)
%
%   This function is the Path B entry point for users who have sEEG data that
%   was NOT acquired with BCI2000. It produces the same .mat struct that
%   preprocessData.m would generate, allowing downstream feature extraction
%   scripts to run without modification.
%
%   =========================================================================
%   REQUIRED INPUTS
%   =========================================================================
%   rawSignal       [nChannels x nTimepoints] double
%                   Continuous sEEG time series. Channels should be already
%                   cleaned (bad channels removed). If your data is
%                   [nTimepoints x nChannels], it will be transposed automatically.
%                   Units: microvolts preferred (consistent with BCI2000 pipeline).
%
%   samplingRate    scalar (Hz)
%                   Sampling frequency of rawSignal.
%                   WARNING: The pipeline is calibrated for 2000 Hz. If your
%                   data is at a different rate, hardcoded indices in poolData.m
%                   (stim onset at sample 1900, baseline window 1:1800, etc.)
%                   will be incorrect. Resample to 2000 Hz before calling
%                   this function if possible.
%
%   eventOnsets     [1 x nTrials] integer
%                   Sample indices in rawSignal where each stimulation event
%                   begins. This plays the same role as the DC04 trigger
%                   channel in the BCI2000 pipeline.
%                   To extract from an analog trigger: use findStimulusOnset.m
%                   Example: eventOnsets = find(diff(triggerChannel > threshold) == 1)
%
%   subjectName     string  (e.g., 'SubjectX')
%
%   stimulatedRegion  {1x2} cell of strings
%                   Anatomical labels for the two stimulated electrodes.
%                   Should match the Destrieux atlas convention used elsewhere:
%                   e.g., {'ctx_lh_G_and_S_cingul-Ant', 'ctx_rh_G_and_S_cingul-Mid-Ant'}
%                   Use 'unknown' if not applicable.
%
%   =========================================================================
%   OPTIONS STRUCT (optional, pass as 6th argument)
%   =========================================================================
%   options.channelNames        {1 x nChannels} cell of strings
%                               Channel label for each row of rawSignal.
%                               Defaults to {'ch1', 'ch2', ...}
%
%   options.VERA                struct  — VERA brain structure (see DATA_GUIDE.md)
%                               If provided and has tala.electrodes, small Laplace
%                               re-referencing is applied. If empty/absent, CAR is
%                               used as a fallback for all re-referenced fields.
%
%   options.stimulatedChannels  [1x2] integer
%                               Row indices in rawSignal of the stimulated channels.
%                               Defaults to [1, 2].
%
%   options.stimulationAmplitude  scalar (mA)  — default: NaN
%
%   options.eegSignal           [nEEGchans x nTimepoints] — surface EEG data.
%                               If provided, produces surfaceEEG fields.
%                               If empty (default), surfaceEEG fields are NaN.
%
%   options.useZerosPlaceholder  logical — default: false
%                               If true, all 3-D data fields are filled with
%                               zeros(nCh, 3800, nTrials) instead of real data.
%                               Use this to generate a valid template struct
%                               when you do not yet have real data.
%
%   options.timeBefore          scalar (s) — epoch window before event; default: 0.95
%   options.timeAfter           scalar (s) — epoch window after event;  default: 0.95
%
%   =========================================================================
%   OUTPUTS
%   =========================================================================
%   data          struct — preprocessed data, same schema as preprocessData.m output
%   hilbertOut    struct — band-specific Hilbert envelopes, same schema as
%                          hilbertOutSPES from preprocessData.m
%
%   =========================================================================
%   SAVING
%   =========================================================================
%   Save data and hilbertOut to match the naming convention expected by
%   downstream scripts:
%
%     outName = sprintf('%s_%s_%s', subjectName, bci2000FileName, stimRegion);
%     save(fullfile('data/preprocessed/', [outName '.mat']), '-struct', 'data');
%     save(fullfile('data/hilbert/', ['hilbertSEEG_' outName '.mat']), '-struct', 'hilbertOut');
%
%   =========================================================================
%   EXAMPLE
%   =========================================================================
%   % Minimal example with zeros placeholder (generate template struct)
%   opts.useZerosPlaceholder = true;
%   [data, hilb] = pf_buildPreprocessedData([], 2000, [], ...
%       'MySubject', {'ctx_lh_G_and_S_cingul-Ant','ctx_rh_G_cingul-Post-dorsal'}, opts);
%   save('data/preprocessed/MySubject_file001_ctx_lh_G_and_S_cingul-Ant.mat', '-struct', 'data');

% =========================================================================
% Parse options
% =========================================================================
if nargin < 6 || isempty(options)
    options = struct();
end

timeBefore = getopt(options, 'timeBefore', 0.95);
timeAfter  = getopt(options, 'timeAfter',  0.95);
useZeros   = getopt(options, 'useZerosPlaceholder', false);
veraIn     = getopt(options, 'VERA', struct());
stimChans  = getopt(options, 'stimulatedChannels', [1 2]);
stimAmp    = getopt(options, 'stimulationAmplitude', NaN);
eegSignal  = getopt(options, 'eegSignal', []);

% =========================================================================
% Handle placeholder mode
% =========================================================================
nSamp  = round((timeBefore + timeAfter) * samplingRate);
if samplingRate == 2000 && nSamp ~= 3800
    nSamp = 3800;  % enforce canonical size
end

if useZeros || isempty(rawSignal) || isempty(eventOnsets)
    fprintf('[pf_buildPreprocessedData] Using zeros placeholder.\n');
    if isempty(rawSignal)
        nCh = 1;
    else
        rawSignal = orientSignal(rawSignal);
        nCh = size(rawSignal, 1);
    end
    if isempty(eventOnsets)
        nTrials = 1;
    else
        nTrials = length(eventOnsets);
    end
    data       = buildPlaceholderStruct(nCh, nSamp, nTrials, subjectName, stimulatedRegion, stimChans, stimAmp, samplingRate, veraIn, options);
    hilbertOut = buildPlaceholderHilbert(nCh, nSamp, nTrials);
    return
end

% =========================================================================
% Validate / orient rawSignal
% =========================================================================
rawSignal = orientSignal(rawSignal);
[nCh, nTime] = size(rawSignal);
nTrials = length(eventOnsets);

fprintf('[pf_buildPreprocessedData] Signal: %d channels x %d samples, %d events\n', ...
    nCh, nTime, nTrials);

if samplingRate ~= 2000
    warning(['pf_buildPreprocessedData: samplingRate = %g Hz, but pipeline is calibrated ' ...
             'for 2000 Hz. Hardcoded indices in poolData.m will be misaligned.'], samplingRate);
end

% Channel names
if isfield(options, 'channelNames') && ~isempty(options.channelNames)
    channelNames = options.channelNames;
else
    channelNames = arrayfun(@(i) sprintf('ch%d', i), 1:nCh, 'UniformOutput', false);
end

% =========================================================================
% Build stimulus vector (analogous to DC04 in BCI2000 pipeline)
% =========================================================================
spesVec = zeros(nTime, 1);
validOnsets = eventOnsets(eventOnsets > round(timeBefore * samplingRate) & ...
                          eventOnsets < nTime - round(timeAfter * samplingRate));
spesVec(validOnsets) = 1;
nTrials = length(validOnsets);

baselineWindow = 1 : round(0.9 * samplingRate);

% =========================================================================
% Build VERA struct if not provided
% =========================================================================
if isempty(fieldnames(veraIn)) || ~isfield(veraIn, 'tala')
    fprintf('[pf_buildPreprocessedData] No VERA provided — using CAR for all re-referencing.\n');
    VERA = buildMinimalVERA(nCh, channelNames);
    useLaplace = false;
else
    VERA = veraIn;
    VERA.channelNames = channelNames;
    useLaplace = isfield(VERA.tala, 'electrodes') && size(VERA.tala.electrodes, 1) == nCh;
    if ~useLaplace
        warning(['pf_buildPreprocessedData: VERA.tala.electrodes has %d rows but signal has %d channels. ' ...
                 'Falling back to CAR.'], size(VERA.tala.electrodes, 1), nCh);
    end
end

% =========================================================================
% Artifact removal and re-referencing
% =========================================================================
fprintf('[pf_buildPreprocessedData] Cleaning signal...\n');
sigClean = getCleanData(rawSignal', samplingRate, validOnsets, 15);  % input: [time x chan]

fprintf('[pf_buildPreprocessedData] Re-referencing...\n');
if useLaplace
    slSig = smallLaplace(sigClean, VERA.tala.electrodes, 5, []);
else
    slSig = commonAverageData(sigClean);
    fprintf('  (CAR used — VERA with MNI coordinates required for small Laplace)\n');
end
carSig = commonAverageData(sigClean);

% Low-pass for CCEP visualization (matches lpSig in preprocessData.m)
lpSig = getLowPassData(slSig, 40, 5, samplingRate);

% =========================================================================
% Baseline signal
% =========================================================================
% Use a pre-event baseline derived from the signal itself (before first event)
baselineEnd = min(validOnsets) - 1;
if baselineEnd > 2 * samplingRate
    baseRaw = rawSignal(:, 1:baselineEnd)';
    baseClean = getCleanData(baseRaw, samplingRate, [], 0);
    if useLaplace
        slBase = smallLaplace(baseClean, VERA.tala.electrodes, 5, []);
    else
        slBase = commonAverageData(baseClean);
    end
    carBase = commonAverageData(baseClean);
    lpBase  = getLowPassData(slBase, 40, 5, samplingRate);
else
    fprintf('[pf_buildPreprocessedData] Insufficient pre-event data for baseline. Using zeros.\n');
    slBase  = zeros(nTime, nCh);
    carBase = zeros(nTime, nCh);
    lpBase  = zeros(nTime, nCh);
end

% =========================================================================
% Epoch data
% =========================================================================
fprintf('[pf_buildPreprocessedData] Epoching...\n');
spesCAR           = epochData(carSig, spesVec, {}, timeBefore, timeAfter, samplingRate);
spesSmallLaplace  = epochData(slSig,  spesVec, {}, timeBefore, timeAfter, samplingRate);
lowPassSPES       = epochData(lpSig,  spesVec, {}, timeBefore, timeAfter, samplingRate);

% Z-score using baseline window
spesCAR_z        = getZScore(spesCAR,          baselineWindow);
spesSmallLap_z   = getZScore(spesSmallLaplace,  baselineWindow);
lowPassSPES_z    = getZScore(lowPassSPES,        baselineWindow);

% =========================================================================
% Broadband gamma
% =========================================================================
fprintf('[pf_buildPreprocessedData] Computing broadband gamma...\n');
bbGammaFilt = bandPassData(slSig', 70, 170, 4, samplingRate);  % [chan x time]
bbGammaH    = getHilbert(bbGammaFilt);
bbGammaEpoch = epochData(bbGammaH, spesVec, {}, timeBefore, timeAfter, samplingRate);
bbGamma_z    = getZScore(abs(bbGammaEpoch), baselineWindow);

% =========================================================================
% Hilbert output (all bands) — matches hilbertOutSPES from preprocessData.m
% =========================================================================
fprintf('[pf_buildPreprocessedData] Computing all-band Hilbert...\n');
hilbertOut = getAllBandpassedData(slSig', samplingRate, spesVec, {}, timeBefore, timeAfter);

% =========================================================================
% Surface EEG (if provided)
% =========================================================================
if ~isempty(eegSignal)
    eegSignal = orientSignal(eegSignal);
    eegClean  = getCleanData(eegSignal', samplingRate, validOnsets, 15);
    carEeg    = commonAverageData(getLowPassData(eegClean, 30, 5, samplingRate));
    surfEEG   = epochData(carEeg, spesVec, {}, timeBefore, timeAfter, samplingRate);
    surfEEG_z = getZScore(surfEEG, baselineWindow);
    surfEEGBaseline = carEeg;
else
    surfEEG         = nan;
    surfEEG_z       = nan;
    surfEEGBaseline = nan;
end

% =========================================================================
% Assemble output struct (matches preprocessData.m output schema)
% =========================================================================
data.subjectName            = subjectName;
data.stimulatedRegion       = stimulatedRegion;
data.stimulatedChannels     = stimChans;
data.stimulationAmplitude   = stimAmp;
data.samplingRate           = samplingRate;
data.numTrials              = nTrials;

data.spesCAR                = spesCAR;
data.spesSmallLaplace       = spesSmallLaplace;
data.lowPassSPES            = lowPassSPES;
data.spesCARZScore          = spesCAR_z;
data.spesSmallLaplaceZScore = spesSmallLap_z;
data.lowPassSPESZScore      = lowPassSPES_z;
data.spesBroadbandGamma     = bbGamma_z;

data.surfaceEEG             = surfEEG;
data.surfaceEEGZScore       = surfEEG_z;
data.baseline.surfaceEEG    = surfEEGBaseline;
data.lowPassBaseline        = lpBase;
data.baseline.smallLaplace  = slBase;
data.baseline.CAR           = carBase;

data.VERA                   = VERA;

fprintf('[pf_buildPreprocessedData] Done. Struct contains %d channels, %d samples, %d trials.\n', ...
    size(data.spesSmallLaplace, 1), size(data.spesSmallLaplace, 2), size(data.spesSmallLaplace, 3));

end

% =========================================================================
% LOCAL HELPERS
% =========================================================================

function sig = orientSignal(sig)
% Ensure signal is [nChannels x nTimepoints] (more channels than timepoints is unusual)
if isempty(sig), return; end
if size(sig, 1) > size(sig, 2)
    sig = sig';
end
end

function val = getopt(s, field, default)
if isfield(s, field) && ~isempty(s.(field))
    val = s.(field);
else
    val = default;
end
end

function VERA = buildMinimalVERA(nCh, channelNames)
% Construct a minimal VERA placeholder when no VERA is provided.
% Coordinates are zeros — smallLaplace will not work, but the struct
% satisfies field checks in downstream scripts.
VERA.electrodeLabels    = channelNames(:);
VERA.electrodeNames     = channelNames(:);
VERA.channelNames       = channelNames;
VERA.SecondaryLabel     = repmat({'unknown'}, nCh, 1);
VERA.tala.electrodes    = zeros(nCh, 3);
VERA.tala.activations   = zeros(nCh, 1);
VERA.electrodeDefinition.Annotation         = repmat({'unknown'}, nCh, 1);
VERA.electrodeDefinition.Label              = channelNames(:);
VERA.electrodeDefinition.DefinitionIdentifier = (1:nCh)';
end

function data = buildPlaceholderStruct(nCh, nSamp, nTrials, subjectName, stimulatedRegion, stimChans, stimAmp, samplingRate, veraIn, options)
% Fill all 3-D fields with zeros — useful for generating a template struct.
z3 = zeros(nCh, nSamp, nTrials);
cnames = getopt(options, 'channelNames', arrayfun(@(i) sprintf('ch%d',i), 1:nCh, 'UniformOutput', false));
if isempty(fieldnames(veraIn))
    VERA = buildMinimalVERA(nCh, cnames);
else
    VERA = veraIn;
    if ~isfield(VERA, 'channelNames')
        VERA.channelNames = cnames;
    end
end

data.subjectName            = subjectName;
data.stimulatedRegion       = stimulatedRegion;
data.stimulatedChannels     = stimChans;
data.stimulationAmplitude   = stimAmp;
data.samplingRate           = samplingRate;
data.numTrials              = nTrials;
data.spesCAR                = z3;
data.spesSmallLaplace       = z3;
data.lowPassSPES            = z3;
data.spesCARZScore          = z3;
data.spesSmallLaplaceZScore = z3;
data.lowPassSPESZScore      = z3;
data.spesBroadbandGamma     = z3;
data.surfaceEEG             = nan;
data.surfaceEEGZScore       = nan;
data.baseline.surfaceEEG    = nan;
data.lowPassBaseline        = zeros(nCh, nSamp);
data.baseline.smallLaplace  = zeros(nCh, nSamp);
data.baseline.CAR           = zeros(nCh, nSamp);
data.VERA                   = VERA;
end

function h = buildPlaceholderHilbert(nCh, nSamp, nTrials)
z3 = zeros(nCh, nSamp, nTrials);
h.delta         = z3;
h.theta         = z3;
h.alpha         = z3;
h.beta          = z3;
h.lowGamma      = z3;
h.broadbandGamma = z3;
h.broadbandLF   = z3;
end

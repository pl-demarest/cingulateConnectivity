function results = pf_validatePreprocessed(dataDir)
% PF_VALIDATEPREPROCESSED  Validate existing preprocessed .mat files for Path B.
%
%   results = pf_validatePreprocessed(dataDir)
%
%   Scans dataDir for .mat files and validates that the first file found
%   contains all struct fields required by the downstream pipeline.
%   Additional files are checked for field presence only (no deep inspection).
%
%   Required fields (must be present in each .mat file):
%   -------------------------------------------------------------------------
%   subjectName             string — subject identifier
%   stimulatedRegion        cell{1x2} — anatomical labels of stimulated channels
%   stimulatedChannels      [1 x 2] — channel indices within VERA
%   samplingRate            scalar — samples/sec (should be 2000)
%   numTrials               scalar — number of SPES trials
%
%   spesSmallLaplace        [nCh x nSamp x nTrials] — small Laplace re-ref epochs
%   spesSmallLaplaceZScore  [nCh x nSamp x nTrials] — z-scored version
%   lowPassSPES             [nCh x nSamp x nTrials] — low-pass (<40Hz) epochs
%   lowPassSPESZScore       [nCh x nSamp x nTrials] — z-scored version
%   spesBroadbandGamma      [nCh x nSamp x nTrials] — broadband gamma z-score
%   surfaceEEGZScore        [nEEGCh x nSamp x nTrials] or scalar NaN
%
%   VERA                    struct with fields:
%     .SecondaryLabel       cell of atlas label strings
%     .channelNames         cell of channel name strings
%     .tala.electrodes      [nCh x 3] MNI coordinates
%
%   baseline.smallLaplace   [nCh x nSamp] — continuous baseline (small Laplace)
%   baseline.CAR            [nCh x nSamp] — continuous baseline (CAR)
%   -------------------------------------------------------------------------
%
%   Note on expected dimensions:
%     nSamp = 3800 (±0.95s at 2000 Hz, stimulus at sample 1900)
%     This is required by poolData.m which indexes hardcoded sample ranges.

results = struct('subject', {}, 'check', {}, 'status', {}, 'message', {});

requiredTopFields = {
    'subjectName', 'stimulatedRegion', 'stimulatedChannels', ...
    'samplingRate', 'numTrials', ...
    'spesSmallLaplace', 'spesSmallLaplaceZScore', ...
    'lowPassSPES', 'lowPassSPESZScore', ...
    'spesBroadbandGamma', 'surfaceEEGZScore', ...
    'VERA', 'baseline'
};
requiredVERAFields   = {'SecondaryLabel', 'channelNames', 'tala'};
requiredBaseFields   = {'smallLaplace', 'CAR'};

% -------------------------------------------------------------------------
% Check 1: Directory contains .mat files
% -------------------------------------------------------------------------
matFiles = dir(fullfile(dataDir, '*.mat'));
checkName = 'Preprocessed .mat files found';
if isempty(matFiles)
    results(end+1) = mkEntry('', checkName, 'FAIL', ...
        sprintf('No .mat files in: %s', dataDir));
    return
end
results(end+1) = mkEntry('', checkName, 'PASS', ...
    sprintf('%d file(s) found in %s', length(matFiles), dataDir));

% -------------------------------------------------------------------------
% Deep check: first file
% -------------------------------------------------------------------------
firstFile = fullfile(dataDir, matFiles(1).name);
fprintf('  Deep-checking first file: %s\n', matFiles(1).name);

checkName = 'First file loads';
try
    D = load(firstFile);
catch ME
    results(end+1) = mkEntry('', checkName, 'FAIL', ME.message);
    return
end
results(end+1) = mkEntry('', checkName, 'PASS', '');

% Determine subject name for labeling
if isfield(D, 'subjectName')
    subj = char(D.subjectName);
else
    subj = matFiles(1).name;
end

% Required top-level fields
checkName = 'Required top-level fields';
missing = setdiff(requiredTopFields, fieldnames(D));
if isempty(missing)
    results(end+1) = mkEntry(subj, checkName, 'PASS', '');
else
    results(end+1) = mkEntry(subj, checkName, 'FAIL', ...
        sprintf('Missing: %s', strjoin(missing, ', ')));
end

% samplingRate check
checkName = 'samplingRate == 2000';
if isfield(D, 'samplingRate')
    if D.samplingRate ~= 2000
        results(end+1) = mkEntry(subj, checkName, 'WARN', ...
            sprintf('samplingRate = %g. Pipeline is calibrated for 2000 Hz. ' ...
                    'Hardcoded index references in poolData.m (lines 143,146) will be wrong.', ...
                    D.samplingRate));
    else
        results(end+1) = mkEntry(subj, checkName, 'PASS', '2000 Hz');
    end
end

% Epoch length check (nSamp should be 3800)
checkName = 'Epoch length == 3800 samples';
if isfield(D, 'spesSmallLaplace') && ~isscalar(D.spesSmallLaplace)
    nSamp = size(D.spesSmallLaplace, 2);
    if nSamp ~= 3800
        results(end+1) = mkEntry(subj, checkName, 'WARN', ...
            sprintf('nSamp = %d (expected 3800). poolData.m uses hardcoded sample indices ' ...
                    'assuming ±0.95s at 2000Hz (stim at sample 1900).', nSamp));
    else
        results(end+1) = mkEntry(subj, checkName, 'PASS', '3800 samples (±0.95s at 2000Hz)');
    end
end

% VERA sub-fields
checkName = 'VERA required sub-fields';
if isfield(D, 'VERA')
    missingV = setdiff(requiredVERAFields, fieldnames(D.VERA));
    if isempty(missingV)
        results(end+1) = mkEntry(subj, checkName, 'PASS', ...
            sprintf('%d channels in VERA', length(D.VERA.channelNames)));
    else
        results(end+1) = mkEntry(subj, checkName, 'FAIL', ...
            sprintf('Missing VERA sub-fields: %s', strjoin(missingV, ', ')));
    end
end

% baseline sub-fields
checkName = 'baseline required sub-fields';
if isfield(D, 'baseline')
    missingB = setdiff(requiredBaseFields, fieldnames(D.baseline));
    if isempty(missingB)
        results(end+1) = mkEntry(subj, checkName, 'PASS', '');
    else
        results(end+1) = mkEntry(subj, checkName, 'FAIL', ...
            sprintf('Missing baseline sub-fields: %s', strjoin(missingB, ', ')));
    end
end

% -------------------------------------------------------------------------
% Shallow field check: remaining files
% -------------------------------------------------------------------------
if length(matFiles) > 1
    fprintf('  Shallow field check on remaining %d files...\n', length(matFiles)-1);
    nBad = 0;
    for f = 2:length(matFiles)
        fpath = fullfile(dataDir, matFiles(f).name);
        try
            info = whos('-file', fpath);
            presentNames = {info.name};
            fm = setdiff(requiredTopFields, presentNames);
            if ~isempty(fm)
                nBad = nBad + 1;
            end
        catch
            nBad = nBad + 1;
        end
    end
    checkName = sprintf('Remaining %d files field check', length(matFiles)-1);
    if nBad == 0
        results(end+1) = mkEntry('', checkName, 'PASS', 'All files contain required fields');
    else
        results(end+1) = mkEntry('', checkName, 'WARN', ...
            sprintf('%d file(s) may be missing fields. Run pf_validatePreprocessed on each.', nBad));
    end
end

end

% =========================================================================
function e = mkEntry(subject, check, status, message)
if nargin < 4, message = ''; end
e = struct('subject', subject, 'check', check, 'status', status, 'message', message);
end

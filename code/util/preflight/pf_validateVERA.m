function results = pf_validateVERA(subjectDir, subjectID, deepMode)
% PF_VALIDATEVERA  Validate the VERA brain structure file for a subject.
%
%   results = pf_validateVERA(subjectDir, subjectID)
%   results = pf_validateVERA(subjectDir, subjectID, deepMode)
%
%   Inputs:
%     subjectDir  — full path to the subject's raw data folder (trailing / OK)
%     subjectID   — subject identifier string (e.g., 'BJH062')
%     deepMode    — logical; if true, loads the .mat and inspects struct fields
%                   (default: false — shallow check only)
%
%   VERA requirement summary:
%     The VERA file must be named exactly: {subjectID}_APARC2009_MNIbrain.mat
%     It must use the FreeSurfer Destrieux atlas (APARC2009).
%     Required top-level fields: electrodeLabels, electrodeNames,
%       SecondaryLabel, electrodeDefinition, tala
%     tala must have: electrodes (Nx3 MNI coordinates)
%     SecondaryLabel: cell array where each element is itself a cell array;
%       the last element of each inner cell is the atlas label string.
%       Format: '{ctx|wm}_{lh|rh}_{DestrieuxRegionName}'
%       Example: 'ctx_lh_G_and_S_cingul-Ant'

if nargin < 3
    deepMode = false;
end

results = struct('subject', {}, 'check', {}, 'status', {}, 'message', {});

% Ensure trailing separator
if ~endsWith(subjectDir, filesep)
    subjectDir = [subjectDir filesep];
end

% -------------------------------------------------------------------------
% Check 1: VERA file exists with correct naming convention
% -------------------------------------------------------------------------
veraFilename = [subjectID '_APARC2009_MNIbrain.mat'];
veraPath = [subjectDir veraFilename];

checkName = 'VERA file exists';
if ~isfile(veraPath)
    % Check if a VERA file exists with wrong name (helps diagnose naming errors)
    wrongFiles = dir([subjectDir '*_MNIbrain.mat']);
    if ~isempty(wrongFiles)
        msg = sprintf('Not found at expected path. Found: %s. File must be named %s.', ...
            wrongFiles(1).name, veraFilename);
    else
        msg = sprintf('Not found. Expected: %s. Must use Destrieux atlas (APARC2009).', veraFilename);
    end
    results(end+1) = mkEntry(subjectID, checkName, 'FAIL', msg);
    return  % Cannot proceed without file
end

results(end+1) = mkEntry(subjectID, checkName, 'PASS', veraFilename);

% -------------------------------------------------------------------------
% Shallow mode: stop here
% -------------------------------------------------------------------------
if ~deepMode
    results(end+1) = mkEntry(subjectID, 'VERA struct fields (skipped)', 'PASS', ...
        'Run with deepMode=true to inspect struct internals');
    return
end

% -------------------------------------------------------------------------
% Deep mode: load and inspect
% -------------------------------------------------------------------------
fprintf('    Loading VERA for %s (deep mode)...\n', subjectID);
try
    V = load(veraPath);
catch ME
    results(end+1) = mkEntry(subjectID, 'VERA file loads', 'FAIL', ME.message);
    return
end
results(end+1) = mkEntry(subjectID, 'VERA file loads', 'PASS', '');

% Get the top-level variable name (should be a struct)
vnames = fieldnames(V);
if isempty(vnames)
    results(end+1) = mkEntry(subjectID, 'VERA struct content', 'FAIL', 'File loaded but is empty');
    return
end
VERA = V.(vnames{1});

% Required top-level fields
requiredFields = {'electrodeLabels', 'electrodeNames', 'SecondaryLabel', ...
                  'electrodeDefinition', 'tala'};
missingFields = {};
for f = 1:length(requiredFields)
    if ~isfield(VERA, requiredFields{f})
        missingFields{end+1} = requiredFields{f}; %#ok<AGROW>
    end
end

checkName = 'VERA required fields';
if isempty(missingFields)
    results(end+1) = mkEntry(subjectID, checkName, 'PASS', ...
        sprintf('%d electrode labels found', length(VERA.electrodeLabels)));
else
    results(end+1) = mkEntry(subjectID, checkName, 'FAIL', ...
        sprintf('Missing: %s', strjoin(missingFields, ', ')));
    return
end

% tala.electrodes field
checkName = 'VERA.tala.electrodes';
if isfield(VERA, 'tala') && isfield(VERA.tala, 'electrodes')
    sz = size(VERA.tala.electrodes);
    if sz(2) == 3
        results(end+1) = mkEntry(subjectID, checkName, 'PASS', ...
            sprintf('%d electrodes x 3 MNI coords', sz(1)));
    else
        results(end+1) = mkEntry(subjectID, checkName, 'WARN', ...
            sprintf('Shape %dx%d — expected Nx3 MNI coordinates', sz(1), sz(2)));
    end
else
    results(end+1) = mkEntry(subjectID, checkName, 'FAIL', ...
        'tala.electrodes field missing — required for smallLaplace re-referencing');
end

% SecondaryLabel format: nested cell, last element is atlas string
checkName = 'VERA.SecondaryLabel format';
try
    sl = VERA.SecondaryLabel;
    if ~iscell(sl) || isempty(sl)
        results(end+1) = mkEntry(subjectID, checkName, 'FAIL', ...
            'SecondaryLabel is not a cell array or is empty');
    else
        % Check first non-empty element
        sampleLabel = '';
        for si = 1:min(length(sl), 20)
            if iscell(sl{si}) && ~isempty(sl{si})
                sampleLabel = sl{si}{end};
                break
            end
        end
        if isempty(sampleLabel)
            results(end+1) = mkEntry(subjectID, checkName, 'WARN', ...
                ['Could not find a non-empty inner cell. ' ...
                 'Each SecondaryLabel{i} must be a cell array whose last element is the atlas string.']);
        elseif ~isempty(regexp(sampleLabel, '^(ctx|wm)_(lh|rh)_', 'once'))
            results(end+1) = mkEntry(subjectID, checkName, 'PASS', ...
                sprintf('Sample label: %s', sampleLabel));
        else
            results(end+1) = mkEntry(subjectID, checkName, 'WARN', ...
                sprintf(['Sample label "%s" does not match expected pattern ' ...
                 '"ctx_lh_..." or "wm_rh_...". Ensure APARC2009 (Destrieux) atlas was used.'], ...
                 sampleLabel));
        end
    end
catch ME
    results(end+1) = mkEntry(subjectID, checkName, 'WARN', ...
        sprintf('Could not inspect SecondaryLabel: %s', ME.message));
end

end

% =========================================================================
function e = mkEntry(subject, check, status, message)
if nargin < 4, message = ''; end
e = struct('subject', subject, 'check', check, 'status', status, 'message', message);
end

% =========================================================================
function tf = endsWith(str, suffix)
% Compatibility wrapper (endsWith builtin added R2020b)
tf = length(str) >= length(suffix) && strcmp(str(end-length(suffix)+1:end), suffix);
end

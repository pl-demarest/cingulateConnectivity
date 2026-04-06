function results = pf_validateChannelInspection(subjectDir, subjectID)
% PF_VALIDATECHANNELINSPECTION  Validate the channelInspection.mat file.
%
%   results = pf_validateChannelInspection(subjectDir, subjectID)
%
%   channelInspection.mat is the critical manual pre-processing artifact that
%   bridges the BCI2000 .dat channel list and the VERA electrode structure.
%   It is created once per subject using channelInspectionScript.m.
%
%   If missing, this check returns WARN (not FAIL) because the file is
%   created manually — preflight cannot auto-generate it. Instructions are
%   printed to guide the user through creating it.
%
%   Required fields and their meaning:
%   -------------------------------------------------------------------------
%   eegElectrodes       — column indices of EEG (surface) channels in the
%                         BCI2000 .dat signal matrix. These are passed to
%                         preprocessData.m to extract surface EEG separately.
%                         Use [] if no surface EEG channels were recorded.
%
%   removeFromData      — column indices to DELETE from the BCI2000 signal
%                         matrix before channel alignment with VERA.
%                         Typically includes reference channels, ECG, bad
%                         channels, and the EEG electrode columns.
%
%   removeFromVera      — row indices to DELETE from VERA.electrodeLabels
%                         before alignment with the BCI2000 channel list.
%                         Includes electrodes not recorded (in OR out, just
%                         not in the .dat), and any channels to exclude.
%
%   switchChannelsFrom  — electrode indices in VERA (post-removal) whose
%                         names do not match the BCI2000 channel names and
%                         need to be relabeled. Use [] if none.
%
%   switchChannelsTo    — the target indices to swap to. Must be same length
%                         as switchChannelsFrom. Use [] if none.
%   -------------------------------------------------------------------------
%
%   After applying removeFromData to BCI2000 and removeFromVera to VERA,
%   the remaining channel counts MUST be equal. This is validated by
%   processChannels.m which will error if they don't match.
%
%   To create this file: run code/channelInspectionScript.m

results = struct('subject', {}, 'check', {}, 'status', {}, 'message', {});

if ~endsWith(subjectDir, filesep)
    subjectDir = [subjectDir filesep];
end

ciPath = [subjectDir 'channelInspection.mat'];
requiredFields = {'eegElectrodes', 'removeFromVera', 'removeFromData', ...
                  'switchChannelsFrom', 'switchChannelsTo'};

% -------------------------------------------------------------------------
% Check 1: File exists (WARN not FAIL — requires manual creation)
% -------------------------------------------------------------------------
checkName = 'channelInspection.mat exists';
if ~isfile(ciPath)
    results(end+1) = mkEntry(subjectID, checkName, 'WARN', ...
        ['Not found. Run code/channelInspectionScript.m for this subject to create it. ' ...
         'Without it, dataPreprocess.m will crash.']);
    fprintf('\n');
    fprintf('  [GUIDANCE] channelInspection.mat is missing for subject %s.\n', subjectID);
    fprintf('  This file maps BCI2000 .dat channels to VERA electrode indices.\n');
    fprintf('  To create it:\n');
    fprintf('    1. Open code/channelInspectionScript.m\n');
    fprintf('    2. Set subjectID and verify the raw data paths\n');
    fprintf('    3. Run the script — it will display both channel lists side by side\n');
    fprintf('    4. Fill in the five fields as instructed, then save\n');
    fprintf('\n');
    return
end
results(end+1) = mkEntry(subjectID, checkName, 'PASS', '');

% -------------------------------------------------------------------------
% Check 2: File loads
% -------------------------------------------------------------------------
checkName = 'channelInspection.mat loads';
try
    CI = load(ciPath);
catch ME
    results(end+1) = mkEntry(subjectID, checkName, 'FAIL', ME.message);
    return
end
results(end+1) = mkEntry(subjectID, checkName, 'PASS', '');

% Get struct (may be nested under a variable name)
if isfield(CI, 'channelInspection')
    ci = CI.channelInspection;
elseif length(fieldnames(CI)) == 1
    fn = fieldnames(CI);
    ci = CI.(fn{1});
    if isstruct(ci) && isfield(ci, 'eegElectrodes')
        % ok
    else
        ci = CI; % flat struct
    end
else
    ci = CI;
end

% -------------------------------------------------------------------------
% Check 3: All required fields present
% -------------------------------------------------------------------------
checkName = 'channelInspection required fields';
missingFields = {};
for f = 1:length(requiredFields)
    if ~isfield(ci, requiredFields{f})
        missingFields{end+1} = requiredFields{f}; %#ok<AGROW>
    end
end

if isempty(missingFields)
    results(end+1) = mkEntry(subjectID, checkName, 'PASS', ...
        sprintf('removeFromData: %d idx | removeFromVera: %d idx | eegElectrodes: %d idx', ...
        length(ci.removeFromData), length(ci.removeFromVera), length(ci.eegElectrodes)));
else
    results(end+1) = mkEntry(subjectID, checkName, 'FAIL', ...
        sprintf('Missing fields: %s. Re-run channelInspectionScript.m.', ...
        strjoin(missingFields, ', ')));
end

end

% =========================================================================
function e = mkEntry(subject, check, status, message)
if nargin < 4, message = ''; end
e = struct('subject', subject, 'check', check, 'status', status, 'message', message);
end

% =========================================================================
function tf = endsWith(str, suffix)
tf = length(str) >= length(suffix) && strcmp(str(end-length(suffix)+1:end), suffix);
end

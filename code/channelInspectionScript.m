% CHANNELINSPECTIONSCRIPT.M
%
% PURPOSE:
%   This script creates the channelInspection.mat file for a single subject.
%   channelInspection.mat is a required pre-processing artifact that tells
%   the pipeline how to align the channel list from the BCI2000 .dat files
%   with the electrode structure from VERA.
%
%   THE CORE PROBLEM:
%   BCI2000 records from ALL electrodes in the headstage (a flat list of
%   column indices). VERA contains ALL implanted electrodes with anatomical
%   locations — including some that may not have been recorded, or that were
%   recorded but need to be excluded (bad channels, references, EEG, etc.).
%
%   After applying channelInspection, both lists must have the same length
%   and must refer to the same set of electrodes in the same order.
%   processChannels.m will throw an error if the counts do not match.
%
% INSTRUCTIONS:
%   1. Set subjectID and rawDirectory below to match your subject
%   2. Run Section 1 to load the BCI2000 and VERA data
%   3. Run Section 2 to display both channel lists side by side
%   4. Fill in the five channelInspection fields in Section 3
%   5. Run Section 4 to verify alignment and save
%
% RUN REQUIREMENTS:
%   - Must be run from the repo root (same folder as preflight.m)
%   - addpath(genpath(cd)) must be called first (done automatically below)
%   - The BCI2000 .dat file and VERA .mat file must exist
%
% OUTPUT:
%   Saves channelInspection.mat to:  {rawDirectory}/{subjectID}/channelInspection.mat

clear
addpath(genpath(cd))

% =========================================================================
%% SECTION 0: Configure subject-specific paths
% =========================================================================
% Set these two variables for your subject. You can either hardcode them
% here or load from config.mat if preflight.m has been run.

% Option A: Load from config.mat (recommended after running preflight)
% load('config.mat');
% subjectID    = 'BJH062';       % <-- change to your subject ID
% rawDirectory = config.rawDirectory;

% Option B: Set paths manually
subjectID    = '';                % e.g., 'BJH062'
rawDirectory = '';                % e.g., '/Volumes/Samsung_T5/cingulateConnectivity/data/raw'

% --- Validate setup ---
if isempty(subjectID) || isempty(rawDirectory)
    error(['channelInspectionScript: Please set subjectID and rawDirectory in Section 0 before running.\n' ...
           'See comments above for instructions.']);
end

subjectDir  = fullfile(rawDirectory, subjectID, filesep);
spesFolder  = 'ElectricalStimulation_1HzStim/ECOG001/';  % standard BCI2000 subfolder

% =========================================================================
%% SECTION 1: Load BCI2000 and VERA data
% =========================================================================
% We load:
%   - One BCI2000 .dat file (any file works — we only need the channel names
%     from params.ChannelNames.Value, not the actual signal data)
%   - The VERA .mat file (provides VERA.electrodeLabels, the implanted
%     electrode list with anatomical locations)

fprintf('\nLoading BCI2000 data for subject %s...\n', subjectID);

% Find the first available .dat file in the SPES folder
spesDirPath = fullfile(subjectDir, spesFolder);
datFiles = dir(fullfile(spesDirPath, '*.dat'));

if isempty(datFiles)
    error(['No .dat files found in: %s\n' ...
           'Check spesFolder and subjectDir settings.'], spesDirPath);
end

firstDat = fullfile(spesDirPath, datFiles(1).name);
fprintf('  Using .dat file: %s\n', datFiles(1).name);

[~, ~, params] = load_bcidat(firstDat);
bciChannelNames = params.ChannelNames.Value;  % all channel names in the .dat

% Load VERA
veraFile = fullfile(subjectDir, [subjectID '_APARC2009_MNIbrain.mat']);
if ~isfile(veraFile)
    error(['VERA file not found: %s\n' ...
           'File must be named exactly: %s_APARC2009_MNIbrain.mat'], veraFile, subjectID);
end

fprintf('  Loading VERA: %s\n', [subjectID '_APARC2009_MNIbrain.mat']);
veraData = load(veraFile);
% VERA may be the struct itself or nested under a variable name
fn = fieldnames(veraData);
if length(fn) == 1
    VERA = veraData.(fn{1});
else
    VERA = veraData;
end

% Normalize electrodeLabels to a cell array of char vectors. VERA in the wild
% stores this field either as a cell array (older VERA outputs) or as a
% string array (newer outputs). All downstream %s formatting in this script
% assumes the cell form, so we coerce once here.
if isfield(VERA, 'electrodeLabels') && isstring(VERA.electrodeLabels)
    VERA.electrodeLabels = cellstr(VERA.electrodeLabels);
end

fprintf('  BCI2000: %d channels\n', length(bciChannelNames));
fprintf('  VERA:    %d electrodes\n', length(VERA.electrodeLabels));

% =========================================================================
%% SECTION 2: Display both channel lists for comparison
% =========================================================================
% Study this output carefully. Your goal is to identify:
%   A) Which BCI2000 columns are EEG (surface) electrodes
%   B) Which BCI2000 columns should be removed (references, ECG, bad, EEG)
%   C) Which VERA rows should be removed (not recorded or excluded electrodes)
%   D) Whether any VERA electrode names do not match BCI2000 names (switch needed)

fprintf('\n');
fprintf('=================================================================\n');
fprintf('  Channel Alignment Comparison\n');
fprintf('=================================================================\n');
fprintf('\n');
fprintf('  BCI2000 channels (%d total):\n', length(bciChannelNames));
fprintf('  Index  |  Name\n');
fprintf('  -------|------------------\n');
for i = 1:length(bciChannelNames)
    fprintf('  %5d  |  %s\n', i, bciChannelNames{i});
end

fprintf('\n');
fprintf('  VERA electrodes (%d total):\n', length(VERA.electrodeLabels));
fprintf('  Index  |  Label\n');
fprintf('  -------|------------------\n');
for i = 1:length(VERA.electrodeLabels)
    fprintf('  %5d  |  %s\n', i, VERA.electrodeLabels{i});
end
fprintf('\n');

% Show atlas labels for first few VERA electrodes (to verify Destrieux format)
fprintf('  Sample VERA anatomical labels (SecondaryLabel, last element):\n');
nShow = min(5, length(VERA.SecondaryLabel));
for i = 1:nShow
    if iscell(VERA.SecondaryLabel{i}) && ~isempty(VERA.SecondaryLabel{i})
        atlasLabel = VERA.SecondaryLabel{i}{end};
    else
        atlasLabel = char(VERA.SecondaryLabel{i});
    end
    fprintf('    VERA(%d): %s  ->  %s\n', i, VERA.electrodeLabels{i}, atlasLabel);
end
fprintf('\n');

% =========================================================================
%% SECTION 3: Fill in the channelInspection fields
% =========================================================================
% Read the field descriptions carefully. The values here are EXAMPLES from
% one subject — you MUST replace them with the correct values for your subject.
%
% HOW TO DETERMINE EACH FIELD:
%
% eegElectrodes:
%   Find the BCI2000 column indices (from the list above) that correspond to
%   SURFACE EEG electrodes (not sEEG). These are physically different from
%   sEEG — they sit on the scalp surface and are used for the surfaceEEG
%   analysis in the pipeline. If you did not record surface EEG, use [].
%   Example: channels 232-254 are EEG → channelInspection.eegElectrodes = [232:254];
%
% removeFromData:
%   BCI2000 column indices to DELETE from the signal matrix before alignment.
%   Include: reference electrodes, ECG/EMG channels, other non-sEEG channels,
%   bad channels, AND all EEG electrode columns (they are extracted separately above).
%   These channels will simply not appear in the pipeline's sEEG analysis.
%   Example: channels 5,6 are references; 232-256 are EEG + extras
%   → channelInspection.removeFromData = [5, 6, 232:256];
%
% removeFromVera:
%   VERA row indices to DELETE from VERA.electrodeLabels before alignment.
%   Include: any implanted electrode that was NOT recorded (e.g., strips that
%   were implanted but not wired to the recording system) or that you want
%   to exclude from analysis.
%   After removing these, length(VERA.electrodeLabels) must equal
%   length(bciChannelNames after removeFromData).
%   Example: rows 26,27 are extra contacts; rows 86,104 are bad; etc.
%   → channelInspection.removeFromVera = [26,27,67,68,86,...];
%
% switchChannelsFrom / switchChannelsTo:
%   After applying the removals above, if some BCI2000 channel names still do
%   not match their corresponding VERA electrode label (same position, different
%   name), use these to relabel them. switchVERAChannels.m swaps the VERA
%   entries at positions switchChannelsFrom with those at switchChannelsTo.
%   Use [] if all channels align after the removals.
%   Example: switchChannelsFrom = [12]; switchChannelsTo = [15];
%   → This swaps VERA rows 12 and 15 so they match BCI2000 column order.
%
% VERIFICATION (run Section 4 to check):
%   length(bciChannelNames) - length(removeFromData) ==
%   length(VERA.electrodeLabels) - length(removeFromVera)
%   If this is not true, the pipeline will error.

channelInspection.eegElectrodes    = [];  % <-- FILL IN: BCI2000 indices of surface EEG channels

channelInspection.removeFromData   = [];  % <-- FILL IN: BCI2000 indices to remove from .dat

channelInspection.removeFromVera   = [];  % <-- FILL IN: VERA row indices to remove

channelInspection.switchChannelsFrom = [];  % <-- FILL IN or leave []
channelInspection.switchChannelsTo   = [];  % <-- FILL IN or leave []

% =========================================================================
%% SECTION 4: Verify alignment and save
% =========================================================================
% Run this section after filling in Section 3 to confirm the channel counts
% match before saving.

nBCI  = length(bciChannelNames) - length(channelInspection.removeFromData);
nVERA = length(VERA.electrodeLabels) - length(channelInspection.removeFromVera);

fprintf('  Alignment check:\n');
fprintf('    BCI2000 channels after removal:  %d\n', nBCI);
fprintf('    VERA electrodes after removal:   %d\n', nVERA);

if nBCI == nVERA
    fprintf('  [PASS] Counts match. Channel alignment is valid.\n');
elseif nBCI == 0 || nVERA == 0
    fprintf('  [WARN] One or both counts are zero. Did you fill in Section 3?\n');
else
    fprintf('  [FAIL] Counts do NOT match (%d vs %d).\n', nBCI, nVERA);
    fprintf('         Adjust removeFromData or removeFromVera until they are equal.\n');
    fprintf('         Do not save until this check passes.\n');
    return
end

% Optionally display aligned names to visually verify correspondence
fprintf('\n');
fprintf('  Aligned channel comparison (BCI2000 vs VERA):\n');
fprintf('  BCI2000 remaining      |  VERA remaining\n');
fprintf('  -----------------------|---------------------------\n');
bciKeep  = setdiff(1:length(bciChannelNames),   channelInspection.removeFromData);
veraKeep = setdiff(1:length(VERA.electrodeLabels), channelInspection.removeFromVera);
nShow2   = min(20, min(length(bciKeep), length(veraKeep)));
for i = 1:nShow2
    fprintf('  %-22s |  %s\n', bciChannelNames{bciKeep(i)}, VERA.electrodeLabels{veraKeep(i)});
end
if nShow2 < length(bciKeep)
    fprintf('  ... (%d more rows)\n', length(bciKeep) - nShow2);
end

% Save
savePath = fullfile(subjectDir, 'channelInspection.mat');
save(savePath, 'channelInspection');
fprintf('\n');
fprintf('  [SAVED] channelInspection.mat -> %s\n', savePath);
fprintf('\n');
fprintf('  Next step: run preflight.m to validate the full subject setup,\n');
fprintf('  or proceed to dataPreprocess.m if all subjects are ready.\n\n');

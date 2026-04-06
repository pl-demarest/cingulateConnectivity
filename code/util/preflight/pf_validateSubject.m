function results = pf_validateSubject(subjectDir, subjectID, spesFolder, deepMode)
% PF_VALIDATESUBJECT  Run all per-subject validation checks.
%
%   results = pf_validateSubject(subjectDir, subjectID)
%   results = pf_validateSubject(subjectDir, subjectID, spesFolder)
%   results = pf_validateSubject(subjectDir, subjectID, spesFolder, deepMode)
%
%   Inputs:
%     subjectDir  — full path to this subject's raw data directory
%     subjectID   — subject identifier string (e.g., 'BJH062')
%     spesFolder  — subfolder containing BCI2000 .dat files
%                   (default: 'ElectricalStimulation_1HzStim/ECOG001/')
%     deepMode    — logical; if true, loads VERA to inspect struct internals
%                   (default: false)
%
%   Validation sequence:
%     1. VERA file and struct (pf_validateVERA)
%     2. stimulationTable.xlsx (pf_validateStimTable)
%     3. BCI2000 .dat directory and files
%     4. Baseline recording file
%     5. channelInspection.mat (pf_validateChannelInspection)

if nargin < 3 || isempty(spesFolder)
    spesFolder = 'ElectricalStimulation_1HzStim/ECOG001/';
end
if nargin < 4
    deepMode = false;
end

results = struct('subject', {}, 'check', {}, 'status', {}, 'message', {});

if ~endsWith(subjectDir, filesep)
    subjectDir = [subjectDir filesep];
end

fprintf('  Validating subject: %s\n', subjectID);

% -------------------------------------------------------------------------
% 1. VERA file
% -------------------------------------------------------------------------
results = [results, pf_validateVERA(subjectDir, subjectID, deepMode)];

% -------------------------------------------------------------------------
% 2. stimulationTable.xlsx
% -------------------------------------------------------------------------
results = [results, pf_validateStimTable(subjectDir, subjectID)];

% -------------------------------------------------------------------------
% 3. BCI2000 SPES .dat directory and files
% -------------------------------------------------------------------------
spesDirPath = [subjectDir spesFolder];
checkName = 'SPES .dat directory exists';
if ~isfolder(spesDirPath)
    results(end+1) = mkEntry(subjectID, checkName, 'FAIL', ...
        sprintf(['Not found: %s\n' ...
                 '         Expected subfolder structure: {subjectDir}/%s\n' ...
                 '         This is hardcoded in dataPreprocess.m (spesFolder variable).'], ...
                 spesDirPath, spesFolder));
else
    datFiles = dir([spesDirPath '*.dat']);
    if isempty(datFiles)
        results(end+1) = mkEntry(subjectID, checkName, 'WARN', ...
            sprintf('Directory exists but contains no .dat files: %s', spesDirPath));
    else
        results(end+1) = mkEntry(subjectID, checkName, 'PASS', ...
            sprintf('%d .dat file(s) found', length(datFiles)));
    end
end

% -------------------------------------------------------------------------
% 4. Baseline recording file
%    importBaseline.m looks for 'baseline*.dat' or 'Baseline*.dat' in subjectDir
% -------------------------------------------------------------------------
checkName = 'Baseline .dat file exists';
baseFiles = [dir([subjectDir 'baseline*.dat']); dir([subjectDir 'Baseline*.dat'])];
if isempty(baseFiles)
    results(end+1) = mkEntry(subjectID, checkName, 'WARN', ...
        ['No baseline*.dat found in subject directory. ' ...
         'importBaseline.m requires at least one baseline recording. ' ...
         'Check for alternative naming (e.g., REST, Resting).']);
else
    results(end+1) = mkEntry(subjectID, checkName, 'PASS', ...
        sprintf('%d baseline file(s): %s', length(baseFiles), baseFiles(1).name));
end

% -------------------------------------------------------------------------
% 5. channelInspection.mat
% -------------------------------------------------------------------------
results = [results, pf_validateChannelInspection(subjectDir, subjectID)];

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

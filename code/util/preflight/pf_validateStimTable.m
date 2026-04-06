function results = pf_validateStimTable(subjectDir, subjectID)
% PF_VALIDATESTIMTABLE  Validate the stimulationTable.xlsx for a subject.
%
%   results = pf_validateStimTable(subjectDir, subjectID)
%
%   The stimulationTable.xlsx defines which BCI2000 .dat files to process
%   and the stimulation parameters for each file. It is read by
%   dataPreprocess.m and filtered by processChannels.m.
%
%   Required columns:
%     file              — BCI2000 .dat filename (without extension)
%     ch1               — first stimulation channel name (matches BCI2000 channel)
%     ch2               — second stimulation channel name
%     currentAmplitude  — stimulation current in mA (pipeline filters for 6 mA)
%     frequency         — stimulation frequency in Hz (pipeline filters for 0.5 Hz)
%
%   Columns added automatically by processChannels (do NOT pre-populate):
%     ch1ID, ch2ID, ch1Number, ch2Number

results = struct('subject', {}, 'check', {}, 'status', {}, 'message', {});

if ~endsWith(subjectDir, filesep)
    subjectDir = [subjectDir filesep];
end

tablePath = [subjectDir 'stimulationTable.xlsx'];
requiredCols = {'file', 'ch1', 'ch2', 'currentAmplitude', 'frequency'};

% -------------------------------------------------------------------------
% Check 1: File exists
% -------------------------------------------------------------------------
checkName = 'stimulationTable.xlsx exists';
if ~isfile(tablePath)
    results(end+1) = mkEntry(subjectID, checkName, 'FAIL', ...
        ['Not found. Create a spreadsheet with columns: ' strjoin(requiredCols, ', ')]);
    return
end
results(end+1) = mkEntry(subjectID, checkName, 'PASS', '');

% -------------------------------------------------------------------------
% Check 2: File is readable
% -------------------------------------------------------------------------
checkName = 'stimulationTable.xlsx readable';
try
    T = readtable(tablePath);
catch ME
    results(end+1) = mkEntry(subjectID, checkName, 'FAIL', ME.message);
    return
end
results(end+1) = mkEntry(subjectID, checkName, 'PASS', sprintf('%d rows', height(T)));

% -------------------------------------------------------------------------
% Check 3: Required columns present
% -------------------------------------------------------------------------
checkName = 'Required columns present';
actualCols = lower(T.Properties.VariableNames);
missingCols = {};
for c = 1:length(requiredCols)
    if ~any(strcmp(lower(requiredCols{c}), actualCols))
        missingCols{end+1} = requiredCols{c}; %#ok<AGROW>
    end
end

if isempty(missingCols)
    results(end+1) = mkEntry(subjectID, checkName, 'PASS', ...
        sprintf('All 5 required columns found (%d total)', width(T)));
else
    results(end+1) = mkEntry(subjectID, checkName, 'FAIL', ...
        sprintf('Missing columns: %s', strjoin(missingCols, ', ')));
end

% -------------------------------------------------------------------------
% Check 4: Warn if table appears to have no rows matching the 6mA/0.5Hz filter
% -------------------------------------------------------------------------
if isempty(missingCols) && height(T) > 0
    checkName = 'Rows passing 6mA / 0.5Hz filter';
    try
        passing = T.currentAmplitude == 6 & T.frequency == 0.5;
        nPass = sum(passing);
        if nPass == 0
            results(end+1) = mkEntry(subjectID, checkName, 'WARN', ...
                ['No rows with currentAmplitude=6 and frequency=0.5. ' ...
                 'processChannels.m filters for these values; adjust if your protocol differs.']);
        else
            results(end+1) = mkEntry(subjectID, checkName, 'PASS', ...
                sprintf('%d / %d rows pass (6mA, 0.5Hz)', nPass, height(T)));
        end
    catch
        % Column type mismatch — skip this check
    end
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

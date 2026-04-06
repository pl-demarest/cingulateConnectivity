function buildStimConfig(dataDirectory)
% buildStimConfig  Discover all stimulation conditions across subject data
%                  and write stim_filter.txt to the repo root.
%
% Usage:
%   buildStimConfig()              % uses default raw data path 'data/raw'
%   buildStimConfig(dataDirectory) % specify alternate path
%
% stim_filter.txt controls which stimulation conditions and epoch window
% parameters are used by dataPreprocess.m. Edit the file to include or
% exclude specific amplitudes, frequencies, and stimulated brain regions,
% then re-run dataPreprocess.m.
%
% Region counts reflect the number of stimulation table rows (across all
% subjects) where that region appears as either stimulation electrode
% (ch1ID or ch2ID). Amplitude and frequency counts reflect total row
% occurrences. All conditions are included by default -- comment out lines
% to exclude them.
%
% Note: region labels (ch1ID/ch2ID) are populated by processChannels during
% the first preprocessing run. Subjects whose tables lack these columns will
% be skipped with a warning. Re-run buildStimConfig() after preprocessing
% those subjects to include their conditions.

if nargin < 1
    dataDirectory = 'data/raw';
end

outputFile = 'stim_filter.txt';

% --- Discover subject directories ---
entries = dir(dataDirectory);
entries = entries([entries.isdir]);
entries = entries(~ismember({entries.name}, {'.', '..'}));
subjects = {entries.name};

if isempty(subjects)
    error('buildStimConfig: no subject folders found in ''%s''.', dataDirectory);
end

% --- Accumulate conditions across all subjects ---
allAmps    = [];
allFreqs   = [];
allRegions = {};
skipped    = {};

for s = 1:length(subjects)
    subjectDir    = fullfile(dataDirectory, subjects{s});
    stimTablePath = fullfile(subjectDir, 'stimulationTable.xlsx');

    if ~isfile(stimTablePath)
        skipped{end+1} = [subjects{s} ' (no stimulationTable.xlsx)']; %#ok<AGROW>
        continue
    end

    tbl = readtable(stimTablePath, 'VariableNamingRule', 'preserve');

    % Check whether ch1ID/ch2ID are populated (requires prior processChannels run)
    hasIDs = ismember('ch1ID', tbl.Properties.VariableNames) && ...
             ismember('ch2ID', tbl.Properties.VariableNames);
    if hasIDs
        hasIDs = hasIDs && ~all(cellfun(@(x) isempty(strtrim(char(x))), tbl.ch1ID));
    end

    if ~hasIDs
        skipped{end+1} = [subjects{s} ' (ch1ID/ch2ID not populated -- run dataPreprocess.m first)']; %#ok<AGROW>
        continue
    end

    % Accumulate amplitudes and frequencies from all rows
    allAmps  = [allAmps;  tbl.currentAmplitude]; %#ok<AGROW>
    allFreqs = [allFreqs; tbl.frequency];         %#ok<AGROW>

    % Accumulate region labels from rows where IDs are populated
    for r = 1:height(tbl)
        id1 = strtrim(char(tbl.ch1ID{r}));
        id2 = strtrim(char(tbl.ch2ID{r}));
        if ~isempty(id1), allRegions{end+1} = id1; end %#ok<AGROW>
        if ~isempty(id2), allRegions{end+1} = id2; end %#ok<AGROW>
    end
end

if isempty(allAmps)
    error(['buildStimConfig: no processed stimulation tables found.\n' ...
           'Run dataPreprocess.m on at least one subject first, ' ...
           'then re-run buildStimConfig().']);
end

% --- Compute unique values and occurrence counts ---
uniqueAmps    = unique(allAmps);
uniqueFreqs   = unique(allFreqs);
uniqueRegions = unique(allRegions(:));

ampCounts    = arrayfun(@(a) sum(allAmps == a),           uniqueAmps);
freqCounts   = arrayfun(@(f) sum(allFreqs == f),          uniqueFreqs);
regionCounts = cellfun(@(r) sum(strcmp(allRegions, r)),   uniqueRegions);

% Sort regions by count descending so primary stimulation targets appear first
[regionCounts, sortIdx] = sort(regionCounts, 'descend');
uniqueRegions = uniqueRegions(sortIdx);

% Column width for aligned inline counts
maxRegionLen  = max(cellfun(@length, uniqueRegions));
regionColWidth = maxRegionLen + 4;

% --- Write stim_filter.txt ---
fid = fopen(outputFile, 'w');
if fid == -1
    error('buildStimConfig: could not open ''%s'' for writing.', outputFile);
end

fprintf(fid, '%% cingulateConnectivity -- Preprocessing Filter Config\n');
fprintf(fid, '%% Generated %s by buildStimConfig()\n', datestr(now, 'yyyy-mm-dd'));
fprintf(fid, '%%\n');
fprintf(fid, '%% Lines starting with %% are comments and are ignored by the parser.\n');
fprintf(fid, '%% To EXCLUDE a condition: add %% at the start of its line.\n');
fprintf(fid, '%% To INCLUDE a condition: ensure its line is not commented out.\n');
fprintf(fid, '%% Re-run buildStimConfig() to regenerate from current subject data.\n');
fprintf(fid, '%%\n');
fprintf(fid, '%% Counts (n=) reflect occurrences across all subject stimulation tables.\n');
fprintf(fid, '%% Region counts include appearances as either stimulation electrode (ch1ID or ch2ID).\n');
fprintf(fid, '\n');

% [amplitudes_mA]
fprintf(fid, '[amplitudes_mA]\n');
for i = 1:length(uniqueAmps)
    fprintf(fid, '%-8g%% n=%d\n', uniqueAmps(i), ampCounts(i));
end
fprintf(fid, '\n');

% [frequencies_Hz]
fprintf(fid, '[frequencies_Hz]\n');
for i = 1:length(uniqueFreqs)
    fprintf(fid, '%-8g%% n=%d\n', uniqueFreqs(i), freqCounts(i));
end
fprintf(fid, '\n');

% [epoch_window_sec]
fprintf(fid, '[epoch_window_sec]\n');
fprintf(fid, '%% Seconds of signal before and after each stimulus onset to include in epochs.\n');
fprintf(fid, '%% timeBefore must be > 0.9 s (the baseline z-score window minimum).\n');
fprintf(fid, '%% These defaults (0.95 s) were chosen for 0.5 Hz stimulation: at that\n');
fprintf(fid, '%% frequency the inter-stimulus interval is 2 s, so +/-0.95 s fits within\n');
fprintf(fid, '%% one period. Reduce these values proportionally for higher frequencies.\n');
fprintf(fid, 'timeBefore = 0.95\n');
fprintf(fid, 'timeAfter  = 0.95\n');
fprintf(fid, '\n');

% [regions]
fprintf(fid, '[regions]\n');
fprintf(fid, '%% Atlas region labels (FreeSurfer Destrieux APARC2009) sorted by occurrence count.\n');
fprintf(fid, '%% A file is included if either stimulation electrode (ch1ID or ch2ID) matches\n');
fprintf(fid, '%% any region in this list.\n');
for i = 1:length(uniqueRegions)
    fprintf(fid, ['%-' num2str(regionColWidth) 's%% n=%d\n'], uniqueRegions{i}, regionCounts(i));
end
fprintf(fid, '\n');

fclose(fid);

% --- Summary ---
fprintf('\nstim_filter.txt written to: %s\n', fullfile(pwd, outputFile));
fprintf('  Subjects processed : %d / %d\n', length(subjects) - length(skipped), length(subjects));
fprintf('  Amplitudes found   : %d unique value(s)\n', length(uniqueAmps));
fprintf('  Frequencies found  : %d unique value(s)\n', length(uniqueFreqs));
fprintf('  Regions found      : %d unique label(s)\n', length(uniqueRegions));

if ~isempty(skipped)
    fprintf('\nWarning: %d subject(s) skipped:\n', length(skipped));
    for i = 1:length(skipped)
        fprintf('  - %s\n', skipped{i});
    end
    fprintf('Re-run buildStimConfig() after preprocessing these subjects to capture their conditions.\n');
end

fprintf('\nReview stim_filter.txt and comment out any conditions to exclude,\nthen run dataPreprocess.m.\n\n');

end

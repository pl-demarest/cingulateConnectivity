function cfg = readStimFilter(filterFile)
% readStimFilter  Parse stim_filter.txt and return the preprocessing filter
%                 configuration as a struct.
%
% cfg = readStimFilter()             % looks for 'stim_filter.txt' in cwd
% cfg = readStimFilter(filterFile)   % specify alternate path
%
% Output struct fields:
%   cfg.amplitudes  -- double array of included stimulation amplitudes (mA)
%   cfg.frequencies -- double array of included stimulation frequencies (Hz)
%   cfg.timeBefore  -- scalar: seconds before stimulus onset for epoch window
%   cfg.timeAfter   -- scalar: seconds after stimulus onset for epoch window
%   cfg.regions     -- cell array of included atlas region label strings
%
% Lines beginning with % are treated as comments and ignored. Inline
% comments (% after a value) are stripped before parsing.

if nargin < 1
    filterFile = 'stim_filter.txt';
end

if ~isfile(filterFile)
    error(['readStimFilter: ''%s'' not found.\n' ...
           'Run buildStimConfig() to generate it.'], filterFile);
end

fid = fopen(filterFile, 'r');
if fid == -1
    error('readStimFilter: could not open ''%s''.', filterFile);
end

% Initialize defaults
cfg.amplitudes  = [];
cfg.frequencies = [];
cfg.timeBefore  = 0.95;
cfg.timeAfter   = 0.95;
cfg.regions     = {};

currentSection = '';

while ~feof(fid)
    raw = fgetl(fid);
    if ~ischar(raw), break; end

    % Strip inline comments and trim whitespace
    commentIdx = strfind(raw, '%');
    if ~isempty(commentIdx)
        raw = raw(1:commentIdx(1)-1);
    end
    line = strtrim(raw);

    if isempty(line), continue; end

    % Detect section header [section_name]
    if line(1) == '[' && line(end) == ']'
        currentSection = line(2:end-1);
        continue
    end

    % Parse content by section
    switch currentSection

        case 'amplitudes_mA'
            val = str2double(line);
            if ~isnan(val)
                cfg.amplitudes(end+1) = val; %#ok<AGROW>
            end

        case 'frequencies_Hz'
            val = str2double(line);
            if ~isnan(val)
                cfg.frequencies(end+1) = val; %#ok<AGROW>
            end

        case 'epoch_window_sec'
            % key = value format
            parts = strsplit(line, '=');
            if length(parts) == 2
                key = strtrim(parts{1});
                val = str2double(strtrim(parts{2}));
                if ~isnan(val)
                    switch key
                        case 'timeBefore'
                            cfg.timeBefore = val;
                        case 'timeAfter'
                            cfg.timeAfter = val;
                    end
                end
            end

        case 'regions'
            label = strtrim(line);
            if ~isempty(label)
                cfg.regions{end+1} = label; %#ok<AGROW>
            end

    end
end

fclose(fid);

% --- Validate ---
if isempty(cfg.amplitudes)
    error('readStimFilter: no amplitudes found in [amplitudes_mA] section of ''%s''.', filterFile);
end
if isempty(cfg.frequencies)
    error('readStimFilter: no frequencies found in [frequencies_Hz] section of ''%s''.', filterFile);
end
if isempty(cfg.regions)
    error('readStimFilter: no regions found in [regions] section of ''%s''.', filterFile);
end
if cfg.timeBefore <= 0.9
    warning(['readStimFilter: timeBefore=%.2f s is at or below the 0.9 s baseline ' ...
             'window minimum. The z-score baseline may be truncated or invalid.'], cfg.timeBefore);
end

end

function results = pf_checkEnvironment()
% PF_CHECKENVIRONMENT  Check MATLAB version and required toolboxes.
%
%   results = pf_checkEnvironment()
%
%   Returns a struct array of results (see pf_report for schema).
%   Checks performed:
%     - MATLAB version >= R2021b (9.11)
%     - Signal Processing Toolbox installed
%     - Statistics and Machine Learning Toolbox installed
%     - load_bcidat function available on the MATLAB path

results = struct('subject', {}, 'check', {}, 'status', {}, 'message', {});

fprintf('  Checking MATLAB environment...\n');

% -------------------------------------------------------------------------
% MATLAB version
% -------------------------------------------------------------------------
verStr = version;
verNum = str2double(regexp(verStr, '^\d+\.\d+', 'match', 'once'));
checkName = 'MATLAB version';
if verNum >= 9.11
    results(end+1) = mkEntry('', checkName, 'PASS', verStr);
else
    results(end+1) = mkEntry('', checkName, 'WARN', ...
        sprintf('%s detected; >= R2021b (9.11) recommended', verStr));
end

% -------------------------------------------------------------------------
% Signal Processing Toolbox
% -------------------------------------------------------------------------
checkName = 'Signal Processing Toolbox';
tbInfo = ver('signal');
if ~isempty(tbInfo)
    results(end+1) = mkEntry('', checkName, 'PASS', tbInfo(1).Version);
else
    results(end+1) = mkEntry('', checkName, 'FAIL', ...
        'Not found. Required for bandPassData, multi_iirnotch_filtering, smallLaplace.');
end

% -------------------------------------------------------------------------
% Statistics and Machine Learning Toolbox
% -------------------------------------------------------------------------
checkName = 'Statistics & ML Toolbox';
tbInfo = ver('stats');
if ~isempty(tbInfo)
    results(end+1) = mkEntry('', checkName, 'PASS', tbInfo(1).Version);
else
    results(end+1) = mkEntry('', checkName, 'FAIL', ...
        'Not found. Required for signrank, kruskalwallis used in poolData.');
end

% -------------------------------------------------------------------------
% load_bcidat on path
% -------------------------------------------------------------------------
% load_bcidat is distributed as a MEX file (.mexmaci64, .mexmaca64, .mexa64,
% .mexw64). The previous `exist(...) == 2` check matched only .m files and
% produced a false-negative when BCI2000 was correctly installed.
% `which` returns the resolved path for any callable form (MEX, .m, P-code).
checkName = 'load_bcidat on path';
loc = which('load_bcidat');
if ~isempty(loc)
    results(end+1) = mkEntry('', checkName, 'PASS', loc);
else
    results(end+1) = mkEntry('', checkName, 'FAIL', ...
        ['Not found. Ensure addpath(genpath(cd)) has been run from repo root ' ...
         'and that BCI2000 tools are installed at code/util/tools/. ' ...
         'load_bcidat is required to read BCI2000 .dat files in preprocessData.']);
end

end

% =========================================================================
function e = mkEntry(subject, check, status, message)
if nargin < 4, message = ''; end
e = struct('subject', subject, 'check', check, 'status', status, 'message', message);
end

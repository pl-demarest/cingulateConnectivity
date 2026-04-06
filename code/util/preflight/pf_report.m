function pf_report(results, reportPath)
% PF_REPORT  Print and optionally save the preflight validation report.
%
%   pf_report(results)
%   pf_report(results, reportPath)
%
%   results is a struct array where each element has:
%       .subject  (string) — subject ID, or '' for global checks
%       .check    (string) — name of the check performed
%       .status   (string) — 'PASS', 'WARN', or 'FAIL'
%       .message  (string) — optional detail or guidance
%
%   If reportPath is provided, a plain-text copy is also saved there.

if nargin < 2
    reportPath = '';
end

BAR = '=================================================================';
bar = '-----------------------------------------------------------------';

lines = {};  % accumulate all output lines for optional file write

lines{end+1} = '';
lines{end+1} = BAR;
lines{end+1} = '  cingulateConnectivity Preflight Report';
lines{end+1} = sprintf('  Generated: %s', datestr(now));
lines{end+1} = BAR;
lines{end+1} = '';

nPass = 0; nWarn = 0; nFail = 0;
currentSubject = 'NOT_SET';

for i = 1:length(results)
    r = results(i);

    % Print section header when subject changes
    if ~strcmp(r.subject, currentSubject)
        currentSubject = r.subject;
        if isempty(currentSubject)
            lines{end+1} = '  GLOBAL CHECKS';
        else
            lines{end+1} = '';
            lines{end+1} = sprintf('  Subject: %s', currentSubject);
        end
        lines{end+1} = ['  ' bar(1:60)];
    end

    switch r.status
        case 'PASS'
            sym = '[PASS]';
            nPass = nPass + 1;
        case 'WARN'
            sym = '[WARN]';
            nWarn = nWarn + 1;
        case 'FAIL'
            sym = '[FAIL]';
            nFail = nFail + 1;
        otherwise
            sym = '[????]';
    end

    if ~isempty(r.message)
        lines{end+1} = sprintf('  %s  %-42s  %s', sym, r.check, r.message);
    else
        lines{end+1} = sprintf('  %s  %s', sym, r.check);
    end
end

lines{end+1} = '';
lines{end+1} = BAR;
lines{end+1} = sprintf('  SUMMARY:  %d passed  |  %d warnings  |  %d failed', nPass, nWarn, nFail);

if nFail == 0 && nWarn == 0
    lines{end+1} = '  STATUS:   ALL CLEAR - ready to run the pipeline';
elseif nFail == 0
    lines{end+1} = '  STATUS:   READY WITH WARNINGS - review items marked [WARN]';
else
    lines{end+1} = '  STATUS:   NOT READY - resolve all [FAIL] items before running';
end
lines{end+1} = BAR;
lines{end+1} = '';

% Print to command window
for k = 1:length(lines)
    fprintf('%s\n', lines{k});
end

% Save to file if requested
if ~isempty(reportPath)
    fid = fopen(reportPath, 'w');
    if fid == -1
        warning('pf_report: could not write report to %s', reportPath);
        return
    end
    for k = 1:length(lines)
        fprintf(fid, '%s\n', lines{k});
    end
    fclose(fid);
    fprintf('  Report saved to: %s\n\n', reportPath);
end

end

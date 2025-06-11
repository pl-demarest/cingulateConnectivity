function appendLog(header, comments, results)
    % appendLog  Append (or overwrite) a log section in analysis_log.txt
    %
    %   appendLog(HEADER, COMMENTS, RESULTS) will:
    %     - remove any existing "==== HEADER ====" block
    %     - write a new block with:
    %         ==== HEADER ====
    %         Timestamp: <now>
    %         COMMENTS
    %         <table or vector of RESULTS>
    %
    logFileName = 'data/analysisLog.txt';
    
    %--- 1) Read existing file (if any) ---
    if exist(logFileName,'file')
        fid   = fopen(logFileName,'r');
        text  = fscanf(fid,'%c');
        fclose(fid);
    else
        text = '';
    end
    
    %--- 2) Strip out any old block with this header ---
    lines = regexp(text, '\r?\n', 'split');
    startIdx = find(startsWith(lines, ['==== ' header ' ====']), 1);
    if ~isempty(startIdx)
        % find the next header (or end-of-file)
        nextHdr = find(startsWith(lines(startIdx+1:end), '==== '), 1, 'first');
        if isempty(nextHdr)
            lines(startIdx:end) = [];
        else
            lines(startIdx:startIdx+nextHdr) = [];
        end
    end
    cleanText = strjoin(lines, newline);
    
    %--- 3) Re-open for write and re-print cleaned text ---
    fid = fopen(logFileName,'w');
    if ~isempty(cleanText)
        fprintf(fid, '%s\n', cleanText);
    end
    
    %--- 4) Write new block header & comments ---
    fprintf(fid, '\n==== %s ====\n', header);
    fprintf(fid, 'Timestamp: %s\n', datestr(now));
    fprintf(fid, '%s\n', comments);
    
    %--- 5) Decide: struct array (table) vs scalar struct ---
    if isstruct(results) && numel(results)>1
        % treat as table
        fields = fieldnames(results);
        % write column headers
        fprintf(fid, '%s', fields{1});
        for k=2:numel(fields)
            fprintf(fid, '\t%s', fields{k});
        end
        fprintf(fid, '\n');
        
        % write each row
        for i = 1:numel(results)
            for j = 1:numel(fields)
                val = results(i).(fields{j});
                str = convertValue(val);
                fprintf(fid, '%s', str);
                if j<numel(fields), fprintf(fid,'\t'); end
            end
            fprintf(fid, '\n');
        end
        
    elseif isstruct(results)
        % scalar struct: each subfield as column, rows = elements
        fields = fieldnames(results);
        % find max number of elements across subfields
        maxLen = 0;
        for i=1:numel(fields)
            f = results.(fields{i});
            if iscell(f)
                maxLen = max(maxLen, numel(f));
            else
                maxLen = max(maxLen, numel(f));
            end
        end
        
        % header row
        fprintf(fid, '%s', fields{1});
        for i=2:numel(fields)
            fprintf(fid, '\t%s', fields{i});
        end
        fprintf(fid, '\n');
        
        % data rows
        for row=1:maxLen
            for i=1:numel(fields)
                f = results.(fields{i});
                if iscell(f)
                    if row<=numel(f), v = f{row}; else v = []; end
                else
                    if row<=numel(f), v = f(row); else v = []; end
                end
                fprintf(fid, '%s', convertValue(v));
                if i<numel(fields), fprintf(fid,'\t'); end
            end
            fprintf(fid,'\n');
        end
        
    else
        % not a struct at all: just dump it
        fprintf(fid, 'Results: %s\n', convertValue(results));
    end
    
    fclose(fid);
end

function str = convertValue(v)
    % convertValue  Turn mixed data into a single string
    if isnumeric(v) || islogical(v)
        if isscalar(v)
            str = num2str(v);
        else
            str = mat2str(v);
        end
        
    elseif ischar(v)
        str = v;
        
    elseif isstring(v)
        str = char(v);
        
    elseif iscell(v)
        % apply ourselves recursively and join with commas
        parts = cellfun(@convertValue, v, 'UniformOutput',false);
        str = strjoin(parts, ',');
        
    else
        % fallback
        str = '[unhandled type]';
    end
end

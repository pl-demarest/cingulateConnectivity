function normalized = normalizeToRange(data, x, y)
    % Normalize non-NaN values in data to the range [x, y] while keeping NaNs intact.
    
    normalized = data;               % Pre-allocate output, preserving NaN positions
    valid = ~isnan(data);            % Logical index of valid (non-NaN) entries
    
    % If there are valid entries, proceed with normalization.
    if any(valid)
        dataMin = min(data(valid));
        dataMax = max(data(valid));
        % Avoid division by zero if all valid values are the same.
        if dataMax == dataMin
            normalized(valid) = x;  % Arbitrary constant when no spread exists
        else
            normalized(valid) = ((data(valid) - dataMin) / (dataMax - dataMin)) * (y - x) + x;
        end
    end
end

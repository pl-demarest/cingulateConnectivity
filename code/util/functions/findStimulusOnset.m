function first_index = findStimulusOnset(stimulus, threshold)

%This function will find the onset of a stimulus based on a set threshold. 

    first_index = []; % Initialize output
    i = 1;
    while i <= length(stimulus)
        if stimulus(i) > threshold % Check if stimulus at index i exceeds threshold
            first_index = [first_index i]; % Append index to output
            % Skip indices until stimulus goes below threshold again
            while i <= length(stimulus) && stimulus(i) > threshold
                i = i + 1;
            end
        end
        i = i + 1;
    end
end
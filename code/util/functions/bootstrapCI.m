function [lowerBound, upperBound] = bootstrapCI(data, numBoots)
    if nargin < 2
        numBoots = 1000;  % default number of bootstrap samples
    end

    % Remove NaNs
    data = data(~isnan(data));
    n = length(data);
    
    % Bootstrap resampling
    bootMeans = zeros(1, numBoots);
    for i = 1:numBoots
        sample = data(randi(n, 1, n));  % resample with replacement
        bootMeans(i) = mean(sample);
    end

    % Get 2.5th and 97.5th percentiles
    lowerBound = prctile(bootMeans, 2.5);
    upperBound = prctile(bootMeans, 97.5);
end

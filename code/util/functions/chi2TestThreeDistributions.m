function [chi2stat, df, p_value] = chi2TestThreeDistributions(data1, data2, data3, nbins)
% chi2TestThreeDistributions compares three distributions using a chi-square test.
%
%   [chi2stat, df, p_value] = chi2TestThreeDistributions(data1, data2, data3)
%   compares the three raw data vectors data1, data2, and data3 by:
%     1. Binning the data into a common set of bins determined from the overall
%        minimum and maximum values.
%     2. Normalizing the histogram counts to obtain probability distributions.
%     3. Recovering the observed counts by multiplying the probabilities by
%        the number of samples in each dataset.
%     4. Constructing a contingency table and computing the chi-square statistic.
%
%   You can also specify the number of bins:
%      [chi2stat, df, p_value] = chi2TestThreeDistributions(data1, data2, data3, nbins)
%
%   Outputs:
%     chi2stat - Chi-square statistic.
%     df       - Degrees of freedom.
%     p_value  - p-value of the chi-square test.
%
%   Note: Make sure that each bin has an expected count of at least 5 for the 
%   chi-square test to be reliable.

    % Check if nbins is provided, if not set default to 10
    if nargin < 4 || isempty(nbins)
        nbins = 10;
    end

    % Define common bin edges from the overall min and max of the data
    allData = [data1(:); data2(:); data3(:)];
    edges = linspace(min(allData), max(allData), nbins+1);
    
    % Compute normalized histogram counts for each dataset
    normCounts1 = histcounts(data1, edges, 'Normalization', 'probability');
    normCounts2 = histcounts(data2, edges, 'Normalization', 'probability');
    normCounts3 = histcounts(data3, edges, 'Normalization', 'probability');
    
    % Recover observed counts by multiplying probabilities by number of samples
    obsCounts1 = normCounts1 * numel(data1);
    obsCounts2 = normCounts2 * numel(data2);
    obsCounts3 = normCounts3 * numel(data3);
    
    % Create contingency table: rows = bins, columns = datasets
    observed = [obsCounts1(:) , obsCounts2(:) , obsCounts3(:)];
    
    % Calculate expected counts under the null hypothesis
    rowSums = sum(observed, 2);    % sum across groups for each bin
    colSums = sum(observed, 1);    % sum across bins for each dataset
    total    = sum(observed(:));   % overall total count
    
    expected = (rowSums * colSums) / total;
    
    % Compute chi-square statistic
    chi2stat = sum((observed - expected).^2 ./ expected, 'all');
    
    % Degrees of freedom: (number of bins - 1) * (number of groups - 1)
    [numBins, numGroups] = size(observed);
    df = (numBins - 1) * (numGroups - 1);
    
    % Calculate p-value from the chi-square distribution
    p_value = 1 - chi2cdf(chi2stat, df);
    
    % Optionally, display results
    fprintf('Chi-square statistic: %.3f\nDegrees of freedom: %d\np-value: %.4f\n', ...
            chi2stat, df, p_value);
end

function results = compareDistributions(data1, data2, data3)
% compareDistributions compares three distributions using a permutation
% test on the normalized probability distributions.
%
% INPUTS:
%   data1, data2, data3 - vectors of sample locations for conditions 1, 2, and 3.
%
% OUTPUT:
%   results - a structure containing the observed divergence values and p-values
%             for each pairwise comparison.
%
% Example:
%   results = compareDistributions(data_condition1, data_condition2, data_condition3);

    % Set parameters
    nBins = 50;       % number of bins to use for the histograms
    nPerm = 1000;     % number of permutations for the permutation test

    % Create a common set of bin edges based on all the data
    allData = [data1(:); data2(:); data3(:)]; % ensure column vectors
    edges = linspace(min(allData), max(allData), nBins+1);

    % Compute histograms and normalize to create probability distributions
    counts1 = histcounts(data1, edges);
    counts2 = histcounts(data2, edges);
    counts3 = histcounts(data3, edges);
    
    pdf1 = counts1 / sum(counts1);
    pdf2 = counts2 / sum(counts2);
    pdf3 = counts3 / sum(counts3);
    
    % Compute observed divergence measures (sum of squared differences)
    observed12 = sum((pdf1 - pdf2).^2);
    observed13 = sum((pdf1 - pdf3).^2);
    observed23 = sum((pdf2 - pdf3).^2);
    
    % Run permutation tests for each pairwise comparison
    p12 = permutationTest(data1, data2, edges, observed12, nPerm);
    p13 = permutationTest(data1, data3, edges, observed13, nPerm);
    p23 = permutationTest(data2, data3, edges, observed23, nPerm);
    
    % Output results in a structure
    results = struct('observed12', observed12, 'p12', p12, ...
                     'observed13', observed13, 'p13', p13, ...
                     'observed23', observed23, 'p23', p23);
end

function pValue = permutationTest(dataA, dataB, edges, observedDiff, nPerm)
% permutationTest performs a permutation test between two datasets.
%
% INPUTS:
%   dataA, dataB  - vectors of sample locations for the two conditions.
%   edges         - common bin edges for histogramming.
%   observedDiff  - the observed divergence (sum of squared differences).
%   nPerm         - number of permutations.
%
% OUTPUT:
%   pValue        - p-value from the permutation test.

    diffPerm = zeros(nPerm, 1);
    combinedData = [dataA(:); dataB(:)];
    nA = length(dataA);

    for i = 1:nPerm
        permIdx = randperm(length(combinedData));
        permDataA = combinedData(permIdx(1:nA));
        permDataB = combinedData(permIdx(nA+1:end));
        
        % Compute normalized histograms for the permuted groups
        countsA = histcounts(permDataA, edges);
        countsB = histcounts(permDataB, edges);
        
        pdfA = countsA / sum(countsA);
        pdfB = countsB / sum(countsB);
        
        % Compute divergence (sum of squared differences)
        diffPerm(i) = sum((pdfA - pdfB).^2);
    end
    
    % Calculate p-value as fraction of permuted divergences that are
    % greater than or equal to the observed divergence
    pValue = sum(diffPerm >= observedDiff) / nPerm;
end

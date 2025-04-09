function results = compareBinProportions(data1, data2, data3, nbins, data1_sig, data2_sig, data3_sig)
% compareBinProportions compares the probability (proportion) of sampling 
% in each bin between three datasets.
%
%   results = compareBinProportions(data1, data2, data3)
%   uses a default of 10 bins.
%
%   results = compareBinProportions(data1, data2, data3, nbins)
%   lets you specify the number of bins.
%
%   results = compareBinProportions(data1, data2, data3, nbins, data1_sig, data2_sig, data3_sig)
%   in addition to the total data, accepts “significant only” data for each condition.
%
%   The function:
%     1. Computes common bin edges from the combined total data.
%     2. Generates histogram counts (without normalization) for each dataset.
%     3. For each bin, calculates the proportion (count divided by total samples).
%     4. Performs pairwise two-sample z-tests for proportions between:
%          - data1 vs. data2,
%          - data1 vs. data3, and
%          - data2 vs. data3.
%     5. (If provided) Calculates, for each bin, the percentage of significant data.
%
%   It returns a structure "results" containing:
%     - The bin edges and centers,
%     - The raw counts in each bin for each dataset,
%     - The normalized probabilities (as would be plotted by a histogram with 'Normalization', 'probability'),
%     - The z-statistics and corresponding p-values for each pairwise comparison,
%     - If provided, the percentage of significant data in each bin for each dataset.
%
%   Note: The z-test for proportions is given by:
%         z = (p1 - p2) / sqrt(pooled*(1-pooled)*(1/n1 + 1/n2))
%         where pooled = (count1+count2)/(n1+n2).
%
%   Adjust for multiple comparisons as needed.

    if nargin < 4 || isempty(nbins)
        nbins = 10;  % Default number of bins if not provided
    end

    % Determine common bin edges based on the overall total data range
    allData = [data1(:); data2(:); data3(:)];
    edges = linspace(min(allData), max(allData), nbins+1);
    binCenters = (edges(1:end-1) + edges(2:end)) / 2;

    % Compute counts (not normalized) for each bin for every dataset
    counts1 = histcounts(data1, edges);
    counts2 = histcounts(data2, edges);
    counts3 = histcounts(data3, edges);

    % Total number of samples in each dataset
    n1 = numel(data1);
    n2 = numel(data2);
    n3 = numel(data3);

    % Preallocate arrays for pairwise z-statistics and p-values
    z12 = zeros(1, nbins);
    p12 = zeros(1, nbins);
    z13 = zeros(1, nbins);
    p13 = zeros(1, nbins);
    z23 = zeros(1, nbins);
    p23 = zeros(1, nbins);

    % Loop over each bin and perform pairwise proportion tests
    for i = 1:nbins
        % --- Comparison: data1 vs. data2 ---
        p1 = counts1(i) / n1;
        p2 = counts2(i) / n2;
        pooled12 = (counts1(i) + counts2(i)) / (n1 + n2);
        se12 = sqrt(pooled12 * (1 - pooled12) * (1/n1 + 1/n2));
        if se12 == 0
            z12(i) = 0;
            p12(i) = 1;
        else
            z12(i) = (p1 - p2) / se12;
            p12(i) = 2 * (1 - normcdf(abs(z12(i))));
        end

        % --- Comparison: data1 vs. data3 ---
        p1 = counts1(i) / n1;
        p3 = counts3(i) / n3;
        pooled13 = (counts1(i) + counts3(i)) / (n1 + n3);
        se13 = sqrt(pooled13 * (1 - pooled13) * (1/n1 + 1/n3));
        if se13 == 0
            z13(i) = 0;
            p13(i) = 1;
        else
            z13(i) = (p1 - p3) / se13;
            p13(i) = 2 * (1 - normcdf(abs(z13(i))));
        end

        % --- Comparison: data2 vs. data3 ---
        p2 = counts2(i) / n2;
        p3 = counts3(i) / n3;
        pooled23 = (counts2(i) + counts3(i)) / (n2 + n3);
        se23 = sqrt(pooled23 * (1 - pooled23) * (1/n2 + 1/n3));
        if se23 == 0
            z23(i) = 0;
            p23(i) = 1;
        else
            z23(i) = (p2 - p3) / se23;
            p23(i) = 2 * (1 - normcdf(abs(z23(i))));
        end
    end

    % Organize the results into a structure for output
    results.binEdges   = edges;
    results.binCenters = binCenters;
    results.counts1    = counts1;
    results.counts2    = counts2;
    results.counts3    = counts3;
    results.n1         = n1;
    results.n2         = n2;
    results.n3         = n3;
    results.z12        = z12;
    results.p12        = p12;
    results.z13        = z13;
    results.p13        = p13;
    results.z23        = z23;
    results.p23        = p23;
    
    % --- Normalized probabilities for each bin ---
    results.prob1 = counts1 ./ n1;
    results.prob2 = counts2 ./ n2;
    results.prob3 = counts3 ./ n3;
    
    % --- Calculate percentage of significant data in each bin, if provided ---
    if nargin >= 7 && ~isempty(data1_sig) && ~isempty(data2_sig) && ~isempty(data3_sig)
        counts1_sig = histcounts(data1_sig, edges);
        counts2_sig = histcounts(data2_sig, edges);
        counts3_sig = histcounts(data3_sig, edges);
        
        % Compute percentage of significant data per bin for each distribution.
        % Multiply by 100 to convert to percentage and avoid division by zero.
        sigPercent1 = 100 * (counts1_sig ./ counts1);
        sigPercent2 = 100 * (counts2_sig ./ counts2);
        sigPercent3 = 100 * (counts3_sig ./ counts3);
        
        % Set percentage to NaN where no total data exists in a bin.
        sigPercent1(counts1 == 0) = NaN;
        sigPercent2(counts2 == 0) = NaN;
        sigPercent3(counts3 == 0) = NaN;
        
        results.sigPercent1 = sigPercent1;
        results.sigPercent2 = sigPercent2;
        results.sigPercent3 = sigPercent3;
    end
end

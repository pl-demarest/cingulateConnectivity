function [optimalThreshold, thresholdMetrics] = findOptimalClusterThreshold(Z, thresholdRange, method)
    % FINDOPTIMALCLUSTERTHRESHOLD Finds optimal threshold for hierarchical clustering
    %
    % Inputs:
    %   Z               - Linkage matrix from hierarchical clustering
    %   thresholdRange  - Vector of thresholds to evaluate (default: 0.1:0.05:0.9)
    %   method          - Method for determining optimal threshold (default: 'balanced')
    %                     'balanced': Maximize clusters with evenly distributed regions
    %                     'similarity': Maximize cluster similarity/cohesion
    %
    % Outputs:
    %   optimalThreshold  - The optimal threshold value
    %   thresholdMetrics  - Structure with metrics for each threshold, including:
    %                       - threshold: The distance threshold value
    %                       - numClusters: Number of clusters at this threshold
    %                       - shannonEntropy: Shannon entropy of cluster sizes
    %                       - naturalBreakPoints: Array of natural break points in the dendrogram
    %                       - coreMetrics: Structure containing:
    %                           - naturalBreakScore: Score for natural break points
    %                           - balanceScore: Score for cluster balance
    %                           - diversityScore: Score for cluster diversity
    %
    % The 'balanced' method evaluates thresholds based on:
    %   1. All clusters with ≤2 regions are masked out first
    %   2. There should be more than 1 total cluster after masking
    %   3. PRIMARY GOAL: Maximize the number of clusters
    %   4. PRIMARY GOAL: Minimize differences in the number of regions between clusters
    %   5. SECONDARY: The total number of regions should be maximized
    %   6. If there are ties, the largest distance threshold is chosen
    %
    % The 'similarity' method evaluates thresholds based on:
    %   1. All clusters with ≤2 regions are masked out first
    %   2. There should be more than 1 total cluster after masking
    %   3. Maximizing cluster similarity/cohesion by finding natural break points
    %      in the linkage height (using gap statistics)
    
    % Default threshold range if not provided
    if nargin < 2 || isempty(thresholdRange)
        thresholdRange = 0.1:0.01:0.9;
    end
    
    % Default method if not provided
    if nargin < 3 || isempty(method)
        method = 'balanced';
    end
    
    % Initialize metrics structure
    thresholdMetrics = struct();
    
    % Calculate tree-wide diversity metrics (independent of threshold)
    n = size(Z, 1) + 1;  % Number of original data points
    heights = Z(:,3);
    
    % Cophenetic correlation coefficient - how well dendrogram preserves distances
    originalDist = squareform(pdist(Z));
    [coph, cophenCorr] = cophenet(Z, originalDist);
    
    % Calculate tree diversification metrics 
    % (how height increases throughout the tree)
    sortedHeights = sort(heights);
    heightDiffs = diff(sortedHeights);
    treeHeightProfile = heightDiffs / sum(heightDiffs);
    
    % Calculate height gradient metrics across the entire tree
    heightCV = std(heights) / mean(heights);  % Coefficient of variation of heights
    
    % Calculate the full height gradient distribution
    heightGradient = diff(sortedHeights) ./ sortedHeights(1:end-1);
    medianHeightGradient = median(heightGradient);
    meanHeightGradient = mean(heightGradient);
    maxHeightGradient = max(heightGradient);
    
    % Calculate quartiles for height distribution to capture shape
    heightQuartiles = quantile(sortedHeights, [0.25, 0.5, 0.75]);
    heightIQR = heightQuartiles(3) - heightQuartiles(1);
    
    % Agglomerative coefficient
    sumHeights = sum(heights);
    if sumHeights > 0
        agglomCoeff = 1 - (n / sumHeights);
    else
        agglomCoeff = 0;
    end
    
    % For each threshold, compute metrics
    for i = 1:length(thresholdRange)
        threshold = thresholdRange(i);
        
        % Get clusters at this threshold
        clusters = cluster(Z, 'Cutoff', threshold, 'Criterion', 'distance');
        
        % Count regions in each cluster
        uniqueClusters = unique(clusters);
        clusterCounts = zeros(length(uniqueClusters), 1);
        
        for j = 1:length(uniqueClusters)
            clusterCounts(j) = sum(clusters == uniqueClusters(j));
        end
        
        % Identify small clusters (≤2 regions)
        smallClusters = uniqueClusters(clusterCounts <= 2);
        
        % Mask out small clusters
        validClusters = setdiff(uniqueClusters, smallClusters);
        
        % Calculate metrics after masking
        numClusters = length(validClusters);
        
        % Initialize coreMetrics structure for this threshold
        thresholdMetrics(i).coreMetrics = struct(...
            'naturalBreakScore', 0, ...
            'balanceScore', 0, ...
            'diversityScore', 0);
        
        if numClusters > 0
            % Count regions in each valid cluster
            validClusterCounts = zeros(numClusters, 1);
            for j = 1:numClusters
                validClusterCounts(j) = sum(clusters == validClusters(j));
            end
            
            totalRegionsInClusters = sum(validClusterCounts);
            avgRegionsPerCluster = mean(validClusterCounts);
            
            % Calculate cluster balance metric (coefficient of variation)
            % Lower values indicate more even distribution of cluster sizes
            if numClusters > 1
                clusterSizeCV = std(validClusterCounts) / mean(validClusterCounts);
            else
                clusterSizeCV = 0; % Only one cluster, so perfectly balanced
            end
            
            % Calculate Shannon entropy of cluster sizes
            % Higher values indicate more diverse cluster sizes
            p = validClusterCounts / totalRegionsInClusters;
            shannonEntropy = -sum(p .* log2(p + eps));
            
            % Calculate dominance index (similar to Simpson's index)
            % Lower values indicate more even distribution
            dominanceIndex = sum((validClusterCounts ./ totalRegionsInClusters).^2);
            
            % Calculate Pielou's evenness (normalized entropy)
            maxEntropy = log2(numClusters);
            pielouEvenness = shannonEntropy / (maxEntropy + eps);
            
            % Store metrics for this threshold
            thresholdMetrics(i).threshold = threshold;
            thresholdMetrics(i).numClusters = numClusters;
            thresholdMetrics(i).totalRegions = totalRegionsInClusters;
            thresholdMetrics(i).avgRegionsPerCluster = avgRegionsPerCluster;
            thresholdMetrics(i).clusterSizeCV = clusterSizeCV;
            thresholdMetrics(i).validClusters = validClusters;
            thresholdMetrics(i).validClusterCounts = validClusterCounts;
            
            % Store diversity metrics
            thresholdMetrics(i).shannonEntropy = shannonEntropy;
            thresholdMetrics(i).dominanceIndex = dominanceIndex;
            thresholdMetrics(i).pielouEvenness = pielouEvenness;
            
            % Calculate the ratio of clusters to total points (normalized diversity)
            thresholdMetrics(i).clusterDensity = numClusters / totalRegionsInClusters;
            
            % Calculate effective number of clusters (exponential of entropy)
            thresholdMetrics(i).effectiveNumClusters = 2^shannonEntropy;
            
            % Calculate relative diversity (ratio of effective to actual clusters)
            thresholdMetrics(i).relativeDiversity = (2^shannonEntropy) / numClusters;
            
            % Store core metrics
            thresholdMetrics(i).coreMetrics.naturalBreakScore = 0;  % Will be updated later
            thresholdMetrics(i).coreMetrics.balanceScore = 1 - clusterSizeCV;
            thresholdMetrics(i).coreMetrics.diversityScore = shannonEntropy / maxEntropy;
            
            % ---------- NEW: Calculate within-cluster height diversity ----------
            % For each cluster, calculate height diversity of internal structure
            withinClusterHeightCV = zeros(numClusters, 1);
            withinClusterHeightRange = zeros(numClusters, 1);
            
            % Get all heights from the dendrogram
            heights = Z(:,3);
            
            for j = 1:numClusters
                % Get indices of points in this cluster
                clusterIdx = validClusters(j);
                clusterMembers = find(clusters == clusterIdx);
                
                if length(clusterMembers) > 1
                    % Find all merges involving only members of this cluster
                    withinClusterMerges = [];
                    
                    % Trace through the linkage matrix
                    for k = 1:size(Z,1)
                        c1 = Z(k,1) + 1; % Convert to 1-based indexing
                        c2 = Z(k,2) + 1;
                        
                        % Check if both points/clusters being merged are in our cluster
                        if threshold >= Z(k,3) && all(ismember([c1, c2], clusterMembers))
                            withinClusterMerges = [withinClusterMerges; Z(k,3)];
                        end
                    end
                    
                    % Calculate height statistics for this cluster's internal structure
                    if ~isempty(withinClusterMerges)
                        withinClusterHeightCV(j) = std(withinClusterMerges) / (mean(withinClusterMerges) + eps);
                        withinClusterHeightRange(j) = range(withinClusterMerges) / (max(heights) + eps);
                    end
                end
            end
            
            % Calculate average within-cluster height diversity weighted by cluster size
            weightedAvgHeightCV = sum(withinClusterHeightCV .* (validClusterCounts / totalRegionsInClusters));
            weightedAvgHeightRange = sum(withinClusterHeightRange .* (validClusterCounts / totalRegionsInClusters));
            
            % Store within-cluster diversity metrics
            thresholdMetrics(i).withinClusterHeightCV = withinClusterHeightCV;
            thresholdMetrics(i).avgWithinClusterHeightCV = weightedAvgHeightCV;
            thresholdMetrics(i).avgWithinClusterHeightRange = weightedAvgHeightRange;
            
            % ---------- NEW: Composite Diversity Index ----------
            % Combine between-cluster diversity (relativeDiversity) with within-cluster height diversity
            % Both components range from 0-1, so the composite index also ranges from 0-1
            betweenClusterDiversity = thresholdMetrics(i).relativeDiversity;
            withinClusterDiversity = weightedAvgHeightCV / (1 + weightedAvgHeightCV); % Transform to 0-1 range
            
            % Calculate composite index - equal weighting of both aspects
            thresholdMetrics(i).compositeDiversityIndex = sqrt(betweenClusterDiversity * withinClusterDiversity);
            
            % Alternate composite index with custom weights
            betweenWeight = 0.6; % Weight for between-cluster diversity
            withinWeight = 0.4;  % Weight for within-cluster diversity
            thresholdMetrics(i).weightedCompositeDiversity = (betweenWeight * betweenClusterDiversity) + (withinWeight * withinClusterDiversity);
        else
            % If no valid clusters remain after masking
            thresholdMetrics(i).threshold = threshold;
            thresholdMetrics(i).numClusters = 0;
            thresholdMetrics(i).totalRegions = 0;
            thresholdMetrics(i).avgRegionsPerCluster = 0;
            thresholdMetrics(i).clusterSizeCV = Inf; % Worst possible balance
            thresholdMetrics(i).validClusters = [];
            thresholdMetrics(i).validClusterCounts = [];
            
            % Store zero diversity when no valid clusters
            thresholdMetrics(i).shannonEntropy = 0;
            thresholdMetrics(i).dominanceIndex = 1; % Complete dominance
            thresholdMetrics(i).pielouEvenness = 0;
            thresholdMetrics(i).clusterDensity = 0;
            thresholdMetrics(i).effectiveNumClusters = 0;
            thresholdMetrics(i).relativeDiversity = 0;
            
            % Set core metrics to zero
            thresholdMetrics(i).coreMetrics.naturalBreakScore = 0;
            thresholdMetrics(i).coreMetrics.balanceScore = 0;
            thresholdMetrics(i).coreMetrics.diversityScore = 0;
            
            % Set within-cluster diversity metrics to zero
            thresholdMetrics(i).withinClusterHeightCV = [];
            thresholdMetrics(i).avgWithinClusterHeightCV = 0;
            thresholdMetrics(i).avgWithinClusterHeightRange = 0;
            thresholdMetrics(i).compositeDiversityIndex = 0;
            thresholdMetrics(i).weightedCompositeDiversity = 0;
        end
        
        % Calculate tree morphology at this threshold
        heightsBelow = heights(heights <= threshold);
        if ~isempty(heightsBelow)
            % Calculate the proportion of merges below this threshold
            thresholdMetrics(i).mergeRatio = length(heightsBelow) / length(heights);
            
            % Calculate rate of height increase near this threshold
            nearThresholdHeights = heights(heights >= 0.9*threshold & heights <= 1.1*threshold);
            if length(nearThresholdHeights) > 1
                thresholdMetrics(i).localHeightGradient = std(nearThresholdHeights) / mean(nearThresholdHeights);
            else
                thresholdMetrics(i).localHeightGradient = 0;
            end
        else
            thresholdMetrics(i).mergeRatio = 0;
            thresholdMetrics(i).localHeightGradient = 0;
        end
    end
    
    % Add global tree diversity metrics to all threshold entries
    for i = 1:length(thresholdRange)
        thresholdMetrics(i).cophenicCorrelation = cophenCorr;
        thresholdMetrics(i).agglomerativeCoefficient = agglomCoeff;
        thresholdMetrics(i).treeHeightProfile = treeHeightProfile;
        
        % Add global tree height gradient metrics
        thresholdMetrics(i).heightCV = heightCV;
        thresholdMetrics(i).medianHeightGradient = medianHeightGradient;
        thresholdMetrics(i).meanHeightGradient = meanHeightGradient;
        thresholdMetrics(i).maxHeightGradient = maxHeightGradient;
        thresholdMetrics(i).heightIQR = heightIQR;
        
        % Calculate tree balance score at this threshold level
        balanceScores = calculateTreeBalanceScores(Z);
        heightsBelow = heights(heights <= thresholdRange(i));
        if ~isempty(heightsBelow)
            relevantBalanceScores = balanceScores(heights <= thresholdRange(i));
            thresholdMetrics(i).meanTreeBalance = mean(relevantBalanceScores);
            thresholdMetrics(i).treeBalanceVariation = std(relevantBalanceScores);
        else
            thresholdMetrics(i).meanTreeBalance = NaN;
            thresholdMetrics(i).treeBalanceVariation = NaN;
        end
    end
    
    % Filter out thresholds with fewer than 2 clusters
    validThresholds = arrayfun(@(x) x.numClusters > 1, thresholdMetrics);
    validMetrics = thresholdMetrics(validThresholds);
    
    % If no valid thresholds, return the one with the most regions
    if isempty(validMetrics)
        [~, maxRegionIdx] = max(arrayfun(@(x) x.totalRegions, thresholdMetrics));
        optimalThreshold = thresholdMetrics(maxRegionIdx).threshold;
        return;
    end
    
    % Choose optimal threshold based on selected method
    switch lower(method)
        case 'balanced'
            % BALANCED METHOD: Maximize clusters with even distribution
            % Calculate composite score for each threshold using the balanced approach
            optimalThreshold = findBalancedThreshold(validMetrics);
        case 'similarity'
            % SIMILARITY METHOD: Maximize cluster similarity/cohesion
            [optimalThreshold, validMetrics] = findSimilarityThreshold(Z, validMetrics);
        otherwise
            error('Unknown method: %s. Use ''balanced'' or ''similarity''.', method);
    end
    
    % Ensure we're returning a single scalar threshold value
    if length(optimalThreshold) > 1
        warning('Multiple optimal thresholds found, using the first one.');
        optimalThreshold = optimalThreshold(1);
    end
    
    % Update the original metrics structure with composite scores
    for i = 1:length(validMetrics)
        idx = find(arrayfun(@(x) x.threshold == validMetrics(i).threshold, thresholdMetrics));
        if isfield(validMetrics, 'compositeScore')
            thresholdMetrics(idx).compositeScore = validMetrics(i).compositeScore;
        end
        if isfield(validMetrics, 'naturalBreakPoints')
            thresholdMetrics(idx).naturalBreakPoints = validMetrics(i).naturalBreakPoints;
        end
    end
end

function optimalThreshold = findBalancedThreshold(validMetrics)
    % Helper function to find optimal threshold using the balanced approach
    
    numValidThresholds = length(validMetrics);
    thresholdValues = arrayfun(@(x) x.threshold, validMetrics);
    totalRegionsValues = arrayfun(@(x) x.totalRegions, validMetrics);
    avgRegionsValues = arrayfun(@(x) x.avgRegionsPerCluster, validMetrics);
    numClustersValues = arrayfun(@(x) x.numClusters, validMetrics);
    clusterBalanceValues = arrayfun(@(x) x.clusterSizeCV, validMetrics);
    
    % Normalize each metric to [0,1] range
    normTotalRegions = (totalRegionsValues - min(totalRegionsValues)) / (max(totalRegionsValues) - min(totalRegionsValues) + eps);
    normAvgRegions = (avgRegionsValues - min(avgRegionsValues)) / (max(avgRegionsValues) - min(avgRegionsValues) + eps);
    normNumClusters = (numClustersValues - min(numClustersValues)) / (max(numClustersValues) - min(numClustersValues) + eps);
    
    % For cluster balance, lower is better, so invert the normalization
    normClusterBalance = 1 - (clusterBalanceValues - min(clusterBalanceValues)) / (max(clusterBalanceValues) - min(clusterBalanceValues) + eps);
    
    % Apply weights to prioritize maximizing clusters and minimizing size differences
    % Higher weights for our primary goals
    weightNumClusters = 2.0;  % Primary goal
    weightClusterBalance = 2.0;  % Primary goal
    weightTotalRegions = 1.0;  % Secondary
    weightAvgRegions = 1.0;  % Secondary
    
    % Calculate composite score with our weighted priorities
    compositeScores = (weightNumClusters * normNumClusters) + (weightClusterBalance * normClusterBalance) + (weightTotalRegions * normTotalRegions) + (weightAvgRegions * normAvgRegions);
    
    % Find maximum score and all thresholds that have this score (potential ties)
    maxScore = max(compositeScores);
    tieIndices = find(abs(compositeScores - maxScore) < eps);
    
    % If there are ties, choose the one with the highest threshold
    if length(tieIndices) > 1
        [~, maxThresholdIdx] = max(thresholdValues(tieIndices));
        maxScoreIdx = tieIndices(maxThresholdIdx);
    else
        maxScoreIdx = find(compositeScores == maxScore, 1);
    end
    
    % Ensure we return a single value
    optimalThreshold = validMetrics(maxScoreIdx).threshold;
    if length(optimalThreshold) > 1
        optimalThreshold = optimalThreshold(1);
    end
    
    % Add scores to metrics structure
    for i = 1:numValidThresholds
        validMetrics(i).compositeScore = compositeScores(i);
    end
end

function [optimalThreshold, validMetrics] = findSimilarityThreshold(Z, validMetrics)
    % Helper function to find optimal threshold using the similarity approach
    % Simplified version focusing on core, independent metrics
    
    % Extract heights from the linkage matrix
    heights = Z(:,3);
    n = size(Z, 1) + 1;  % Number of original data points
    
    % Sort heights for structural analysis
    sortedHeights = sort(heights);
    
    % Calculate merge density at different heights
    numBins = 20;
    [mergeDensity, binEdges] = histcounts(heights, numBins);
    binCenters = (binEdges(1:end-1) + binEdges(2:end)) / 2;
    
    % Normalize merge density and ensure it's a column vector
    normMergeDensity = (mergeDensity / max(mergeDensity))';
    
    % Find local minima in merge density (potential natural breaks)
    localMinima = find(diff(sign(diff([Inf; normMergeDensity; Inf]))) > 0);
    naturalBreakPoints = binCenters(localMinima);
    
    % Extract basic metrics
    thresholdValues = arrayfun(@(x) x.threshold, validMetrics);
    totalRegionsValues = arrayfun(@(x) x.totalRegions, validMetrics);
    regionRatios = totalRegionsValues / n;
    
    % 1. Tree Structure Score (based on height distribution)
    treeStructureScore = std(diff(sortedHeights)) / mean(sortedHeights);
    
    % 2. Natural Break Score (fundamental structural metric)
    naturalBreakScores = zeros(size(thresholdValues));
    for i = 1:length(thresholdValues)
        distances = abs(naturalBreakPoints - thresholdValues(i));
        naturalBreakScores(i) = 1 - min(distances) / max(heights);
    end
    
    % 3. Cluster Balance Score (simplified from multiple metrics)
    clusterSizeCV = arrayfun(@(x) x.clusterSizeCV, validMetrics);
    balanceScores = 1 - (clusterSizeCV - min(clusterSizeCV)) / (max(clusterSizeCV) - min(clusterSizeCV) + eps);
    
    % 4. Diversity Score (using only Shannon entropy as primary diversity metric)
    shannonEntropyValues = arrayfun(@(x) x.shannonEntropy, validMetrics);
    diversityScores = (shannonEntropyValues - min(shannonEntropyValues)) / (max(shannonEntropyValues) - min(shannonEntropyValues) + eps);
    
    % Calculate adaptive weights based on tree structure
    % This adapts to the specific characteristics of each tree
    heightPercentiles = prctile(heights, [25 50 75]);
    relativeHeightPos = zeros(size(thresholdValues));
    for i = 1:length(thresholdValues)
        relativeHeightPos(i) = sum(heights <= thresholdValues(i)) / length(heights);
    end
    
    % Create adaptive weights centered on median height
    adaptiveWeights = exp(-(relativeHeightPos - 0.5).^2 / 0.15);
    
    % Calculate region retention importance based on tree structure
    regionRetentionImportance = 0.5 + 0.5 * (1 - exp(-treeStructureScore));
    
    % Combine adaptive weights with region retention
    compositeWeights = adaptiveWeights .* (regionRatios.^regionRetentionImportance);
    
    % Apply weights to core metrics
    correctedNaturalBreakScores = naturalBreakScores .* compositeWeights;
    correctedBalanceScores = balanceScores .* compositeWeights;
    correctedDiversityScores = diversityScores .* compositeWeights;
    
    % Define weights for core components
    naturalBreakWeight = 2.0;    % Primary weight for structural breaks
    balanceWeight = 1.5;         % Weight for cluster balance
    diversityWeight = 1.5;       % Weight for cluster diversity
    
    % Calculate final composite score using only core metrics
    compositeScores = (naturalBreakWeight * correctedNaturalBreakScores) + ...
                     (balanceWeight * correctedBalanceScores) + ...
                     (diversityWeight * correctedDiversityScores);
    
    % Find threshold with highest score
    [~, maxScoreIdx] = max(compositeScores);
    optimalThreshold = thresholdValues(maxScoreIdx);
    
    % Update core metrics for each threshold
    for i = 1:length(validMetrics)
        validMetrics(i).compositeScore = compositeScores(i);
        validMetrics(i).regionRatio = regionRatios(i);
        validMetrics(i).adaptiveWeight = adaptiveWeights(i);
        validMetrics(i).compositeWeight = compositeWeights(i);
        validMetrics(i).coreMetrics.naturalBreakScore = correctedNaturalBreakScores(i);
        validMetrics(i).coreMetrics.balanceScore = correctedBalanceScores(i);
        validMetrics(i).coreMetrics.diversityScore = correctedDiversityScores(i);
        validMetrics(i).naturalBreakPoints = naturalBreakPoints;
    end
end

function balanceScores = calculateTreeBalanceScores(Z)
    % Calculate a score for each level of the tree based on the balance of merges
    % More balanced merges (similar sized clusters joining) indicate better partitioning
    
    n = size(Z, 1) + 1;  % Number of original data points
    balanceScores = zeros(size(Z, 1), 1);
    
    % Track cluster sizes at each merge
    clusterSizes = ones(2*n-1, 1);  % Initialize all clusters with size 1
    
    for i = 1:size(Z, 1)
        % Get clusters being merged
        c1 = round(Z(i, 1)) + 1;  % +1 for MATLAB indexing
        c2 = round(Z(i, 2)) + 1;
        
        % Get size of each cluster
        s1 = clusterSizes(c1);
        s2 = clusterSizes(c2);
        
        % Calculate balance ratio (0 to 1, where 1 is perfectly balanced)
        % For a balanced merge, clusters should be of similar size
        balance = min(s1, s2) / max(s1, s2);
        balanceScores(i) = balance;
        
        % Update size of new cluster
        clusterSizes(n + i) = s1 + s2;
    end
    
    return;
end
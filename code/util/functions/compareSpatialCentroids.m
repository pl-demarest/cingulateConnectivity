function [center1, center2, pValue] = compareSpatialCentroids(pos, effects, condLabels, numPerms, visualize)
% compareSpatialCentroids computes the weighted centers for two conditions 
% and uses permutation testing to determine if their spatial locations differ.
%
%   [center1, center2, pValue] = compareSpatialCentroids(pos, effects, condLabels, numPerms, visualize)
%   computes the weighted centers (centroids) for two conditions and performs
%   a permutation test on the difference in centers.
%
%   Inputs:
%       pos        - Nx1 vector of spatial positions.
%       effects    - Nx1 vector of effect sizes.
%       condLabels - Nx1 vector of condition labels (e.g., 1 and 2).
%       numPerms   - Number of permutations for the test.
%       visualize  - (Optional) Boolean flag to display a histogram plot of
%                    the permuted differences versus the observed difference.
%                    Default is false.
%
%   Outputs:
%       center1    - Weighted center for condition 1.
%       center2    - Weighted center for condition 2.
%       pValue     - Permutation-based p-value for the difference in centers.
%
%   Example:
%       pos = linspace(0, 100, 50)';
%       effects = rand(50,1) + 0.5;
%       condLabels = randi([1,2], 50, 1);
%       [c1, c2, p] = compareSpatialCentroids(pos, effects, condLabels, 1000, true);

    % Set default for visualize flag if not provided
    if nargin < 5
        visualize = false;
    end

    % Ensure inputs are column vectors
    pos = pos(:);
    effects = effects(:);
    condLabels = condLabels(:);

    % Identify indices for each condition
    idx1 = condLabels == 1;
    idx2 = condLabels == 2;
    
    % Calculate weighted centers (centroids) for each condition
    center1 = sum(pos(idx1) .* effects(idx1)) / sum(effects(idx1));
    center2 = sum(pos(idx2) .* effects(idx2)) / sum(effects(idx2));
    
    % Compute the observed difference in centers
    diffObs = center1 - center2;
    
    % Initialize permutation differences array
    diffPerm = zeros(numPerms, 1);
    for k = 1:numPerms
        % Randomly shuffle condition labels
        permLabels = condLabels(randperm(length(condLabels)));
        idx1_perm = permLabels == 1;
        idx2_perm = permLabels == 2;
        
        % In case one condition ends up with no data points, set difference to 0.
        if sum(idx1_perm) == 0 || sum(idx2_perm) == 0
            diffPerm(k) = 0;
        else
            center1_perm = sum(pos(idx1_perm) .* effects(idx1_perm)) / sum(effects(idx1_perm));
            center2_perm = sum(pos(idx2_perm) .* effects(idx2_perm)) / sum(effects(idx2_perm));
            diffPerm(k) = center1_perm - center2_perm;
        end
    end
    
    % Calculate two-tailed p-value
    pValue = (sum(abs(diffPerm) >= abs(diffObs)) + 1) / (numPerms + 1);
    
    % Output results to command window
    fprintf('Condition 1 Center: %.3f\n', center1);
    fprintf('Condition 2 Center: %.3f\n', center2);
    fprintf('Observed Difference: %.3f\n', diffObs);
    fprintf('Permutation p-value: %.3f\n', pValue);
    
    % Visualization: Histogram of permuted differences with observed difference marked
    if visualize
        figure;
        histogram(diffPerm, 'Normalization', 'pdf');
        hold on;
        % Mark the observed difference with a red vertical line
        xline(diffObs, 'r', 'LineWidth', 2, 'Label', 'Observed Diff', 'LabelOrientation', 'horizontal');
        title(sprintf('Permutation Distribution of Center Differences (p = %.3f)', pValue));
        xlabel('Difference in Centers');
        ylabel('Probability Density');
        hold off;
    end
end

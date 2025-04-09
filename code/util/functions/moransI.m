function [I, pValue] = moransI(y, W, numPerms, visualize)
% moransI calculates Moran's I statistic and a permutation-based p-value.
%
%   [I, pValue] = moransI(y, W, numPerms, visualize) computes the observed
%   Moran's I for the vector y and spatial weight matrix W, estimates the
%   p-value using numPerms random permutations of y, and, if visualize is true,
%   plots both:
%     (1) A histogram of the permutation distribution with the observed I marked,
%     (2) A Moran scatter plot of standardized effect sizes versus their spatial lag.
%
%   Inputs:
%       y         - Nx1 vector of effect sizes (or poly-fitted values)
%       W         - NxN spatial weight matrix (with zeros on the diagonal)
%       numPerms  - Number of permutations for p-value estimation
%       visualize - (Optional) Boolean flag to display plots. Default is false.
%
%   Outputs:
%       I         - Observed Moran's I statistic
%       pValue    - Two-tailed p-value from the permutation test
%
%   The Moran scatter plot shows the relationship between the standardized effect 
%   sizes (z) and their spatial lag (weighted average of neighbors). The slope of 
%   the fitted regression line approximates Moran's I when W is row-standardized.
%
%   Example:
%       numPerms = 1000;
%       visualize = true;
%       [I, pValue] = moransI(y, W, numPerms, visualize);

    % Set default for visualize flag if not provided
    if nargin < 4
        visualize = false;
    end

    % Ensure y is a column vector
    y = y(:);
    N = length(y);
    
    % Compute mean and deviations from the mean
    y_bar = mean(y);
    y_diff = y - y_bar;
    
    % Total sum of weights
    S0 = sum(W(:));
    
    % Compute numerator and denominator for Moran's I
    numerator = sum(sum(W .* (y_diff * y_diff')));
    denominator = sum(y_diff .^ 2);
    
    % Calculate observed Moran's I
    I = (N / S0) * (numerator / denominator);
    
    % Initialize vector to store permuted I values
    I_perm = zeros(numPerms, 1);
    
    % Permutation test: shuffle y and compute Moran's I for each permutation
    for k = 1:numPerms
        y_perm = y(randperm(N));
        y_perm_diff = y_perm - mean(y_perm);
        numerator_perm = sum(sum(W .* (y_perm_diff * y_perm_diff')));
        denominator_perm = sum(y_perm_diff .^ 2);
        I_perm(k) = (N / S0) * (numerator_perm / denominator_perm);
    end
    
    % Compute two-tailed p-value:
    pValue = (sum(abs(I_perm - mean(I_perm)) >= abs(I - mean(I_perm))) + 1) / (numPerms + 1);
    
    % Visualization section
    if visualize
        % 1. Permutation Histogram
        figure;
        histogram(I_perm, 'Normalization', 'pdf');
        hold on;
        xline(I, 'r', 'LineWidth', 2);
        hold off;
        title(sprintf('Permutation Distribution of Moran''s I (p = %.3f)', pValue));
        xlabel('Moran''s I');
        ylabel('Probability Density');
        
    end
end

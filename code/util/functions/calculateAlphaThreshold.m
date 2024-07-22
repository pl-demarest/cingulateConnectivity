function alphaThreshold = calculateAlphaThreshold(pValues, desiredFDR)
    % This function calculates the alpha threshold for a given FDR using the Benjamini-Hochberg procedure
    % Inputs:
    %   pValues: A vector of p-values from multiple hypothesis tests
    %   desiredFDR: The desired false discovery rate level (e.g., 0.05)
    %
    % Output:
    %   alphaThreshold: The calculated alpha threshold at which p-values should be considered significant

    % Calculate adjusted p-values using the Benjamini-Hochberg procedure
    adjustedPValues = mafdr(pValues, 'BHFDR', true);

    % Sort adjusted p-values
    [sortedPValues] = sort(adjustedPValues);

    % Find the highest adjusted p-value that is less than or equal to the desired FDR
    alphaThreshold = max(sortedPValues(sortedPValues <= desiredFDR));

    % Handle the case where no p-values are below the desired FDR
    if isempty(alphaThreshold)
        alphaThreshold = 0;
        fprintf('No p-values are significant at the %0.2f FDR level.\n', desiredFDR);
    else
        fprintf('The alpha threshold for a FDR of %0.2f is %0.4f.\n', desiredFDR, alphaThreshold);
    end
end

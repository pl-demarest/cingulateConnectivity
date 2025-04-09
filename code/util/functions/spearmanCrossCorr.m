function [correlations, lag, maxCorr, maxLag, maxAbsCorr, maxAbsLag] = spearmanCrossCorr(x, y, lagTime)
    % Precompute lengths and shifts
    dataLength = length(x);
    backwardShift = dataLength-1:-lagTime:0;
    forwardShift = 1:lagTime:dataLength;
    
    % Combine shifts and preallocate arrays
    shifts = [-backwardShift, forwardShift];
    correlations = zeros(size(shifts));
    lag = zeros(size(shifts));
    
    % Calculate correlations for each shift
    parfor idx = 1:length(shifts)
        shift = shifts(idx);
        % circshift works for both positive and negative shifts
        newX = circshift(x, shift);
        % Compute Spearman correlation without squaring
        correlations(idx) = corr(newX, y, 'Type', 'Spearman');
        lag(idx) = shift;
    end
    
    % Limit analysis to half the data length in both directions
    lagWindowIDX = (lag >= -dataLength/2) & (lag <= dataLength/2);
    
    % Find max (signed) correlation and its lag
    [maxCorr, idxMax] = max(correlations(lagWindowIDX));
    lagWindow = lag(lagWindowIDX);
    maxLag = lagWindow(idxMax);
    
    % Find max absolute correlation and its lag
    absCorrelations = abs(correlations);
    [maxAbsCorr, idxMaxAbs] = max(absCorrelations(lagWindowIDX));
    maxAbsLag = lagWindow(idxMaxAbs);
end

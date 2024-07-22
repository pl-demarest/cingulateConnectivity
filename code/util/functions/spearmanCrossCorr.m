function [correlations, lag, maxCorr, maxLag] = spearmanCrossCorr(x, y, lagTime)
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
        if shift < 0
            % Negative shift: circular shift backward
            newX = circshift(x, shift);
        elseif shift > 0
            % Positive shift: circular shift forward
            newX = circshift(x, shift);
        else
            % No shift
            newX = x;
        end
        correlations(idx) = (corr(newX, y, 'Type', 'Spearman'))^2;
        lag(idx) = shift;
    end
    
    % Limit analysis to half the data length in both directions
    lagWindowIDX = (lag >= -dataLength/2) & (lag <= dataLength/2);
    maxCorr = max(correlations(lagWindowIDX));
    maxLagIDX = (correlations == maxCorr) & lagWindowIDX;
    maxLagAll = lag(maxLagIDX);
    maxLag = maxLagAll(1);
end

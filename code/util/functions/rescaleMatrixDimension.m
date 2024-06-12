function rescaledMatrix = rescaleMatrixDimension(matrix, interval, dim)

% Validate input
    if dim ~= 1 && dim ~= 2
        error('Dimension must be either 1 (rows) or 2 (columns).');
    end
    
    % Get the size of the matrix
    [numRows, numCols] = size(matrix);
    
    % Initialize the output matrix
    rescaledMatrix = zeros(size(matrix));
    
    % Rescale rows or columns
    if dim == 1
        % Rescale each row
        for i = 1:numRows
            row = matrix(i, :);
            minVal = min(row);
            maxVal = max(row);
            rescaledMatrix(i, :) = rescale(row,interval(1),interval(2));
        end
    else
        % Rescale each column
        for j = 1:numCols
            col = matrix(:, j);
            minVal = min(col);
            maxVal = max(col);
            rescaledMatrix(:, j) = rescale(col,interval(1),interval(2));
        end
    end
end
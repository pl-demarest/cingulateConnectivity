function W = createWeightMatrix(pos)
    % pos: a vector containing the spatial positions of your data points.
    % W: the resulting weight matrix based on inverse distance weighting.
    
    epsilon = 1e-5;  % small constant to avoid division by zero
    N = numel(pos);
    W = zeros(N);
    
    for i = 1:N
        for j = 1:N
            if i ~= j
                d = abs(pos(i) - pos(j));
                W(i, j) = 1 / (d + epsilon);  % inverse distance weight
            end
        end
    end
end

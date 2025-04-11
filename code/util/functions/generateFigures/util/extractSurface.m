function [newVert, newTri] = extractSurface(idx, points, triangle)
% Assume points is an Nx3 matrix of XYZ coordinates
% Assume triangle is an Mx3 matrix of connectivity (indices into points)
% Assume idx_array is a Kx1 vector of indices into points that you want to extract

% Extract the points
newVert = points(idx, :);

% Create a map of old indices to new indices
old_to_new_indices = zeros(size(points, 1), 1);
old_to_new_indices(idx) = 1:length(idx);

% Update the connectivity matrix
new_triangle = old_to_new_indices(triangle);

% Remove any triangle that contains zero (these would have referenced points not included in idx_array)
newTri = new_triangle(all(new_triangle, 2), :);

% Check and display the results
end
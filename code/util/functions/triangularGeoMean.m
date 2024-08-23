function [mappedColor, mappedCoord] = triangularGeoMean(values,figureFlag)
%takes in a vector of 3 values, normalizes them, and gcalculates a
%geometric mean between the 3 values, then mapps the geommetric mean to an
%RGB value to visualize relative geometric weights of the 3 values


% Define vertices of the triangle
vertices = [0 0; 1 0; 0.5 1];
faces = [1 2 3];

% Define colors at the vertices
%vertexColors = [getColors('lush lilac'); getColors('modern orange'); getColors('lago blue')]; % RGB colors at vertices
%vertexColors = [1,0,0;0,1,0;0,0,1];
vertexColors = [222,45,38;49,163,84;49,90,230]./255;


% Compute the geometric mean
geoMean = nthroot(prod(values), 3);

% Normalize the values to sum to 1 for barycentric coordinates
normalizedValues = values / sum(values);

% Compute the barycentric coordinates (as an example, use the normalized values directly)
barycentricCoords = normalizedValues;

% Map barycentric coordinates to Cartesian coordinates of the triangle
mappedCoord = barycentricCoords(1) * vertices(1, :) + ...
              barycentricCoords(2) * vertices(2, :) + ...
              barycentricCoords(3) * vertices(3, :);


% Create a figure
if strcmp(figureFlag,'on')
    figure();
hold on;

% Plot the triangle with interpolated colors
h = patch('Faces', faces, 'Vertices', vertices, 'FaceVertexCData', vertexColors, ...
          'FaceColor', 'interp', 'EdgeColor', 'none');
axis equal;
% Add a colorbar for reference
hold off;
% Plot the mapped point on the triangle
hold on;
plot(mappedCoord(1), mappedCoord(2), 'ko', 'MarkerFaceColor', 'k');
hold off;
end

% Query the interpolated color at the mapped coordinate
F = scatteredInterpolant(vertices(:, 1), vertices(:, 2), vertexColors(:, 1), 'linear', 'none');
R = F(mappedCoord(1), mappedCoord(2));
F.Values = vertexColors(:, 2);
G = F(mappedCoord(1), mappedCoord(2));
F.Values = vertexColors(:, 3);
B = F(mappedCoord(1), mappedCoord(2));
mappedColor = [R, G, B];

%account for colors that may miss

if any(isnan(mappedColor))
F = scatteredInterpolant(vertices(:, 1), vertices(:, 2), vertexColors(:, 1), 'linear', 'nearest');
R = F(mappedCoord(1), mappedCoord(2));
F.Values = vertexColors(:, 2);
G = F(mappedCoord(1), mappedCoord(2));
F.Values = vertexColors(:, 3);
B = F(mappedCoord(1), mappedCoord(2));
mappedColor = [R, G, B];
end

% Ensure color values are within [0, 1] range
mappedColor(mappedColor < 0) = 0;
mappedColor(mappedColor > 1) = 1;

% Display the geometric mean and its associated color
fprintf('Geometric Mean: %.2f\n', geoMean);
fprintf('Mapped Color: [%.2f, %.2f, %.2f]\n', mappedColor(1), mappedColor(2), mappedColor(3));

end


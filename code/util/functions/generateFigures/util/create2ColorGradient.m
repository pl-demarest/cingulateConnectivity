function cmap = create2ColorGradient(rgbColor1, rgbColor2, steps)

% generate a color gradient between any two colors
    % Validate the input
    if length(rgbColor1) ~= 3 || length(rgbColor2) ~= 3
        error('Both RGB colors must be 1x3 vectors.');
    end
    if any(rgbColor1 > 1 | rgbColor1 < 0) || any(rgbColor2 > 1 | rgbColor2 < 0)
        error('RGB values must be in the range [0, 1].');
    end
    if steps <= 0 || floor(steps) ~= steps
        error('Number of steps must be a positive integer.');
    end

    % Initialize colormap
    cmap = zeros(steps, 3);

    % Calculate step size for each color channel
    for i = 1:3
        stepSize = (rgbColor2(i) - rgbColor1(i)) / (steps - 1);
        cmap(:, i) = linspace(rgbColor1(i), rgbColor2(i), steps);
    end
end

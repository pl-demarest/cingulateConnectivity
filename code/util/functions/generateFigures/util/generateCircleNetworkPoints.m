function [outterCircumference, innerCircumference] = generateCircleNetworkPoints(outer_radius,inner_radius,num_outer_points,num_inner_points)

% Define the center and radius of the circles
outer_center_x = 0;
outer_center_y = 0;

% Generate outer circle points without duplicating the last point
theta_outer = linspace(pi/2,pi/2-2*pi, num_outer_points + 1);
outer_circumference_x = outer_center_x + outer_radius * cos(theta_outer(1:end-1));
outer_circumference_y = outer_center_y + outer_radius * sin(theta_outer(1:end-1));

outterCircumference = [outer_circumference_x; outer_circumference_y];

% Adjust inner circle points to be on the left and right
% Right side points (0 to π)
theta_inner_right = linspace(0, pi, floor(num_inner_points/2) + 1);
% Left side points (π to 2π)
theta_inner_left = linspace(pi, 2*pi, floor(num_inner_points/2) + 1);

% Combine and sort to ensure the distribution on both sides
theta_inner_combined = [theta_inner_right(1:end-1), theta_inner_left(1:end-1)];
[theta_inner_sorted, sort_index] = sort(theta_inner_combined);

inner_circumference_x = outer_center_x + inner_radius * cos(theta_inner_sorted);
inner_circumference_y = outer_center_y + inner_radius * sin(theta_inner_sorted);

innerCircumference = [inner_circumference_x; inner_circumference_y];

theta = 120; % to rotate index of the small circle 120 counterclockwise
R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
innerCircumference = R*innerCircumference;

end




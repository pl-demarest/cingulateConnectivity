function [outerTable,innerTable] = generateCircleNetworkPoints(outer_radius,inner_radius, innerConvergenceRadius, outerConvergenceRadius, outerTable, innerTable)

%take the imported tables, and output adjusted tables that includes
%xposition, y position, region name, region class, region integrer labels,
%region hemisphere, class integer labels, and for each class integer label,
%an entry describing the x/y coordinate of the class's corresponding
%intermediate circle

%% Generate a table containing left and right hemesphere regions.

%duplicate and reverse order of table
tempOuter = outerTable;
tempOuter = tempOuter(end:-1:1,:);
tempInner = innerTable;
tempInner = tempInner(end:-1:1,:);

%Assign right hemesphere labels to input tables (regions assigned
%clockwise)
outerTable.rHemisphere = ones(size(outerTable,1),1);
innerTable.rHemisphere = zeros(size(innerTable,1),1);
tempOuter.rHemisphere = zeros(size(outerTable,1),1);
tempInner.rHemisphere = ones(size(innerTable,1),1);

%combine tables
outerTable = [outerTable;tempOuter];
innerTable = [innerTable;tempInner];

%% next, using the length of the table, generate a coordinate for each table entry
num_outer_points = size(outerTable,1);
num_inner_points = length(unique(innerTable.Class))*2;

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
[theta_inner_sorted] = sort(theta_inner_combined);

inner_circumference_x = outer_center_x + inner_radius * cos(theta_inner_sorted);
inner_circumference_y = outer_center_y + inner_radius * sin(theta_inner_sorted);


innerCircumference = [inner_circumference_x; inner_circumference_y];

theta = 120; % to rotate index of the small circle 120 counterclockwise
R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
innerCircumference = R*innerCircumference;

%add coordinates to tables
outerTable.xCoord = outer_circumference_x';
outerTable.yCoord = outer_circumference_y';

%assign coordinates appropriately based on the unique class labels and
%hemisphere

classes = unique(innerTable.Class);
count = 1;
for h = [0,1]
    if h == 1
        classes = flip(classes);

    end
for i = 1:length(classes)

curX = innerCircumference(1,count);
curY = innerCircumference(2,count);
curClass =classes(i);

%
curIDX = ismember(innerTable.Class,curClass) & (innerTable.rHemisphere == h);
    
innerTable.xCoord(curIDX) = curX;
innerTable.yCoord(curIDX) = curY;
count = count+1;
end
end


%% Generate intermediate circumferences for convergent wiring

uniqueClasses = unique(outerTable.Class);

%switch between right and left hemisphere

for i = 1:length(uniqueClasses)

    currentClass = uniqueClasses{i};

    for currHem = 0:1
    classIndexR = contains(outerTable.Class,currentClass) & (outerTable.rHemisphere == currHem);
    %classIndexL = contains(outerTable.Class,currentClass) & (outerTable.rHemisphere == 0);

    arcXR = outerTable.xCoord(classIndexR);
    arcYR = outerTable.yCoord(classIndexR);
    
    thetaStart = atan2(arcYR(1), arcXR(1));
    thetaEnd   = atan2(arcYR(end), arcXR(end));

    if thetaEnd - thetaStart > pi
        thetaEnd = thetaEnd - 2*pi;
    end

    thetaMidpoint = (thetaEnd + thetaStart) / 2;

    XMidpoint = outer_radius * cos(thetaMidpoint);
    YMidpoint = outer_radius * sin(thetaMidpoint);

    X_r1 = innerConvergenceRadius * cos(thetaMidpoint);
    Y_r1 = innerConvergenceRadius * sin(thetaMidpoint);

    X_r2 = outerConvergenceRadius * cos(thetaMidpoint);
    Y_r2 = outerConvergenceRadius * sin(thetaMidpoint);

    outerTable.innerCovergeXCoord(classIndexR) = X_r1;
    outerTable.innerCovergeYCoord(classIndexR) = Y_r1;

    outerTable.outterCovergeXCoord(classIndexR) = X_r2;
    outerTable.outterCovergeYCoord(classIndexR) = Y_r2;

    end

end

%% generate conditional wiring paths for when a circle in one hemesphere has to pass to the other hemesphere, the radius has to be less
xPoints = innerTable.xCoord;
yPoints = innerTable.yCoord;

% Parameters
reduction_factor = 0.9;    % 10% radius reduction
angle_offset = 2 * pi / 180;  % Small angle offset for left/right points

% Original circle points from your variables
xPoints = innerTable.xCoord;  % X-coordinates from your table
yPoints = innerTable.yCoord;  % Y-coordinates from your table

n_points = numel(xPoints);  % Number of points on the inner circle
xPoints = [xPoints; xPoints(1)];  % Close the circle
yPoints = [yPoints; yPoints(1)];  % Close the circle

% Compute midpoints
mid_x = (xPoints(1:end-1) + xPoints(2:end)) / 2;
mid_y = (yPoints(1:end-1) + yPoints(2:end)) / 2;

% Compute the radius and center of the original circle
center_x = mean(xPoints(1:end-1));
center_y = mean(yPoints(1:end-1));
angles = atan2(mid_y - center_y, mid_x - center_x);

radius = mean(sqrt((xPoints(1:end-1) - center_x).^2 + (yPoints(1:end-1) - center_y).^2));

% Adjust the midpoints to the reduced circle
mid_x = center_x + reduction_factor * radius * cos(angles);
mid_y = center_y + reduction_factor * radius * sin(angles);

% Calculate left and right points for each midpoint
left_angles = angles + angle_offset;   % Left point angle
right_angles = angles - angle_offset;  % Right point angle

% Left and right points
left_x = center_x + reduction_factor * radius * cos(left_angles);
left_y = center_y + reduction_factor * radius * sin(left_angles);
right_x = center_x + reduction_factor * radius * cos(right_angles);
right_y = center_y + reduction_factor * radius * sin(right_angles);

%TODO- make a pathing script to avoid overlapping in the inner circle


end




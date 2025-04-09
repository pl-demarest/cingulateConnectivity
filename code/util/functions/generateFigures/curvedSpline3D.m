function [curveX, curveY, curveZ] = curvedSpline3D(P0, P2, curveDim, curveDir, curvatureMagnitude, nPoints, jitterAmplitude)
% curvedSpline3D Generates a quadratic Bézier curve between two 3D points
%
%   [curveX, curveY, curveZ] = curvedSpline3D(P0, P2, curveDim, curveDir, curvatureMagnitude, nPoints)
%
%   Inputs:
%       P0 - 1x3 vector representing the starting point [x0, y0, z0].
%       P2 - 1x3 vector representing the ending point [x2, y2, z2].
%       curveDim - Scalar (1, 2, or 3) indicating which coordinate to offset.
%       curveDir - Scalar (1 or -1) specifying the positive or negative direction.
%       curvatureMagnitude - Scalar that sets the distance of the offset.
%       nPoints - (Optional) Number of points to compute along the curve (default is 100).
%
%   Outputs:
%       curveX, curveY, curveZ - Vectors of x, y, and z coordinates along the curve.
%
%   Example:
%       % Create a curve that bends in the positive z-direction:
%       [X, Y, Z] = curvedSpline3D([0 0 0], [10 10 10], 3, 1, 5);
%       plot3(X, Y, Z, 'b-', 'LineWidth',2); grid on;
%
%       % Create a curve that bends in the negative x-direction:
%       [X, Y, Z] = curvedSpline3D([0 0 0], [10 10 10], 1, -1, 3);
%       plot3(X, Y, Z, 'r-', 'LineWidth',2); grid on;
%
%   Note:
%       The parameter t is generated from 0 to 1, which is standard for Bézier curves.
%
if nargin < 6
    nPoints = 100;
end

% Calculate the midpoint between the two endpoints.
midPoint = (P0 + P2) / 2;

% Create an offset vector that only has a nonzero entry in the chosen dimension.
offsetVector = zeros(1, 3);
offsetVector(curveDim) = curveDir * curvatureMagnitude;

% Calculate the control point (P1) by offsetting the midpoint.
P1 = midPoint + offsetVector;

% Generate a parameter t that goes from 0 to 1.
t = linspace(0, 1, nPoints);

% Apply jitter to the control point P1
P1_jittered = P1 + (rand(1,3)-0.5)*jitterAmplitude;

% Compute the quadratic Bézier curve with jittered control point:
% B(t) = (1-t)^2 * P0 + 2*(1-t)*t * P1_jittered + t^2 * P2
curveX = (1-t).^2 * P0(1) + 2*(1-t).*t * P1_jittered(1) + t.^2 * P2(1);
curveY = (1-t).^2 * P0(2) + 2*(1-t).*t * P1_jittered(2) + t.^2 * P2(2);
curveZ = (1-t).^2 * P0(3) + 2*(1-t).*t * P1_jittered(3) + t.^2 * P2(3);

end

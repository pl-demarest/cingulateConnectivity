function [out] = normalizeAngle(angleIn)
%angle in = samples x trial

%use this to get the normalized angle by mazimizing similar angles thorugh
%time and minimizing different angles through time across trials

meanAngle = nanmean(angle(angleIn),2);

diff = angle(angleIn) - meanAngle;

out = cos(diff).*meanAngle;

end
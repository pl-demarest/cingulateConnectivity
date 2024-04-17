function [phaseData] = getPhase(data, samplingRate)
%, phasePeak, phaseWidth, phaseProminence
Type      = 'low';
[b0_LP,a0_LP] = butter(4,2*20/samplingRate, Type);

for t = 1:size(data,2)
    lpdata(:,t) = hilbert(filtfilt(b0_LP,a0_LP,double(data(:,t))));
end

for t = 1:size(data,2)

    phaseData(:,t) = angle(lpdata(:,t));


end


end

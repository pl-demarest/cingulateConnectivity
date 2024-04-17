function timeVector = getTimeVector(sampleLength,samplingRate)
%returns a vector centered on a stimulation input, where the stimulation in
%milliseconds

length_samples = sampleLength;
% Sampling rate
fs = samplingRate; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

end
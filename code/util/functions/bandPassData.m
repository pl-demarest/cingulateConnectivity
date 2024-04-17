function [bandPassedData] = bandPassData(signal,lowerFreq,upperFreq,order,samplingRate)

HP_cutoff = lowerFreq;
LP_cutoff = upperFreq;
Type      = 'bandpass';
[b0_A,a0_A] = butter(order,2*[HP_cutoff LP_cutoff]/samplingRate, Type);

%fvtool(b0_A, a0_A)

for channel = 1:size(signal,2)
    bandPassedData(:,channel) = filtfilt(b0_A,a0_A,signal(:,channel));
end

end
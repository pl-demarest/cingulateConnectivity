function [bandPassedData] = bandPassData(signal,lowerFreq,upperFreq,order,samplingRate)

%set input to be chan x signal
if size(signal,1) > size(signal,2)
    signal = signal';
end

HP_cutoff = lowerFreq;
LP_cutoff = upperFreq;
Type      = 'bandpass';
[b0_A,a0_A] = butter(order,2*[HP_cutoff LP_cutoff]/samplingRate, Type);
[sos,g] = tf2sos(b0_A,a0_A);


%fvtool(b0_A, a0_A)

for channel = 1:size(signal,1)
    bandPassedData(channel,:) = filtfilt(sos,g,signal(channel,:));

end

checkNan = sum(isnan(bandPassedData));

if checkNan > 0
    fprintf('filter unstable, nans detected when bandpass filtering, lowering order')
    while checkNan > 0

HP_cutoff = lowerFreq;
LP_cutoff = upperFreq;
Type      = 'bandpass';
order = order-1;

if order == 0

    break
end

[b0_A,a0_A] = butter(order,2*[HP_cutoff LP_cutoff]/samplingRate, Type);
[sos,g] = tf2sos(b0_A,a0_A);


%fvtool(b0_A, a0_A)

    for channel = 1:size(signal,1)
    bandPassedData(channel,:) = filtfilt(sos,g,signal(channel,:));

    end

    checkNan = sum(isnan(bandPassedData));

    end


end

end
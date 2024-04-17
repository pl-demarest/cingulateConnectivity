function lowPassedData = getLowPassData(signal,lowPassThreshold,order,SamplingRate)

Type      = 'low';
[b0_LP,a0_LP] = butter(order,2*lowPassThreshold/SamplingRate, Type);

for channel = 1:size(signal,2)
    lowPassedData(:,channel) = filtfilt(b0_LP,a0_LP,double(signal(:,channel)));
end

end

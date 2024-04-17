function cleanDataOut = getCleanData(signal,samplingRate,stimulationIndex,stimulationWindow)

hp_cutoff = 0.5;
order = 5;
type = 'high';
[b0_hp, a0_hp] = butter(order, 2*hp_cutoff/samplingRate, type);

if stimulationWindow > 0
removeArtifactSignal = removeArtifact(signal,stimulationIndex,stimulationWindow);
hp_signal = filtfilt(b0_hp,a0_hp,double(removeArtifactSignal))';
cleanDataOut = multi_iirnotch_filtering(hp_signal,samplingRate,60)'; %sitmulation window is in samples
else
hp_signal = filtfilt(b0_hp,a0_hp,double(signal))';
cleanDataOut = multi_iirnotch_filtering(hp_signal,samplingRate,60)'; 
end
end
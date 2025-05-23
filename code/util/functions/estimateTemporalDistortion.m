function [smearingSamples, smearingTime] = estimateTemporalDistortion(samplingRate,HP_cutoff,LP_cutoff,order)

Type      = 'bandpass';
[b0_A,a0_A] = butter(order,2*[HP_cutoff LP_cutoff]/samplingRate, Type);
[sos,g] = tf2sos(b0_A,a0_A);

impulse = [1, zeros(1, 5000)]; % an impulse followed by zeros
response = filtfilt(sos, g, impulse);

% Normalize and find where the response is effectively non-zero
threshold = 0.01 * max(abs(response));
nonzeroIdx = find(abs(response) > threshold);
smearingSamples = nonzeroIdx(end) - nonzeroIdx(1) + 1;
smearingTime = 1000*(smearingSamples / samplingRate); % in ms

end


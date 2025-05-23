function [tf, times, freqs] = computeTimeFreq(data, fs, freqs, nCycles)
% computeTimeFreq  Compute time–frequency power via Morlet wavelets
%
%   [tf, times, freqs] = computeTimeFreq(data, fs, freqs, nCycles)
%
%   Inputs:
%     data    – [nTrials × nSamples] matrix of time series
%     fs      – sampling rate (e.g. 2000)
%     freqs   – vector of frequencies to analyze (e.g. 2:2:200)
%     nCycles – (optional) number of wavelet cycles (default = 6)
%
%   Outputs:
%     tf      – [nTrials × nFreqs × nSamples] complex TFR
%     times   – [1 × nSamples] time axis in seconds
%     freqs   – same as input freqs
%
%   Usage example:
%     fs      = 2000;
%     freqs   = 2:2:200;                % 2,4,6,…,200 Hz
%     [tf, t, f] = computeTimeFreq(myData, fs, freqs);
%     power    = abs(tf).^2;            % power
%     avgPower = squeeze(mean(power,1));% average across trials
%
%   See also: spectrogram, cwt

    if nargin<4, nCycles = 6; end

    [nTrials, nSamples] = size(data);
    nFreqs = numel(freqs);
    tf     = zeros(nTrials, nFreqs, nSamples);
    
    % time axis
    times = (0:nSamples-1) ./ fs;

    % Loop over frequencies
    for fi = 1:nFreqs
        f = freqs(fi);

        %--- build Morlet wavelet for this freq -----------------------
        sigma_t = nCycles / (2*pi*f);
        t_wav   = -3*sigma_t : 1/fs : 3*sigma_t;
        A       = 1/sqrt(sigma_t*sqrt(pi));   % normalization
        wavelet = A .* exp(2*1i*pi*f.*t_wav) .* exp(-t_wav.^2/(2*sigma_t^2));
        L = numel(wavelet);

        % pad length for convolution
        nConv = nSamples + L - 1;
        Wf    = fft(wavelet, nConv);

        %--- convolve each trial with this wavelet --------------------
        for tr = 1:nTrials
            Xf = fft(data(tr,:), nConv);
            convRes = ifft(Xf .* Wf);
            % trim out the extra padding:
            idx0    = floor(L/2)+1;
            tf(tr,fi,:) = convRes(idx0 : idx0+nSamples-1);
        end
    end
end

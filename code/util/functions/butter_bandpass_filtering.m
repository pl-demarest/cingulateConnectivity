function [ y ] = butter_bandpass_filtering( X, Fs, fBand, n)
%  X: time x channal
%  Fs: sampling rate
%  fBand: frequency band
%  n: order of butter worth filtering

Wn = fBand;
Fn = Fs/2;
ftype = 'bandpass';
[b, a] = butter(n,Wn/Fn,ftype);
y = filtfilt(b,a,X);

% fvtool(b,a,'Fs',Fs);
end


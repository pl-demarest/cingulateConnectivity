function [ y ] = butter_highpass_filtering(X, Fs, freq, n)
%BUTTER_BANDPASS_FILTERING 이 함수의 요약 설명 위치
%   자세한 설명 위치
%  X: time x channal
%  Fs: sampling rate
%  fBand: frequency band
%  n: order of butter worth filtering
n_time = size(X,1);
n_ch = size(X,2);

if n_time < n_ch
    error('n_time < n_ch');
end
    
    
Wn = freq;
Fn = Fs/2;
ftype = 'high';
[b, a] = butter(n,Wn/Fn,ftype);
% [zhi,phi,khi] = butter(n,Wn/Fn,ftype);
% [soshi, g] = zp2sos(zhi,phi,khi);
y = filtfilt(b,a,X);
% y = filtfilt(soshi,g,X);


% fvtool(b,a,'Fs',Fs);
end

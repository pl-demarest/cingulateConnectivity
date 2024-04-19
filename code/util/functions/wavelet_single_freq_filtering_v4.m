function [ filtered_data filtered_complex ] = wavelet_single_freq_filtering_v4(data, srate, freq, numcycles)
%FFT_BANDPASS_FILTERING 이 함수의 요약 설명 위치
%   자세한 설명 위치

% data : time by channel

%%
center_freq = freq; % in Hz
w_sigma = numcycles/(2*pi*center_freq);
time        = -w_sigma*3:1/srate:3*w_sigma; % time for wavelet

%% typical wavelet
% numcycles = 1;
% wavelet = exp(2*1i*pi*center_freq.*time) .* exp(-time.^2./(2*w_sigma.^2));

%% Cohen's wavelet
fwhm = numcycles * (2*log(2)).^0.5/(pi*center_freq);
wavelet = exp(2*1i*pi*center_freq.*time).*exp(-4*log(2)*time.^2/fwhm.^2);

%%
wavelet = wavelet / sum(abs(wavelet));
warning('off');
half_of_wavelet_size = ((length(time)-1)/2);

% FFT parameters
n_wavelet     = length(time);
n_data        = size(data,1);
n_ch = size(data,2);
n_convolution = n_wavelet+n_data-1;

% FFT of wavelet
fft_wavelet = fft(wavelet,n_convolution);

filtered_data  = zeros(n_data,n_ch);
filtered_complex = zeros(n_data,n_ch);

for chani=1:n_ch
    fft_data = fft(squeeze(data(:,chani))',n_convolution);
    convolution_result_fft = ifft(fft_wavelet.*fft_data,n_convolution) * sqrt(4/(2*pi*center_freq));
    convolution_result_fft = convolution_result_fft(half_of_wavelet_size+1:end-half_of_wavelet_size);    
    filtered_complex(:,chani)  = convolution_result_fft;
    filtered_data(:,chani)  = real(convolution_result_fft);

end



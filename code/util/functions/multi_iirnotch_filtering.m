function [filtered_signal] = multi_iirnotch_filtering(signal,srate,notch_freq)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


% define the line noise frequency and bandwidth
peak.fcenter = 60;
peak.bw      = 0.001;

% calculate the IIR-peak filter coefficients in a,b format 
peak.wo = peak.fcenter/(srate/2);  
peak.bw = peak.bw;
[peak.b,peak.a] = iirpeak(peak.wo,peak.bw);  

% define the harmonics of line noise frequency
param.filter.notch.fcenter = notch_freq;

param.filter.notch.bw      = ones(1,length(param.filter.notch.fcenter)).*0.001;

% calculate the IIR-peak filter coefficients in a,b format 
for idx = 1:length(param.filter.notch.fcenter)
    notch{idx}.wo = param.filter.notch.fcenter(idx)/(srate/2);  
    notch{idx}.bw = param.filter.notch.bw(idx);
    [notch{idx}.b,notch{idx}.a] = iirnotch(notch{idx}.wo,notch{idx}.bw);  
end

fprintf(1, '> Notch filtering signal \n');
fprintf(1,'[');
% for each channel
for idx_channel=1:size(signal,2)
    
    % get the signal for this channel
    signal_preliminary = double(signal(:,idx_channel));
    
    % remove all harmonics of line-noise
    for idx = 1:length(param.filter.notch.fcenter)
        signal_preliminary = filtfilt(notch{idx}.b,notch{idx}.a,signal_preliminary); 
    end 
    
    % return the signal
    filtered_signal(:,idx_channel) = single(signal_preliminary);
    
    fprintf(1,'.');
end
fprintf(1,'] done\n');


end


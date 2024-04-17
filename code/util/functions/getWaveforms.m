function peaks = getPeaks(data,samplingRate)

%using some set of methods, extract the low frequency waveform component
%from CCEPs to make identification of peaks, latency, polarity, response
%duration, and amplitude without high frequency components.
% data is given as a chan x signal x trial structure, each field of the
% struct will contain the same structure

dimensions = size(data);

%Initialize filtered data
lowpass = nans(dimensions);

%create N1 and N2 windows

n1Window = dimensions(2)/2+(samplingRate*(0.01)):dimensions(2)/2+(samplingRate*(0.05));
n2Window = dimensions(2)/2+(samplingRate*(0.05)):dimensions(2)/2+(samplingRate*(0.3));

%get Baseline index 

baselineWindow = 1:.9*samplingRate;

for ch = 1:dimensions(1)

    curDat = squeeze(data(ch,:,:));

    meanTrace = nanmean(curDat,2);
    
    %find peaks

    
    baseDat = meanTrace(baselineWindow);
    baseSTD = std(baseDat)*5;

    %n1 positive peaks
    [n1p, n1pl, n1pw,n1pp] = findpeaks(meanTrace(n1Window),'MinPeakHeight',baseSTD,'Annotate','extents');
    %n1 negative peaks
    [n1n, n1nl, n1nw,n1np] = findpeaks(-meanTrace(n1Window),'MinPeakHeight',baseSTD,'Annotate','extents');

    n1n = -n1n;

    %n2 positive peaks
    [n2p, n2pl, n2pw,n2pp] = findpeaks(meanTrace(n2Window),'MinPeakHeight',baseSTD,'Annotate','extents');

    %n2 negative peaks
    [n2n, n2nl, n2nw,n2np] = findpeaks(-meanTrace(n2Window),'MinPeakHeight',baseSTD,'Annotate','extents');
    n2n = -n2n;

    %determine number of peaks

    numPeaksN1 = length([n1p n1n]);
    numPeaksN2 = length([n2p n2n]);

    %determine most prominent peaks for n1 and n2
    if n1pp >= n1np
    n1PromIDX = find(max(n1pp));

    n2Prom = find(max(n2pp));
    

    %calculate proportion of n1 peaks
    
    baselineDistr = curDat(baselineWindow,:);
    baselineDistr = baselineDistr(:);
    
    for t = 1:dimensions(3)
        peakVal (t) = a;
    end

    %response duration

    %response RMS


end




end
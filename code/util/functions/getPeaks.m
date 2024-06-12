function peaks = getPeaks(data,samplingRate,lowPass)

%using some set of methods, extract the low frequency waveform component
%from CCEPs to make identification of peaks, latency, polarity, response
%duration, and amplitude without high frequency components.
% data is given as a chan x signal x trial structure, each field of the
% struct will contain the same structure

dimensions = size(data);
time = 1:dimensions(2);

%Initialize filtered data

%create N1 and N2 windows

n1Window = dimensions(2)/2+(samplingRate*(0.01)):dimensions(2)/2+(samplingRate*(0.05));
n2Window = dimensions(2)/2+(samplingRate*(0.06)):dimensions(2)/2+(samplingRate*(0.7));

%get Baseline index 

baselineWindow = 1:.9*samplingRate;

for ch = 1:dimensions(1)
    curLP = squeeze(lowPass(ch,:,:));
    curDat = squeeze(data(ch,:,:));

    meanTrace = nanmean(curDat,2);

    baseDat = meanTrace(baselineWindow);
    baseSTD = std(baseDat)*5;
    

    % get response duration and RMS of response
    respnseIDX = find(abs(meanTrace(dimensions(2)/2+(samplingRate*(0.01)):end)) > baseSTD);
    responseRange = min(respnseIDX):max(respnseIDX);
    


    %find peaks
    %n1 positive peaks
    [n1p, n1pl, n1pw,n1pp] = findpeaks(meanTrace(n1Window),'MinPeakHeight',baseSTD,'Annotate','extents');
    %n1 negative peaks
    [n1n, n1nl, n1nw,n1np] = findpeaks(-meanTrace(n1Window),'MinPeakHeight',baseSTD,'Annotate','extents');

    n1n = -n1n;
    n1np = -n1np;
    
    %for n2 peak detection, use a lowpassed signal to better resolve the
    %low frequency component
    

    lowPassedData = mean(curLP,2);
    baseSTDN2 = std(lowPassedData(baselineWindow))*5;
    %n2 positive peaks
    [n2p, n2pl, n2pw,n2pp] = findpeaks(lowPassedData(n2Window),'MinPeakHeight',baseSTDN2,'Annotate','extents');
    %n2 negative peaks
    [n2n, n2nl, n2nw,n2np] = findpeaks(-lowPassedData(n2Window),'MinPeakHeight',baseSTDN2,'Annotate','extents');
    
    
    n2n = -n2n;
    n2np = -n2np;



    %determine number of peaks
    peaks.numPeaksN1(ch) = length(n1p) + length(n1n);
    peaks.numPeaksN2(ch) = length(n2p) + length(n2n);

    %determine widest peaks for n1 and n2 and use these as feature values
    if peaks.numPeaksN1(ch) == 0

    peaks.n1Polarity(ch) = 0;
    peaks.n1Amplitude(ch) = 0;
    peaks.n1Latency(ch) = 0;
    peaks.n1Width(ch) = 0;
    peaks.n1Prominence(ch) = 0;

    elseif (~isempty(n1p) && isempty(n1n)) || any(max(abs(n1pw)) >= max(abs(n1nw)))%check to use vales from either negative or positive peaks
    
    n1PromIDX = find(max(abs(n1pw)));
    peaks.n1Polarity(ch) = 1;
    peaks.n1Amplitude(ch) = n1p(n1PromIDX);
    peaks.n1Latency(ch) = n1pl(n1PromIDX)+(samplingRate*(0.01));
    peaks.n1Width(ch) = n1pw(n1PromIDX);
    peaks.n1Prominence(ch) = n1pp(n1PromIDX);

    elseif (~isempty(n1n) && isempty(n1p)) || any(max(abs(n1pw)) <= max(abs(n1nw)))

    n1PromIDX = find(max(abs(n1nw)));
    peaks.n1Polarity(ch) = -1;
    peaks.n1Amplitude(ch) = n1n(n1PromIDX);
    peaks.n1Latency(ch) = n1nl(n1PromIDX)+(samplingRate*(0.01));
    peaks.n1Width(ch) = n1nw(n1PromIDX);
    peaks.n1Prominence(ch) = n1np(n1PromIDX);

    end


    if peaks.numPeaksN2(ch) == 0

    peaks.n2Polarity(ch) = 0;
    peaks.n2Amplitude(ch) = 0;
    peaks.n2Latency(ch) = 0;
    peaks.n2Width(ch) = 0;
    peaks.n2Prominence(ch) = 0;

    elseif (~isempty(n2p) && isempty(n2n)) || any(max(abs(n2pw)) >= max(abs(n2nw)))%check to use vales from either negative or positive peaks
    
    n2PromIDX = find(max(abs(n2pw)));
    peaks.n2Polarity(ch) = 1;
    peaks.n2Amplitude(ch) = n2p(n2PromIDX);
    peaks.n2Latency(ch) = n2pl(n2PromIDX)+(samplingRate*(0.06));
    peaks.n2Width(ch) = n2pw(n2PromIDX);
    peaks.n2Prominence(ch) = n2pp(n2PromIDX);

    elseif (~isempty(n2n) && isempty(n2p)) || any(max(abs(n2pw)) <= max(abs(n2nw)))

    n2PromIDX = find(max(abs(n2nw)));
    peaks.n2Polarity(ch) = -1;
    peaks.n2Amplitude(ch) = n2n(n2PromIDX);
    peaks.n2Latency(ch) = n2nl(n2PromIDX)+(samplingRate*(0.06));
    peaks.n2Width(ch) = n2nw(n2PromIDX);
    peaks.n2Prominence(ch) = n2np(n2PromIDX);

    end
    
    %use info on peaks to calculate response duration
    n1Onset = peaks.n1Latency(ch)-(.5*peaks.n1Width(ch));

    %determine end of response as when CCEP passes over the min or max
    %prominence of n2 (if n2 exists)
    if peaks.numPeaksN2(ch) ~= 0
    %generate a line of the prominence value
    n2ProminenceY = repmat(peaks.n2Amplitude(ch)-peaks.n2Prominence(ch),length(meanTrace(n2Window)),1);
    
    %create a difference vector between prominence y value and all values
    %in n2 window
    n2Dif = n2ProminenceY - meanTrace(n2Window);

    %set values to either 1 or 0 to detect diff
    posIDX = find(n2Dif >= 0);
    negIDX = find(n2Dif < 0);
    n2Dif(posIDX) = 1;
    n2Dif(negIDX) = 0;
    n2DifDif = diff(n2Dif);
    %find first instance of sign change
    crossover = find(n2DifDif == -1 | n2DifDif == 1);
    if isempty(crossover)
    n2Offset = 0;
    else

    n2Offset = crossover(1)+n2Window(1);
    end
    else
    
    n2Offset = peaks.n1Latency(ch)+(.5*peaks.n1Width(ch)); 
    end
    
    responseRange = time(time >= n1Onset & time <= n2Offset);

    peaks.RMS(ch) = rms(meanTrace(responseRange))-rms(baseDat);

    peaks.responseDuration(ch) = length(responseRange)/samplingRate;
    
    %calculate proportion of n1 peaks
    
    baselineDistr = curDat(baselineWindow,:);
    baselineDistr = baselineDistr(:);
    
    if peaks.numPeaksN1(ch) ~= 0
        
    for t = 1:dimensions(3)
        curTrial = curDat(:,t);
        curN1Window = curTrial(n1Window);
        n1Peaks(t) = curN1Window(n1PromIDX);
    end
    
    peaks.n1PeakToBaseline(ch) = length(n1Peaks(n1Peaks > baseSTD  | n1Peaks < -baseSTD ))/length(n1Peaks);
    clear n1Peaks


    else

    peaks.n1PeakToBaseline(ch) = 0;

    end

end




end
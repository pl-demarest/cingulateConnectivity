function [latencies, peaksOut, prominences] = getN1Latency(data,window,threshold)
%data should be channels x signal, where the singal is a mean CCEP

for ch = 1:size(data,1)

    curDat = data(ch,window);

    [peaks, locs, w, p] = findpeaks(curDat,'MinPeakHeight',threshold(ch));
    [peaksN, locsN, wN, pN] = findpeaks(-curDat,'MinPeakHeight',threshold(ch));

    peaksA = [peaks, -peaksN];
    locsA = [locs, locsN];
    pA = [p, pN];

if isempty(peaksA)

    latencies(ch) = 0;
    peaksOut(ch) = 0;
    prominences(ch) = 0;
    continue

end


    %get peak with the highest prevalence

    peakIDX = find(locsA == min(locsA));
    if length(peakIDX) >1
    peakIDX = peakIDX(1);
    end
    latencies(ch) = locsA(peakIDX);
    peaksOut(ch) = peaksA(peakIDX);
    prominences(ch) = pA(peakIDX);

end


end
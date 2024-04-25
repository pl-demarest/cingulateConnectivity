function [zscoredData] = getZScore(input,baselineWindow)

%input is struct with field dimensions chans x signal x trial
%each field needs to be time locked to the same index- ie the baseline of
%each field needs to be in the same index range
%baseline is an index of signal to be used as baseline data in sample
%window

if length(size(input)) == 3

currentData = input;
zscoredDataCondition = nan(size(currentData));
%Iterate through each trial then z-score to the pre-stim period window.

for ch = 1:size(currentData,1)

for trial = 1:size(currentData,3)
baseline = currentData(ch,baselineWindow,trial);

    baseMean = mean(baseline); 
    baseSTD = std(baseline);

    temp = (currentData(ch,:,trial) - baseMean)/baseSTD;
        
    zscoredDataCondition(ch,:,trial) = temp;

end

end

zscoredData = zscoredDataCondition;

elseif length(size(input)) == 2

%% data input needs to be signal x trial
currentData = input;
zscoredDataCondition = nan(size(currentData));
%Iterate through each trial then z-score to the pre-stim period window.

for t = 1:size(currentData,2)
baseline = currentData(baselineWindow,t);

    baseMean = mean(baseline); 
    baseSTD = std(baseline);

    temp = (currentData(:,t) - baseMean)/baseSTD;
        
    zscoredDataCondition(:,t) = temp;

end

zscoredData = zscoredDataCondition;

else

    disp('format not compatible')
    zscoredData = nan;
end





end
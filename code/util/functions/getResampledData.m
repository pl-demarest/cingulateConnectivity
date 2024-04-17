function [resampledData] = getResampledData(input,newFreq,oldFreq)
%input is struct with field dimensions chans x signal x trial
%each field needs to be time locked to the same index- ie the baseline of
%each field needs to be in the same index range
%baseline is an index of signal to be used as baseline data

fns = fieldnames(input);

for i = 1:length(fns)

currentData = input.(fns{i});

for ch = 1:size(currentData,1)

        for trial = 1:size(currentData,3)
            tempResample(ch,:,trial) = resample(currentData(ch,:,trial),newFreq,oldFreq);
        end
end

resampledData.(fns{i}) = tempResample;

end


end
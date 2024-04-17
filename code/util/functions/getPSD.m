function [dataPower, fb] = getPSD(input,frequencies,samplingRate)



fns = fieldnames(input);

for i = 1:length(fns)

    currentData = input.(fns{i});

    for trial = 1:size(currentData,3)

        for ch = 1:size(currentData,1)


            currentTrace = currentData(ch,:,trial)';

    [powerOut, fb] = pwelch(currentTrace,hamming(length(currentTrace)*0.5),[],frequencies,samplingRate);
    dataPower.(fns{i})(ch,:,trial) = powerOut;


        end
    
    end

end


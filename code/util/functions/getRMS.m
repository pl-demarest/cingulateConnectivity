function [RMSOut] = getRMS(signal, baselineWindow, taskWindow)

RMSOut = nans(size(signal,1),size(signal,3));

for ch = 1:size(signal,1)
    for trial = 1:size(signal,3)

        base = rms(signal(ch,baselineWindow,trial));
        task = rms(signal(ch,taskWindow,trial));

        RMSOut(ch,trial) = mean(task-base);


    end
end



end
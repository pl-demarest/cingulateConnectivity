function [epochedData] = epochData(signal,stimulusCodes,stimulusConditions,timeBefore,timeAfter,samplingRate)


%orient signal data to be channel by signal:

if size(signal,1) > size(signal,2)
    signal = signal';
end

uniqueStimuli = unique(stimulusCodes,'sorted');
uniqueStimuli(uniqueStimuli == 0) = [];


for i = 1:length(uniqueStimuli)

    code = uniqueStimuli(i);
    tempStimulusCodes = stimulusCodes;
    tempStimulusCodes(find(tempStimulusCodes ~= code)) = 0;
    tempStimulusCodes(find(tempStimulusCodes == code)) = 1;
    trialStartStop = diff(double(tempStimulusCodes));
    startIndex = find(trialStartStop == 1);
    
    for ch = 1:min(size(signal))
        for trial = 1:length(startIndex)
            preTrial = startIndex(trial)-(timeBefore*samplingRate);
            postTrial = startIndex(trial)+((timeAfter*samplingRate)-1);
            if preTrial < 1
                continue
                sprintf('Indicated Starting Index <1')
            end

        if size(signal,2) < postTrial
            %For now, the last value of trials shorter than trial length
            %are filled with the last value of the signal
            requiredLength = postTrial-preTrial+1;
            
            tempSignal = signal(ch,preTrial:size(signal,2));
            value = signal(ch,size(signal,2));
            valueMatrix = repmat(value,[1,requiredLength-size(tempSignal,2)]);

            signalWithFakeBaseline = [tempSignal, valueMatrix];
            temp3DMatrix(ch,:,trial) = signalWithFakeBaseline;
                
        else
            temp3DMatrix(ch,:,trial) = signal(ch,preTrial:postTrial);
        end

        end
    end
    if length(uniqueStimuli) > 1
    epochedData = struct;
    epochedData.(stimulusConditions{i}) = temp3DMatrix;
    else
    epochedData = temp3DMatrix;
    end
    clear tempStimulusCodes

end

end




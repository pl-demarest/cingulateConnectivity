function [sortData, uniqueStimuli] = sortData(signal,stimulusCodes,stimulusConditions,samplingRate)

%sort data by stimulus codes

if size(signal,1) > size(signal,2)
    signal = signal';
end

uniqueStimuli = unique(stimulusCodes,'sorted');
uniqueStimuli(uniqueStimuli == 0) = [];
sortData = struct;
tempMatrix = [];

for i = 1:length(uniqueStimuli)

    code = uniqueStimuli(i);
    tempStimulusCodes = stimulusCodes;
    tempStimulusCodes(find(tempStimulusCodes ~= code)) = 0;
    tempStimulusCodes(find(tempStimulusCodes == code)) = 1;

    trialStartStop = diff(double(tempStimulusCodes));
    startIndex = find(trialStartStop == 1);
    stopIndex = find(trialStartStop == -1);

    for ch = 1:min(size(signal))
        for trial = 1:length(startIndex)
            preTrial = startIndex(trial);
            postTrial = stopIndex(trial);    
            
            baseLineStart = postTrial+1;
            baseLineEnd = startIndex(trial+1)-1;




            tempMatrix(ch,:,trial) = signal(ch,preTrial:postTrial);
            tempBase(ch,:,trial) = signal(ch,baseLineStart:baseLineEnd);

        end
    end

    sortData.(stimulusConditions{i}) = tempMatrix;
    sortData.baseline = tempBase;
    
    clear tempStimulusCodes
end



end
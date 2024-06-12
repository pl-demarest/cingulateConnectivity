% use this script to compile final data struct for ML
clear
addpath(genpath(cd))
pooledData = load('data/pooledData.mat');

dataLength = length(pooledData.channelNumber);

rightACC = {'ctx_rh_G_and_S_cingul-Ant','wm_rh_G_and_S_cingul-Ant'};
leftACC = {'ctx_lh_G_and_S_cingul-Ant','wm_lh_G_and_S_cingul-Ant'};

rightMCC = {'ctx_rh_G_and_S_cingul-Mid-Ant','ctx_rh_G_and_S_cingul-Mid-Post','wm_rh_G_and_S_cingul-Mid-Ant','wm_rh_G_and_S_cingul-Mid-Post'};
leftMCC = {'ctx_lh_G_and_S_cingul-Mid-Ant','ctx_lh_G_and_S_cingul-Mid-Post','wm_lh_G_and_S_cingul-Mid-Ant','wm_lh_G_and_S_cingul-Mid-Post'};

rightPCC = {'ctx_rh_G_cingul-Post-dorsal', 'ctx_rh_G_cingul-Post-ventral', 'wm_rh_G_cingul-Post-dorsal','wm_rh_G_cingul-Post-ventral'};
leftPCC = {'ctx_lh_G_cingul-Post-dorsal','ctx_lh_G_cingul-Post-ventral','wm_lh_G_cingul-Post-dorsal','wm_lh_G_cingul-Post-ventral'};


for i = 1:dataLength

    responseStartIDX = pooledData.responseStartTime(i);
    responseEndIDX = pooledData.responseEndTime(i);
    currentStimChan = pooledData.stimulatedRegion{i};

    
    data(i).pValue = pooledData.pValue(i);
    data(i).cohensD = pooledData.cohensD(i);
    data(i).variance = pooledData.variance(i);

    data(i).responseLatency = pooledData.responseLatency(i);
    data(i).responseStart = pooledData.responseStartTime(i);
    data(i).responseEnd = pooledData.responseEndTime(i);
    data(i).responseDuration = pooledData.responseDurationByAbruptChanges(i);
    data(i).responsePeakMagnitude = pooledData.responsePeakMagnitude(i);
    data(i).responsePeakLatency = pooledData.responsePeakMagnitudeTime(i);
    data(i).firstAngle = pooledData.angleCharacteristics(1,i);
    data(i).secondAngle = pooledData.angleCharacteristics(2,i);
    data(i).thirdAngle = pooledData.angleCharacteristics(3,i);
    data(i).firstAngleTime = pooledData.angleCharacteristicsTime(1,i);
    data(i).secondAngleTime = pooledData.angleCharacteristicsTime(2,i);
    data(i).thirdAngleTime = pooledData.angleCharacteristicsTime(3,i);
    if ~isnan(responseStartIDX) || ~isnan(responseEndIDX)
    data(i).startingAngle = pooledData.responseAngles(responseStartIDX, i);
    data(i).endAngle = pooledData.responseAngles(responseEndIDX, i);
    else
    data(i).startingAngle = nan;
    data(i).endAngle = nan;
    end

    data(i).n1Amplitude = pooledData.n1Amplitude(i);
    data(i).n1Latency = pooledData.n1Latency(i);
    data(i).n1PeakNumber = pooledData.n1PeakNumber(i);
    data(i).n1PeakToBaselineRatio = pooledData.n1PeakToBaselineRatio(i);
    data(i).n1Polarity = pooledData.n1Polarity(i);
    data(i).n1Prominence = pooledData.n1Prominence(i);
    data(i).n1Width = pooledData.n1Width(i);
    data(i).n2Amplitude = pooledData.n2Amplitude(i);
    data(i).n2Latency = pooledData.n2Latency(i);
    data(i).n2PeakNumber = pooledData.n2PeakNumber(i);
    data(i).n2Polarity = pooledData.n2Polarity(i);
    data(i).n2Prominence = pooledData.n2Prominence(i);
    data(i).n2Width = pooledData.n2Width(i);

    %assign labels
    if contains(currentStimChan,rightACC)
    
        data(i).label = 1;

    elseif contains(currentStimChan, leftACC)

        data(i).label = 2;

    elseif contains(currentStimChan, rightMCC)

        data(i).label = 3;

    elseif contains(currentStimChan, leftMCC)

        data(i).label = 4;

    elseif contains(currentStimChan, rightPCC)

        data(i).label = 5;

    elseif contains(currentStimChan, leftPCC)

        data(i).label = 6;

    end
    



end


save('data/compiledData.mat','data','-mat','-v7.3')

for i = 1:dataLength

    responseStartIDX = pooledData.responseStartTime(i);
    responseEndIDX = pooledData.responseEndTime(i);
    currentStimChan = pooledData.stimulatedRegion{i};

    
    dataMat(i,1)= pooledData.pValue(i);
    dataMat(i,2) = pooledData.cohensD(i);
    dataMat(i,3) = pooledData.variance(i);

    dataMat(i,4) = pooledData.responseLatency(i);
    dataMat(i,5) = pooledData.responseStartTime(i);
    dataMat(i,6) = pooledData.responseEndTime(i);
    dataMat(i,7) = pooledData.responseDurationByAbruptChanges(i);
    dataMat(i,8) = pooledData.responsePeakMagnitude(i);
    dataMat(i,9) = pooledData.responsePeakMagnitudeTime(i);
    dataMat(i,10) = pooledData.angleCharacteristics(1,i);
    dataMat(i,11) = pooledData.angleCharacteristics(2,i);
    dataMat(i,12) = pooledData.angleCharacteristics(3,i);
    dataMat(i,13) = pooledData.angleCharacteristicsTime(1,i);
    dataMat(i,14) = pooledData.angleCharacteristicsTime(2,i);
    dataMat(i,15) = pooledData.angleCharacteristicsTime(3,i);
    if ~isnan(responseStartIDX) || ~isnan(responseEndIDX)
    dataMat(i,16) = pooledData.responseAngles(responseStartIDX, i);
    dataMat(i,17) = pooledData.responseAngles(responseEndIDX, i);
    else
    dataMat(i,16) = nan;
    dataMat(i,17) = nan;
    end

    dataMat(i,18) = pooledData.n1Amplitude(i);
    dataMat(i,19) = pooledData.n1Latency(i);
    dataMat(i,20) = pooledData.n1PeakNumber(i);
    dataMat(i,21) = pooledData.n1PeakToBaselineRatio(i);
    dataMat(i,22) = pooledData.n1Polarity(i);
    dataMat(i,23) = pooledData.n1Prominence(i);
    dataMat(i,24) = pooledData.n1Width(i);
    dataMat(i,25) = pooledData.n2Amplitude(i);
    dataMat(i,26) = pooledData.n2Latency(i);
    dataMat(i,27) = pooledData.n2PeakNumber(i);
    dataMat(i,28) = pooledData.n2Polarity(i);
    dataMat(i,29) = pooledData.n2Prominence(i);
    dataMat(i,30) = pooledData.n2Width(i);

    %assign labels
    if contains(currentStimChan,rightACC)
    
        dataMat(i,31) = 1;

    elseif contains(currentStimChan, leftACC)

        dataMat(i,31) = 2;

    elseif contains(currentStimChan, rightMCC)

        dataMat(i,31) = 3;

    elseif contains(currentStimChan, leftMCC)

        dataMat(i,31) = 4;

    elseif contains(currentStimChan, rightPCC)

        dataMat(i,31) = 5;

    elseif contains(currentStimChan, leftPCC)

        dataMat(i,31) = 6;

    end
    



end

save('data/compiledDataMatrix.mat','dataMat','-mat','-v7.3')
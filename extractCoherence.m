clear
addpath(genpath(cd))

%specify directories
dataDirectory = 'data/preprocessed/';
saveDirectory = 'data/coherence/';

mkdir(saveDirectory);

%identify data
files = dir(dataDirectory);
filesidx = [files.isdir];
files = files(~filesidx);
dataFiles = {files.name};


for dat = 1:length(dataFiles)

    data = load(dataFiles{dat});
    saveCoherenceFile = [saveDirectory 'coherence_' dataFiles{dat}];
    saveDistributionFile = [saveDirectory 'distribution_' dataFiles{dat}];

if ~isfile(saveCoherenceFile)
    
    runAnalysis = data.spesSmallLaplace;
    baselineWindow = 1:.9*data.samplingRate;
    taskWindow = .95*data.samplingRate:(.95*data.samplingRate + (0.7*data.samplingRate));

    clear data

    coherenceStruct = getCoherenceSingleChannel(runAnalysis,baselineWindow,taskWindow);

    taskData = coherenceStruct.task;
    baseData = coherenceStruct.baseline;
    trialPairs = coherenceStruct.trialPairs;

    save(saveCoherenceFile,"coherenceStruct",'-mat','-v7.3')

    clear coherenceStruct 
end

if ~isfile(saveDistributionFile)
    
    distributionStruct = getDistributionInfo(taskData, baseData, trialPairs);

    save(saveDistributionFile,"distributionStruct",'-mat','-v7.3')

    clear distributionStruct
    
end

end
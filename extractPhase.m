clear
addpath(genpath(cd))

%specify directories
dataDirectory = 'data/preprocessed/';
savePhaseDirectory = 'data/phase/';

mkdir(savePhaseDirectory);

%identify data
files = dir(dataDirectory);
filesidx = [files.isdir];
files = files(~filesidx);
dataFiles = {files.name};

for dat = 1:length(dataFiles)

    load(dataFiles{dat});
    savePhaseFile = [savePhaseDirectory 'phase_' dataFiles{dat}];

if ~isfile(savePhaseFile)
    
    runAnalysis = data.spesSmallLaplace;
    baselineWindow = 1:.9*data.samplingRate;
    taskWindow = .95*data.samplingRate:(.95*data.samplingRate + (0.7*data.samplingRate));
    sr = data.samplingRate;

    clear data
    
    phaseStruct = getPhaseFeatures(runAnalysis,sr,baselineWindow,taskWindow);

    save(savePhaseFile,"phaseStruct",'-mat','-v7.3')

    clear phaseStruct
end


end
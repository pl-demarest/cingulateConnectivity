clear
addpath(genpath(cd))

%specify directories
dataDirectory = 'data/preprocessed/';
hilbertDirectory = 'data/hilbert/';

savePhaseDirectory = 'data/phase/';

mkdir(savePhaseDirectory);

%identify data
files = dir(dataDirectory);
filesidx = [files.isdir];
files = files(~filesidx);
dataFiles = {files.name};

for dat = 1:length(dataFiles)
    currentFile = dataFiles{dat};
    savePhaseFile = [savePhaseDirectory 'phase_' currentFile];

if ~isfile(savePhaseFile)

    load([hilbertDirectory 'hilbert_' currentFile]);
    
    runAnalysis = hilbert.spes;
    clear hilbert

    load([dataDirectory currentFile]);
    sr = data.samplinngRate;
    baselineWindow = 1:.9*data.samplingRate;
    taskWindow = .95*data.samplingRate:(.95*data.samplingRate + (0.95*data.samplingRate));
    clear data
    
    phaseStruct = getPhaseFeatures(runAnalysis,sr,baselineWindow,taskWindow);

    save(savePhaseFile,"phaseStruct",'-mat','-v7.3')

    clear phaseStruct
end


end
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

    runAnalysis = load([hilbertDirectory 'hilbertSEEG_' currentFile],'broadbandLF');
    
    
    load([dataDirectory currentFile],'samplingRate');
    sr = samplingRate;
    baselineWindow = 1:.9*sr;
    taskWindow = .95*sr:(.95*sr + (0.95*sr));
    
    phaseStruct = getPhaseFeatures(runAnalysis,sr,baselineWindow,taskWindow);

    save(savePhaseFile,"phaseStruct",'-mat','-v7.3')

    clear phaseStruct
end


end
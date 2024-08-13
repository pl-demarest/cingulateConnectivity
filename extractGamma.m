clear
addpath(genpath(cd))

%specify directories
dataDirectory = 'data/preprocessed/';
hilbertDirectory = 'data/hilbert/';

savePhaseDirectory = 'data/gamma/';

mkdir(savePhaseDirectory);

%identify data
files = dir(dataDirectory);
filesidx = [files.isdir];
files = files(~filesidx);
dataFiles = {files.name};

for dat = 1:length(dataFiles)
    currentFile = dataFiles{dat};
    saveGammaFile = [savePhaseDirectory 'gamma_' currentFile];

if ~isfile(saveGammaFile)

    runAnalysis = load([hilbertDirectory 'hilbertSEEG_' currentFile],'broadbandGamma');
    
    load([dataDirectory currentFile],'samplingRate');
    sr = samplingRate;
    baselineWindow = 1:.9*sr;
    taskWindow = .95*sr:(.95*sr + (0.95*sr));
    
    gammaStruct = getGammaFeatures(runAnalysis,sr,baselineWindow,taskWindow);

    save(saveGammaFile,'-struct','gammaStruct')

    clear phaseStruct
end


end
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

load([dataDirectory dataFiles{1}],'samplingRate');
sr = samplingRate;

for dat = 1:length(dataFiles)
    currentFile = dataFiles{dat};
    saveGammaFile = [savePhaseDirectory 'gamma_' currentFile];

if ~isfile(saveGammaFile)

    runAnalysis = load([hilbertDirectory 'hilbertSEEG_' currentFile],'broadbandGamma');

    baselineWindow = 1:.9*sr;
    taskWindow = 1.05*sr:((0.95*sr)*2); %ensure stimulation and n1 do not affect gamma
    
    gammaStruct = getGammaFeatures(runAnalysis,sr,baselineWindow,taskWindow);

    save(saveGammaFile,'-struct','gammaStruct')

    clear phaseStruct
end


end
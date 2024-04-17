clear
addpath(genpath(cd))

%specify directories
dataDirectory = 'data/preprocessed/';
saveDirectory = 'data/waveformFeatures/';
mkdir(saveDirectory);

%identify data
files = dir(dataDirectory);
filesidx = [files.isdir];
files = files(~filesidx);
dataFiles = {files.name};

for dat = 1:length(dataFiles)

    
    saveFile = [saveDirectory 'features_' dataFiles{dat}];


if ~isfile(saveFile)

    load(dataFiles{dat});

    toExtract = data.spesSmallLaplaceZScore;
    sr = data.samplingRate;
    clear data

    responseStruct = getPeaks(toExtract,sr);

    save(saveFile,"responseStruct",'-mat','-v7.3')

    clear responseStruct 
    
end

end
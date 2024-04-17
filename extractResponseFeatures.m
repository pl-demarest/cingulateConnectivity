clear
addpath(genpath(cd))

%specify directories
dataDirectory = 'data/preprocessed/';
saveDirectory = 'data/waveformFeatures/';
mkdir(saveDirectory);

%identify data
files = dir(dataDirectory);
dataFiles = {files(41:end).name};

for dat = 1:length(dataFiles)

    
    saveFile = [saveDirectory 'features_' dataFiles{dat}];


if ~isfile(saveFile)

    load(dataFiles{dat});

    toExtract = data.spesSmallLaplace;
    sr = data.samplingRate;
    clear data

    responseStruct = getPeaks(toExtract,sr);

    save(saveFile,"responseStruct",'-mat','-v7.3')

    clear responseStruct 
    
end

end
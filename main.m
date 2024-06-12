clear
addpath(genpath(cd))

%specify directories
dataDirectory = 'data/raw';
saveDirectory = 'data/preprocessed/';
saveHilbert = 'data/hilbert/';
mkdir(saveDirectory);
mkdir(saveHilbert);
spesFolder = 'ElectricalStimulation_1HzStim/ECOG001/';

%import dependencies
load("code/dependencies/cingulateID.mat") % anatomical IDs of cingulate cortex channels
labelTable = readtable("code/dependencies/labelTable.txt"); % table containing all relevant info for anatomical atlas
load("code/dependencies/SEEGClinical22ChanLoc_xyz.mat") % EEG Channel Info
regionIDX = find(ismember(labelTable.Var1,cingulateID));
regionNames = {labelTable.Var2{regionIDX}}';

%identify subject folders
files = dir(dataDirectory);
dirFlags = [files.isdir];
folders = files(dirFlags);
subjects = {folders(3:end).name};

%outer loop: iterate through all subjects
for subj = 1:length(subjects)

    currentSubject = subjects{subj};
    subjectDirectory = [dataDirectory '/' currentSubject '/'];

    if ~isfile([subjectDirectory 'preprocessComplete.txt'])
    specDirectory = [subjectDirectory spesFolder];

    %load stimulation table and channelInspection info
    load([subjectDirectory 'channelInspection.mat']);
    stimTable = readtable([subjectDirectory 'stimulationTable.xlsx']);

    %load baseline data, vera data, check for flags on the baseline data
    %for variability in baseline data collection, and output baseline data accordingly.
    VERA = load([subjectDirectory currentSubject '_APARC2009_MNIbrain.mat']);
    [baseSig, baseStates, baseParams] = importBaseline(subjectDirectory);

    %Use the channel inspection to adjust VERA struct (standardize channels between data file and VERA file), add anatomical IDs
    %to the stimTable, output names and order of the EEG channels.
    
    [VERA, stimTable, EEGChannels, filesOut, namesOut] = processChannels(VERA, channelInspection, stimTable, baseParams.ChannelNames.Value, regionNames, 6, 0.5);
    writetable(stimTable,[subjectDirectory 'stimulationTable.xlsx'])
for file = 1:length(filesOut)

    
    currentFile = filesOut{file};
    currentRegion = {stimTable.ch1ID{find(ismember(stimTable.file, currentFile))},stimTable.ch2ID{find(ismember(stimTable.file, currentFile))}};
    stimulatedChannels = [stimTable.ch1(find(ismember(stimTable.file, currentFile))),stimTable.ch2(find(ismember(stimTable.file, currentFile)))];

    if ~isfile([saveDirectory currentSubject '_' currentFile '_' namesOut{file} '.mat'])
    [data, hilbertSeeg, hilbertEeg] = preprocessData([subjectDirectory spesFolder currentFile '.dat'], baseSig, EEGChannels, channelInspection, currentRegion, VERA, currentSubject, stimTable.currentAmplitude(find(ismember(stimTable.file, currentFile))), stimulatedChannels);
    
    save([saveDirectory currentSubject '_' currentFile '_' namesOut{file} '.mat'],'-struct','data')
    clear data
    save([saveHilbert 'hilbertSEEG_' currentSubject '_' currentFile '_' namesOut{file} '.mat'],'-struct','hilbertSeeg')
    save([saveHilbert 'hilbertEEG_' currentSubject '_' currentFile '_' namesOut{file} '.mat'],'-struct','hilbertEeg')
    clear hilbert

    end

end

preprocessTag = 'preprocessingComplete'
writematrix(preprocessTag,[subjectDirectory 'preprocessComplete.txt'])

    end

end
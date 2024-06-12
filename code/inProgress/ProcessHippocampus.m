clear
addpath(genpath(cd))

%specify directories
dataDirectory = 'data/raw';
saveDirectory = 'data/preprocessedHippocampus/';
spesFolder = 'ElectricalStimulation_1HzStim/ECOG001/';

%import dependencies
load("code/dependencies/cingulateID.mat") % anatomical IDs of cingulate cortex channels
labelTable = readtable("code/dependencies/labelTable.txt"); % table containing all relevant info for anatomical atlas
load("code/dependencies/SEEGClinical22ChanLoc_xyz.mat") % EEG Channel Info
regionIDX = find(ismember(labelTable.Var1,cingulateID));
load('code/dependencies/listHip.mat');
load('code/dependencies/listCort.mat');
load('code/dependencies/listAmyg.mat');

%%
rightACC = {'ctx_rh_G_and_S_cingul-Ant','wm_rh_G_and_S_cingul-Ant'};
leftACC = {'ctx_lh_G_and_S_cingul-Ant','wm_lh_G_and_S_cingul-Ant'};

rightMCC = {'ctx_rh_G_and_S_cingul-Mid-Ant','ctx_rh_G_and_S_cingul-Mid-Post','wm_rh_G_and_S_cingul-Mid-Ant','wm_rh_G_and_S_cingul-Mid-Post'};
leftMCC = {'ctx_lh_G_and_S_cingul-Mid-Ant','ctx_lh_G_and_S_cingul-Mid-Post','wm_lh_G_and_S_cingul-Mid-Ant','wm_lh_G_and_S_cingul-Mid-Post'};

rightPCC = {'ctx_rh_G_cingul-Post-dorsal', 'ctx_rh_G_cingul-Post-ventral' , 'wm_rh_G_cingul-Post-dorsal','wm_rh_G_cingul-Post-ventral'};
leftPCC = {'ctx_lh_G_cingul-Post-dorsal','ctx_lh_G_cingul-Post-ventral','wm_lh_G_cingul-Post-dorsal','wm_lh_G_cingul-Post-ventral'};
%%

regionNames = [listHip,listAmyg,rightACC,leftACC,rightMCC,leftMCC,rightPCC,leftPCC];

%identify subject folders
files = dir(dataDirectory);
dirFlags = [files.isdir];
folders = files(dirFlags);
subjects = {folders(3:end).name};

%outer loop: iterate through all subjects
for subj = 1:length(subjects)

    currentSubject = subjects{subj};
    subjectDirectory = [dataDirectory '/' currentSubject '/'];

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
    
    [VERA, stimTable, EEGChannels, filesOut, namesOut] = processChannels(VERA, channelInspection, stimTable, baseParams.ChannelNames.Value, regionNames, 6);
    writetable(stimTable,[subjectDirectory 'stimulationTable.xlsx'])
for file = 1:length(filesOut)

    
    currentFile = filesOut{file};
    currentRegion = {stimTable.ch1ID{find(ismember(stimTable.file, currentFile))},stimTable.ch2ID{find(ismember(stimTable.file, currentFile))}};
    stimulatedChannels = [stimTable.ch1(find(ismember(stimTable.file, currentFile))),stimTable.ch2(find(ismember(stimTable.file, currentFile)))];

    if ~isfile([saveDirectory currentSubject '_' currentFile '_' namesOut{file} '.mat'])
    [data] = preprocessData([subjectDirectory spesFolder currentFile '.dat'], baseSig, EEGChannels, channelInspection, currentRegion, VERA, currentSubject, stimTable.currentAmplitude(find(ismember(stimTable.file, currentFile))), stimulatedChannels);
    save([saveDirectory currentSubject '_' currentFile '_' namesOut{file} '.mat'],'-struct','data')

    clear data 

    end

end


preprocessTag = 'preprocessingComplete'
writematrix(preprocessTag,[subjectDirectory 'preprocessComplete.txt'])



end
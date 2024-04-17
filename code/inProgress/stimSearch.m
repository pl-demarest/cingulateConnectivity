%run this script to find subjects with specific stimulation converage. For
%example, patients with stimulation of the hippocampus and recording of the
%frontal cortex regions

clear
addpath(genpath(cd))

%specify directories
dataDirectory = 'data/raw';
saveDirectory = 'data/preprocessed/';
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

stimulated = {'CA1-body'
'CA1-head'
'CA3-head'
'CA4-body'
'CA4-head'
'GC-ML-DG-body'
'GC-ML-DG-head'
'HATA'
'hippocampal_fissure'
'molecular_layer_HP-body'
'molecular_layer_HP-head'
'presubiculum-body'
'subiculum-body'
'subiculum-head'};

recorded = {'G_and_S_frontomargin'
'G_and_S_transv_frontopol'
'G_front_inf-Opercular'
'G_front_inf-Orbital'
'G_front_inf-Triangul'
'G_front_middle'
'G_front_sup'
'S_calcarine'
'S_front_inf'
'S_front_middle'
'S_front_sup'
'G_orbital'
'G_rectus'
'S_orbital_lateral'
'S_orbital_med-olfact'
'S_orbital-H_Shaped'
'S_suborbital'};

count = 1;
%outer loop: iterate through all subjects
for subj = 1:length(subjects)
    currentSubject = subjects{subj};
    subjectDirectory = [dataDirectory '/' currentSubject '/'];
    stimTable = readtable([subjectDirectory 'stimulationTable.xlsx']);
    load([subjectDirectory currentSubject '_APARC2009_MNIbrain.mat']);
    SecondaryLabel = cellfun(@(x)x(end),SecondaryLabel,'UniformOutput',false);
    coverage = [stimTable.ch1ID; stimTable.ch2ID];
    %first check coverage
    stimulatedCheck = find(contains([SecondaryLabel{:}],stimulated));
    recordedCheck = find(contains([SecondaryLabel{:}],recorded));
    if ~isempty(stimulatedCheck) && ~isempty(recordedCheck)
    %check if stimuolation in stimulated region
    stimulatedBool = find(contains(coverage,stimulated));
    if ~isempty(stimulatedBool)
        subjectsStore{count} = currentSubject;
        stimulatedCount(count) = length(stimulatedCheck);
        recordedCount(count) = length(recordedCheck);
        count = count +1;
    end
    end
end
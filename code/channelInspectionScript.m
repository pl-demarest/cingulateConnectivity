clear
addpath(genpath(cd))
[sg, states, params] = load_bcidat('/Volumes/Samsung_T5/cingulateConnectivity/data/raw/BJH054/ElectricalStimulation_1HzStim/ECOG001/ECOGS001R01.dat');
load('/Volumes/Samsung_T5/cingulateConnectivity/data/raw/BJH054/BJH054_APARC2009_MNIbrain.mat');

%%
channelInspection.eegElectrodes = [232:254];
channelInspection.removeFromVera = [];

channelInspection.removeFromData = [5,6,218:256]; 
channelInspection.switchChannelsFrom = [];
channelInspection.switchChannelsTo = [];

%%

save('data/raw/BJH054/channelInspection.mat','channelInspection')
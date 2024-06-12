clear
addpath(genpath(cd))
[sg, states, params] = load_bcidat('/Volumes/Samsung_T5/cingulateConnectivity/data/raw/BJH053/ElectricalStimulation_1HzStim/ECOG001/ECOGS001R01.dat');
load('/Volumes/Samsung_T5/cingulateConnectivity/data/raw/BJH053/BJH053_APARC2009_MNIbrain.mat');

%%
channelInspection.eegElectrodes = [232:254];
channelInspection.removeFromVera = [];

channelInspection.removeFromData = [5,6,173:256]; 
channelInspection.switchChannelsFrom = [];
channelInspection.switchChannelsTo = [];

%%

save('data/raw/BJH053/channelInspection.mat','channelInspection')
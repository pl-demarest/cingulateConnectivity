clear
addpath(genpath(cd))
[sg, states, params] = load_bcidat('/Volumes/Samsung_T5/cingulateConnectivity/data/raw/BJH058/ElectricalStimulation_1HzStim/ECOG001/ECOGS001R01.dat');
load('/Volumes/Samsung_T5/cingulateConnectivity/data/raw/BJH058/BJH058_APARC2009_MNIbrain.mat');
%%
channelInspection.eegElectrodes = [233:254];
channelInspection.removeFromVera = [20,21,22,50:54,63,66:70,85:90,126,131,132,146,147,187,188,200,210];

channelInspection.removeFromData = [5,6,233:256];
channelInspection.switchChannelsFrom = [];
channelInspection.switchChannelsTo = [];

%%

save('data/raw/BJH058/channelInspection.mat','channelInspection')
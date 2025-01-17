clear
addpath(genpath(cd))
[sg, states, params] = load_bcidat('/Volumes/Samsung_T5/cingulateConnectivity/data/raw/BJH062/ElectricalStimulation_1HzStim/ECOG001/ECOGS001R01.dat');
load('/Volumes/Samsung_T5/cingulateConnectivity/data/raw/BJH062/BJH062_APARC2009_MNIbrain.mat');
%%
channelInspection.eegElectrodes = [232:254];
channelInspection.removeFromVera = [26,27,67,68,86,104,108:113,117,118,122,133:135,145:149,155,168:170,174:178,198,199,208:210,260:263];

channelInspection.removeFromData = [5,6,232:256];
channelInspection.switchChannelsFrom = [];
channelInspection.switchChannelsTo = [];

%%

save('data/raw/BJH062/channelInspection.mat','channelInspection')
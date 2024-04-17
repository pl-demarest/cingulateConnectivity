clear
addpath(genpath(cd))
[sg, states, params] = load_bcidat('/Volumes/Samsung_T5/cingulateConnectivity/data/raw/BJH032/ElectricalStimulation_1HzStim/ECOG001/ECOGS001R01.dat');
load('/Volumes/Samsung_T5/cingulateConnectivity/data/raw/BJH032/BJH032_APARC2009_MNIbrain.mat');


%%
channelInspection.eegElectrodes = [];
channelInspection.removeFromVera = [];
channelInspection.removeFromData = []; 
channelInspection.switchChannelsFrom = [];
channelInspection.switchChannelsTo = [];

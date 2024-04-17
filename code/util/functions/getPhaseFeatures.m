function phase = getPhaseFeatures(input,samplingRate,baselineWindow,taskWindow)

%%
% bandpass the data
for t = 1:size(input,3)
phase.delta(:,:,t) = bandPassData(input(:,:,t),1,3,4,samplingRate);%delta
phase.theta(:,:,t) = bandPassData(input(:,:,t),4,7,4,samplingRate);%theta
phase.alpha(:,:,t) = bandPassData(input(:,:,t),8,12,4,samplingRate);%alpha
phase.beta(:,:,t) = bandPassData(input(:,:,t),13,25,4,samplingRate);%beta
phase.lowGamma(:,:,t) = bandPassData(input(:,:,t),25,50,4,samplingRate);%lowGamama
phase.broadbandGamma(:,:,t) = bandPassData(input(:,:,t),70,170,4,samplingRate);%highGamma
phase.broadbandLF(:,:,t) = bandPassData(input(:,:,t),5,40,4,samplingRate);%broadband low frequency

phase.deltaHilbert(:,:,t) = getHilbert(squeeze(phase.delta(:,:,t)));
phase.thetaHilbert(:,:,t) = getHilbert(squeeze(phase.theta(:,:,t)));
phase.alphaHilbert(:,:,t) = getHilbert(squeeze(phase.alpha(:,:,t)));
phase.betaHilbert(:,:,t) = getHilbert(squeeze(phase.beta(:,:,t)));
phase.lowGammaHilbert(:,:,t) = getHilbert(squeeze(phase.lowGamma(:,:,t)));
phase.broadbandGammaHilbert(:,:,t) = getHilbert(squeeze(phase.broadbandGamma(:,:,t)));
phase.broadbandLF(:,:,t) = getHilbert(squeeze(phase.broadbandLF(:,:,t)));
end
%% extract angle, magnitude, duration(using abrupt changes), and phase-locked angle/magnitude of each bandpass

for ch = 1:size(input,1)








end


end
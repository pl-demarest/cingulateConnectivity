function phase = getPhaseFeatures(input,baselineWindow,taskWindow)

%% extract angle, magnitude, duration(using abrupt changes), and phase-locked angle/magnitude of each bandpass
fns = fieldnames(input);

for ch = 1:size(input.delta,1)
%extract normalized angle
dA = mean(normalizeAngle(squeeze(input.delta(ch,:,:))),2);
tA = mean(normalizeAngle(squeeze(input.theta(ch,:,:))),2);
aA = mean(normalizeAngle(squeeze(input.alpha(ch,:,:))),2);
bA = mean(normalizeAngle(squeeze(input.beta(ch,:,:))),2);
lGA = mean(normalizeAngle(squeeze(input.lowGamma(ch,:,:))),2);
bGA = mean(normalizeAngle(squeeze(input.broadbandGamma(ch,:,:))),2);
bLFA = mean(normalizeAngle(squeeze(input.broadbandLF(ch,:,:))),2); %use this to characterize response duration
% find the peak magnitude angle for each and return the phase/amplitude of
% each
dMag = mean(squeeze(abs(input.delta(ch,:,:))),2);
tMag = mean(squeeze(abs(input.theta(ch,:,:))),2);
aMag = mean(squeeze(abs(input.alpha(ch,:,:))),2);
bMag = mean(squeeze(abs(input.beta(ch,:,:))),2);
lGMag = mean(squeeze(abs(input.lowGamma(ch,:,:))),2);
bGMag = mean(squeeze(abs(input.broadbandGamma(ch,:,:))),2);
bLFMag = mean(squeeze(abs(input.broadbandLF(ch,:,:))),2);

clear input
%get magnitude and angle of the phase-locked angle. return the angle and
%the magnitude
dPeak = find(dMag == max(dMag(taskWindow)));
tPeak = find(tMag == max(tMag(taskWindow)));
aPeak = find(aMag == max(aMag(taskWindow)));
bPeak = find(bMag == max(bMag(taskWindow)));
lGPeak = find(lGMag == max(lGMag(taskWindow)));
bGPeak = find(bGMag == max(bGMag(taskWindow)));



bLFPeak = find(bLFMag == max(bLFMag(taskWindow)));

ipt = findchangepts(bLFMAG,MaxNumChanges=2,Statistic="rms");


end


end
function phase = getPhaseFeatures(input,samplingRate,baselineWindow,taskWindow)

%initialize tolerance window for detecting response onset
minIndex = taskWindow(1)-(samplingRate*.02);

for ch = 1:size(input.delta,1)

    %% extract information from angle
%extract normalized angle
agl = normalizeAngle(squeeze(input.broadbandLF(ch,:,:)));
meanAgl = mean(agl,2);

%extract duration of phase content
angPts = findchangepts(meanAgl,MaxNumChanges=2,Statistic="rms");
aglDuration = (angPts(2)-angPts(1))/samplingRate;

%if response window matches tolerance window:
if angPts(1) > minIndex && angPts(2) < taskWindow(end)
%function to extract up to 3 of the most prominent change points
else
aglCharacter = [0,0,0];
end


%% extract information from magnitude
%normalize 
mag = getZScore(abs(input.broadbandLF(1,:,:)),baselineWindow);
meanMag = mean(mag,2);

magPts = findchangepts(meanMag,MaxNumChanges=2,Statistic="rms");
magDuration = (magPts(2)-magPts(1))/samplingRate;

%if response window matches tolerance window:
if angPts(1) > minIndex && angPts(2) < taskWindow(end)

else

end


% find the peak magnitude angle for each and return the phase/amplitude of
% % each
% dMag = mean(getZScore(squeeze(abs(input.delta(ch,:,:))),baselineWindow),2);
% tMag = mean(squeeze(abs(input.theta(ch,:,:))),2);
% aMag = mean(squeeze(abs(input.alpha(ch,:,:))),2);
% bMag = mean(squeeze(abs(input.beta(ch,:,:))),2);
% lGMag = mean(squeeze(abs(input.lowGamma(ch,:,:))),2);
% bGMag = mean(squeeze(abs(input.broadbandGamma(ch,:,:))),2);
% bLFMag = mean(squeeze(abs(input.broadbandLF(ch,:,:))),2);
% 
% clear input
% %get magnitude and angle of the phase-locked angle. return the angle and
% %the magnitude
% i.dPeak = find(dMag == max(dMag(taskWindow)));
% i.tPeak = find(tMag == max(tMag(taskWindow)));
% i.aPeak = find(aMag == max(aMag(taskWindow)));
% i.bPeak = find(bMag == max(bMag(taskWindow)));
% i.lGPeak = find(lGMag == max(lGMag(taskWindow)));
% i.bGPeak = find(bGMag == max(bGMag(taskWindow)));
% i.bGPeak = find(bGMag == max(bGMag(taskWindow)));
% 
% % ensure that indexes occur within (at most) -20ms before the stim
% % onset(due to smearing of data)
% 
% iNames = fieldnames(i);
% 
% for f = 1:length(iNames)
% 
% cur = i.(iNames{f});
% 
% if length(cur) >1
% fprintf('multiple peaks detected, only indexing first peak')
% end
% 
% cur(cur<minIndex) = [];
% cur = cur(1);
% i.(iNames{f}) = cur;
% 
% end
% 
% 
% phase.deltaAmplitude(ch) = dMag(i.dPeak);
% phase.thetaAmplitude(ch) = tMag(i.tPeak);
% phase.alphaAmplitude(ch) = max(aMag(taskWindow));
% phase.betaAmplitude(ch) = max(aMag(taskWindow));
% phase.lowGammaAmplitude(ch) = max(aMag(taskWindow));
% phase.broadbandGammaAmplitude(ch) = max(aMag(taskWindow));
% 
% 
% bLFPeak = find(bLFMag == max(bLFMag(taskWindow)));
% 
% ipt = findchangepts(bLFMAG,MaxNumChanges=2,Statistic="rms");


end


end
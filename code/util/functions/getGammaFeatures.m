function gamma = getGammaFeatures(input,samplingRate,baselineWindow,taskWindow)
for ch = 1:size(input.broadbandGamma,1)
% get gamma amplitude and then normalize
magRaw = abs(squeeze(input.broadbandGamma(ch,:,:)));
mag = getZScore(magRaw,baselineWindow);
meanMag = nanmean(squeeze(mag),2);
stdMag = nanstd(squeeze(mag),[],2);

% check for significant increase or decrease in gamma

corrSignal = [meanMag(baselineWindow);meanMag(taskWindow)];
corrBinary = [zeros(length(baselineWindow),1);ones(length(taskWindow),1)];
[r,p] = corr(corrSignal,corrBinary,'type','Spearman');
% get gamma onset and gamma window
magPts = findchangepts(meanMag,MaxNumChanges=2,Statistic="mean");

if isempty(magPts)
magPts = [nan,nan];
responsePeakLatency = nan;
responsePeak = nan;
magDuration = nan;
magAmplitude = nan;
elseif isscalar(magPts)
magPts = [magPts, length(meanMag)];
magDuration = (magPts(2)-magPts(1))/samplingRate;
%if response window matches tolerance window:
responsePeak = max(meanMag(magPts(1):magPts(2)));
responsePeakLatency = find(meanMag(magPts(1):magPts(2)) == responsePeak) + magPts(1)-1;
magAmplitude = nanmean(meanMag(magPts(1):magPts(2)));
else
magDuration = (magPts(2)-magPts(1))/samplingRate;
%if response window matches tolerance window:
responsePeak = max(meanMag(magPts(1):magPts(2)));
responsePeakLatency = find(meanMag(magPts(1):magPts(2)) == responsePeak) + magPts(1)-1;
magAmplitude = nanmean(meanMag(magPts(1):magPts(2)));
end

gamma.meanGamma(ch,:) = meanMag;
gamma.stdGamma(ch,:) = stdMag;
gamma.rho(ch) = r;
gamma.p(ch) = p;
gamma.amplitude(ch) = magAmplitude;
gamma.responseStart(ch) = magPts(1);
gamma.responseStop(ch) = magPts(2);
gamma.responseDuration(ch) = magDuration;
gamma.peakGamma(ch) = responsePeak;
gamma.peakGammaLatency(ch) = responsePeakLatency;

end
end
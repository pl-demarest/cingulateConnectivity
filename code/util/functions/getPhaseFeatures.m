function phase = getPhaseFeatures(input,samplingRate,baselineWindow,taskWindow,numPhases)

% for the detected responses, we have a few assumptions we have to
% consider. Since Changepoint detection on the magnitude of the filtered
% data may lead to cahngepoints detected during an upward ramping of the
% signal, we use the diff function to identify the changepoint where the
% slope of the signal changes. This, however, can lead to a false detection that separates the baseline signal from the post stimulation signal if the
% baseline signal contains noise or larger fluctuations, or if the evoked
% potential also contains oscillation-like behavior. Therefore, we will use
% the estimated temporal distortion window and select the first changepoint
% that occurs the earliest within this estimated window. 

[smearingSamples, ~] = estimateTemporalDistortion(2000,5,40,3); %call this function to get an estimate of temporal distortion due to filter parameters.
minIndex = taskWindow(1) - smearingSamples;


%initialize storage of 3 variables for the output struct
phase.angleCharacterization = nan(size(input.broadbandLF,1),numPhases);
phase.angleCharacterizationTime = nan(size(input.broadbandLF,1),numPhases);

% generate a time vector in ms
length_samples = 3800;
% Sampling rate
fs = 2000; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;

for ch = 1:size(input.broadbandLF,1)
%% extract information from magnitude
%normalize 
magRaw = abs(squeeze(input.broadbandLF(ch,:,:)));
mag = getZScore(magRaw,baselineWindow);
meanMag = nanmean(squeeze(mag),2);

magPtsON = findchangepts(diff(meanMag),MaxNumChanges=2,Statistic="rms");
magPtsOFF = findchangepts(meanMag,MaxNumChanges=2,Statistic="linear");


if (isempty(magPtsON)) || (magPtsON(1) <= minIndex) 

    if ~isempty(magPtsOFF)

        if (magPtsOFF(1) >= minIndex)
        magPts = magPtsOFF;
        else
        magPts = [];
        end

    else 
    magPts = [];
    end

else
magPts = magPtsOFF;
magPts(1) = magPtsON(1);

if length(magPts) == 2
    if magPts(1) > magPts(2)
        magPts = flip(magPts);
    end
end

end


if isempty(magPts)
startStop = [nan,nan];
responsePeakLatency = nan;
responsePeak = nan;
magDuration = nan;
magPts = [nan, nan];
elseif isscalar(magPts)
magPts = [magPts, length(meanMag)];
magDuration = (magPts(2)-magPts(1))/samplingRate;
%if response window matches tolerance window:
responsePeak = max(meanMag(magPts(1):magPts(2)));
responsePeakLatency = find(meanMag(magPts(1):magPts(2)) == responsePeak) + magPts(1)-1;
startStop = [timeVector(magPts), timeVector(length(meanMag))];
else
magDuration = (magPts(2)-magPts(1))/samplingRate;
%if response window matches tolerance window:
responsePeak = max(meanMag(magPts(1):magPts(2)));
responsePeakLatency = find(meanMag(magPts(1):magPts(2)) == responsePeak) + magPts(1)-1;
startStop = [timeVector(magPts(1)),timeVector(magPts(2))];
end

%% extract information from angle
%extract normalized angle
agl = normalizeAngle(squeeze(input.broadbandLF(ch,:,:)));
meanAgl = mean(agl,2);

v = characterizeAngleResponse(meanAgl, magPts, 0, numPhases, false);
v = sort(v,1,"ascend");

%% store variables

phase.angle(ch,:) = meanAgl;
phase.angleCharacterization(ch,:) = v(:,2);
phase.angleCharacterizationTime(ch,:) = v(:,1)+magPts(1);
phase.magnitude(ch,:) = meanMag;

phase.magnitudeStart(ch) = startStop(1);
phase.magnitudeStop(ch) = startStop(2);

phase.startIDX(ch) = magPts(1);
phase.endIDX(ch) = magPts(2);
phase.magnitudeDuration(ch) = magDuration;
phase.peakMagnitude(ch) = responsePeak;
phase.peakMagnitudeLatency(ch) = responsePeakLatency;

end

end
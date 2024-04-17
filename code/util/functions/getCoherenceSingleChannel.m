function [coherenceStruct] = getCoherenceSingleChannel(data,baselineWindow,taskWindow)
%Inpout should be ch x sig x trial
%return a matrix containing coherence values for each channel pair across
%all posisble trail combinations

%establish field name

states = {'baseline','task'};
stateWindows = {baselineWindow, taskWindow};

for state = 1:length(states)

currentState = states{state};
currentStateWindow = stateWindows{state};


n = size(data,3);

%use this to generate all possible cmbinations of trials
[p, q] = meshgrid(1:n, 1:n);
mask   = triu(ones(n), 1) > 0.5;
pairs  = [p(mask) q(mask)];

N = length(pairs);


coherenceMatrix = nan(size(data,1),N);


for ch = 1:size(data,1)

channel = squeeze(data(ch,:,:));

%initialize Correlation distribution
corrDistribution = nan(1,N);


parfor trialPair=1:N
    x = channel(currentStateWindow,pairs(trialPair,1));
    y = channel(currentStateWindow,pairs(trialPair,2));
    corrDistribution(trialPair) = corr(x,y,'Type','spearman');
end

coherenceMatrix(ch,:) = corrDistribution;



end %first Chan

coherenceStruct.(currentState) = coherenceMatrix;

end %experimental state
coherenceStruct.trialPairs = pairs;

end
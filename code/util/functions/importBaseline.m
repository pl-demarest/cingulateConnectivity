function [signal, states, params] = importBaseline(directory)

[bs, states, params] = load_bcidat([directory 'baseline.dat']);
bs = double(bs);

if isfile([directory 'baselineIDX.mat'])
    load([directory 'baselineIDX.mat']); %if the baseline file was selected from another condition, a baselineIDX file will exist, specifying the indexes to be used for baseline.
    signal = bs(baselineIDX,:);
elseif isfield(states,'StimulusCode')
    if length(unique(states.StimulusCode)) == 2 %If data is from BLAES baseline recordings, there are 2 stim codes, where 1 is baseline
    baselineIDX = find(states.StimulusCode == 1);
    signal = bs(baselineIDX,:);
    elseif length(unique(states.StimulusCode)) > 2 %if data came from taVNS baseline, there are multiple stimulus codes, where 0 is baseline
    baselineIDX = find(states.StimulusCode == 0);
    signal = bs(baselineIDX,:);
    end
else
    signal = bs;
end

end
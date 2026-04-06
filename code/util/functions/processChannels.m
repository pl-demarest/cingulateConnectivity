function [VERA, stimTable, EEGChansOut, filesOut, namesOut] = processChannels(VERA, channelInspection, stimTable, ChannelNames, regionNames, stimAmp, stimFreq)

%Input the current VERA struct, the channelInspection struct, the
%stimTable, and the ChannelNames from the baseline parameter file. The
%output of this function will add the anatomical ID of each channel to the
%stimTable in order to start the preprocessing of necessary files.



EEGChansOut = ChannelNames(channelInspection.eegElectrodes);

%Remove channels that need to be removed form the .dat channel names
ChannelNames(channelInspection.removeFromData) = [];
ChannelNames = erase(ChannelNames,' ');
% The VERA struct needs to be adjusted, if
% the switch channels from/to struct field is not empty, use the switch
% function to switch channels BEFORE removing channels from VERA

if isfield(channelInspection,'switchChannelsFrom')
    if ~isempty(channelInspection.switchChannelsFrom)
    VERA = switchVERAChannels(VERA,channelInspection.switchChannelsFrom, channelInspection.switchChannelsTo);
    end
end

VERA = removeNonExistantChannels(VERA,channelInspection.removeFromVera);

%add .dat channels to the channel struct
VERA.channelNames = ChannelNames;

if length(VERA.electrodeLabels) ~= length(ChannelNames)
        error('The number of channels between VERA and .dat are not equal');
end

VERA.SecondaryLabel = cellfun(@(x)x(end),VERA.SecondaryLabel,'UniformOutput',false); %make vera labels uniform

chan1ToIndex = stimTable.ch1;
chan2ToIndex = stimTable.ch2;

cingulateCount = 1;

for ch = 1:length(chan1ToIndex)

    chanelIndex1 = find(ismember(ChannelNames, chan1ToIndex(ch)));
    channelID1 = convertCharsToStrings(VERA.SecondaryLabel{chanelIndex1});

    chanelIndex2 = find(ismember(ChannelNames,chan2ToIndex(ch)));
    channelID2 = convertCharsToStrings(VERA.SecondaryLabel{chanelIndex2});

    stimTable.ch1ID(ch) = {channelID1};
    stimTable.ch2ID(ch) = {channelID2};
    stimTable.ch1Number(ch) = chanelIndex1;
    stimTable.ch2Number(ch) = chanelIndex2;

    if (any(ismember(regionNames, channelID1)) && ismember(stimTable.currentAmplitude(ch), stimAmp) && ismember(stimTable.frequency(ch), stimFreq)) || (any(ismember(regionNames, channelID2)) && ismember(stimTable.currentAmplitude(ch), stimAmp) && ismember(stimTable.frequency(ch), stimFreq))
        filesOut{cingulateCount} = stimTable.file{ch};
        if any(ismember(regionNames, channelID1)) && any(ismember(regionNames, channelID2))
            namesOut(cingulateCount) = channelID1;
        elseif any(ismember(regionNames, channelID1))
            namesOut(cingulateCount) = channelID1;
        elseif any(ismember(regionNames, channelID2))
            namesOut(cingulateCount) = channelID2;
        end
        cingulateCount = cingulateCount +1;
    end
    clear channelID2 channelID1

end



end
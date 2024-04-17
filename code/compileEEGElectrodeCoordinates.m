%% Load coordinate files and get coordinates for relevant electrodes based on the coordinate systems provided by DSI and EEGLAB

% first load
a = readlocs('code/util/eeglab2022.0/sample_data/32ChanLoc_xyz.xyz');
b = readlocs('code/util/eeglab2022.0/sample_data/24ChanLoc_xyz.xyz');

Names = {'Fp1','F3','C3','P3','O1','Fp2','F4','C4','P4','O2','F7','T7','P7','F8','T8','P8','F9','F10','FPz','Fz','Cz','Pz','Oz'};
dimensions = {'X','Y','Z','sph_radius'}; %need to change DSI dimensions to match eegllab dimensions

%% get the DSI values to be the same dimensions and scale as the eeglab example
for i = 1:length(dimensions)

    for ii = 1:length(b)

        if strcmp(dimensions{i},'sph_radius')==1

b(ii).(dimensions{i}) = 1;

        else

b(ii).(dimensions{i}) = b(ii).(dimensions{i})/100;

        end

    end
end
%%
% estract labels field, then use the ismember to find all electrodes that
% do not overlap, then grab all necessary values from t he larger list, and
% add the other electrodes from the smaller list, return error.

thirtyTwoLabels = struct2cell(a);
twentyFourLabels = struct2cell(b);
aLabels = cell(1,length(thirtyTwoLabels));
bLabels = cell(1,length(twentyFourLabels));

parfor ch = 1:length(aLabels)
aLabels{ch} = thirtyTwoLabels{4,1,ch};
end

parfor ch = 1:length(bLabels)
bLabels{ch} = twentyFourLabels{4,1,ch};
end

%% build new struct.
EEGChans = a;
EEGChans(24:32) = [];
for ch = 1:length(Names)


    curChan = Names{ch};

    if ismember(curChan,aLabels) == 1

        idx = find(strcmp(aLabels,curChan));
        EEGChans(ch) = a(idx);

    elseif ismember(curChan,bLabels) ==1 

        idx = find(strcmp(bLabels,curChan));
        EEGChans(ch) = b(idx);

    end



end


EEGChans(17).Y = 0.72;
EEGChans(17).X = -0.48;
EEGChans(17).Z = 0.11;
EEGChans(17).labels = 'F9';
EEGChans(17).sph_theta = 34;
EEGChans(17).sph_phi = 7;
EEGChans(17).theta = -83;
EEGChans(17).radius = 0.52;

EEGChans(18).Y = -0.73;
EEGChans(18).X = -0.49;
EEGChans(18).Z = 0.03;
EEGChans(18).labels = 'F10';
EEGChans(18).sph_theta = -34;
EEGChans(18).sph_phi = 7;
EEGChans(18).theta = 83;
EEGChans(18).radius = 0.52;

figure();
topoplot(zeros(1,23),EEGChans,'style','blank','electrodes','labels')
set(gca,'fontsize',24)

save('code/dependencies/SEEGClinical22ChanLoc_xyz.mat',"EEGChans",'-mat')
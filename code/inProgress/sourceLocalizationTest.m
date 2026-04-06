clear
addpath(genpath(cd))
pooledData = load('/Volumes/Samsung_T5/cingulateConnectivity/data/preprocessed/BJH062_ECOGS001R30_ctx_lh_G_and_S_cingul-Mid-Ant.mat');
load("code/dependencies/SEEGClinical22ChanLoc_xyz.mat") %
%%
testData = squeeze(mean(pooledData.surfaceEEG,3));
save('/Volumes/Samsung_T5/brainstormAnalysis/testData/testData.mat',"testData")

X = [EEGChans.Y];                 % or: X = T{:,2};
Y = [EEGChans.X];                 % or: Y = T{:,1};
Z = [EEGChans.Z];                 % or: Z = T{:,3};
labels = {EEGChans.labels};   % ensure string/cellstr

% Are X/Y/Z in meters already? (unit sphere ~ 1.0) -> use 1
% If in millimeters -> use 1e-3
scale_to_m = 1;  % set to 1e-3 if you know they’re mm

% === BUILD CHANNEL STRUCT ================================================
n = numel(labels);
Channel = repmat(struct( ...
    'Name',        '', ...
    'Type',        'EEG', ...
    'Loc',         zeros(3,1), ...
    'Orient',      [], ...
    'Weight',      1, ...
    'Comment',     '', ...
    'Group',       'EEG', ...
    'DisplayUnits','µV' ...
), 1, n);

for k = 1:n
    Channel(k).Name  = char(labels(k));
    Channel(k).Loc   = [X(k); Y(k); Z(k)] * scale_to_m;  % meters
    % Leave Orient empty for EEG unless you have normals
end

ChanMat = struct();
ChanMat.Comment = sprintf('EEG (%d ch) - custom import', n);
ChanMat.Channel = Channel;

% === SAVE =================================================================
outFile = fullfile('/Volumes/Samsung_T5/brainstormAnalysis/testData/channel_custom.mat');
save(outFile, '-struct', 'ChanMat');
fprintf('Wrote Brainstorm channel file: %s\n', outFile);

% Reuse X, Y, Z, labels, and scale_to_m from above
coords = [X(:), Y(:), Z(:)] * scale_to_m;

outTxt = fullfile('/Volumes/Samsung_T5/brainstormAnalysis/testData/eeg_positions.sfp');  % extension isn’t critical
fid = fopen(outTxt, 'w');
for k = 1:numel(labels)
    fprintf(fid, '%s\t%.9f\t%.9f\t%.9f\n', char(labels(k)), coords(k,1), coords(k,2), coords(k,3));
end
fclose(fid);
fprintf('Wrote ASCII EEG positions: %s\n', outTxt);



%PACKAGEEEGDATA Extract scalp-EEG fields from pooledData.mat into a slim
%   package consumed by the follow-up ccEEG project.
%
%   Inputs:
%       data/pooledData.mat       (this repo, produced by poolData.m)
%
%   Outputs:
%       /Volumes/Samsung_T5/ccEEG/data/eegPooledData.mat
%
%   Usage (from the cingulateConnectivity repo root):
%       cd /Volumes/Samsung_T5/cingulateConnectivity
%       addpath(genpath(cd))
%       packageEEGData
%
%   The output is five top-level variables (EEG, EEGERP, EEGChans,
%   EEGChannelNumber, EEGStimulatedRegion) plus a `provenance` struct.
%   Loaded by ccEEG's eegFigures.m via `pooledData = load(file)`, after
%   which `pooledData.EEG`, `pooledData.EEGStimulatedRegion`, etc. resolve
%   directly. Re-running overwrites.

sourceFile = fullfile(pwd, 'data', 'pooledData.mat');
destDir    = '/Volumes/Samsung_T5/ccEEG/data';
destFile   = fullfile(destDir, 'eegPooledData.mat');

if ~isfile(sourceFile)
    error('packageEEGData:missingSource', ...
        'pooledData.mat not found at %s. Run the pooling pipeline first.', sourceFile);
end

if ~isfolder(destDir)
    mkdir(destDir);
end

fprintf('Loading %s ...\n', sourceFile);
src = load(sourceFile);

if isfield(src, 'pooledData')
    src = src.pooledData;
end

requiredFields = {'EEG', 'EEGERP', 'EEGChans', 'EEGChannelNumber', 'EEGStimulatedRegion'};
for k = 1:numel(requiredFields)
    f = requiredFields{k};
    if ~isfield(src, f)
        error('packageEEGData:missingField', ...
            'pooledData is missing required field "%s".', f);
    end
end

% Promote the five required fields to top-level variables so that ccEEG's
% eegFigures.m can access pooledData.EEG, pooledData.EEGStimulatedRegion, etc.
% directly after `pooledData = load(file)`.
EEG                  = src.EEG;                  %#ok<NASGU>
EEGERP               = src.EEGERP;               %#ok<NASGU>
EEGChans             = src.EEGChans;             %#ok<NASGU>
EEGChannelNumber     = src.EEGChannelNumber;     %#ok<NASGU>
EEGStimulatedRegion  = src.EEGStimulatedRegion;  %#ok<NASGU>

info = dir(sourceFile);
provenance = struct();
provenance.sourceFile     = sourceFile;
provenance.sourceBytes    = info.bytes;
provenance.sourceModified = datestr(info.datenum, 'yyyy-mm-ddTHH:MM:SS');
provenance.packagedAt     = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
provenance.packagedBy     = 'packageEEGData.m';
provenance.matlabVersion  = version;

fprintf('Saving slim package to %s ...\n', destFile);
save(destFile, 'EEG', 'EEGERP', 'EEGChans', 'EEGChannelNumber', ...
               'EEGStimulatedRegion', 'provenance', '-v7.3');

out = dir(destFile);
fprintf('Done. Source: %.1f MB  →  Package: %.1f MB\n', ...
    info.bytes / 1e6, out.bytes / 1e6);

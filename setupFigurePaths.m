% SETUPFIGUREPATHS  Add PEABrain to the MATLAB path from config.mat.
%
%   Run this at the start of any session before generating figures that
%   render 3D brain models (figures 2, 3, 5, 6, suppFig1, and supplementals).
%
%   PEABrain path is set during preflight.m. If this fails, re-run preflight.

if ~isfile('config.mat')
    error('config.mat not found. Run preflight.m first.');
end

load('config.mat', 'config');

if isempty(config.peaBrainPath)
    warning('setupFigurePaths:notConfigured', ...
        'PEABrain path not configured. Re-run preflight.m to set it.');
    return
end

if ~isfolder(config.peaBrainPath)
    warning('setupFigurePaths:notFound', ...
        'PEABrain path not found: %s\nRe-run preflight.m to update it.', ...
        config.peaBrainPath);
    return
end

addpath(genpath(config.peaBrainPath));
fprintf('[OK] PEABrain added to path: %s\n', config.peaBrainPath);

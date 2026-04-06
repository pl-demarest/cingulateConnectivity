function results = pf_checkDependencies()
% PF_CHECKDEPENDENCIES  Verify all required files in code/dependencies/ are present.
%
%   results = pf_checkDependencies()
%
%   These files are loaded at the start of the pipeline (dataPreprocess.m,
%   poolData.m, compileData.m) and must be present in the repo. They provide
%   anatomical atlas IDs, region label tables, and EEG channel metadata.
%
%   Run from the repo root with addpath(genpath(cd)) already called.

results = struct('subject', {}, 'check', {}, 'status', {}, 'message', {});

fprintf('  Checking code/dependencies/ files...\n');

% Required files with a brief description of their purpose
required = {
    'code/dependencies/cingulateID.mat',         'Destrieux atlas IDs for cingulate regions';
    'code/dependencies/labelTable.txt',           'Atlas ID -> region name lookup table';
    'code/dependencies/SEEGClinical22ChanLoc_xyz.mat', 'Surface EEG channel location info';
    'code/dependencies/cingulateNames.mat',       'Cingulate region name strings for figure labels';
    'code/dependencies/regionCategories.xlsx',    'Region grouping table for hierarchical analysis';
    'code/dependencies/mniMRI.mat',               'MNI brain template for 3D rendering';
    'code/dependencies/listAmyg.mat',             'Amygdala atlas label list';
    'code/dependencies/listHip.mat',              'Hippocampus atlas label list';
    'code/dependencies/listCort.mat',             'Cortex atlas label list';
    'code/dependencies/templateLHip.mat',         'Left hippocampus surface template';
    'code/dependencies/templateRHip.mat',         'Right hippocampus surface template';
    'code/dependencies/templateBrain.mat',        'Whole-brain surface template';
};

% Separate required (pipeline-critical) from figure-only files
pipelineCritical = {
    'code/dependencies/cingulateID.mat'
    'code/dependencies/labelTable.txt'
    'code/dependencies/SEEGClinical22ChanLoc_xyz.mat'
    'code/dependencies/cingulateNames.mat'
};

for k = 1:size(required, 1)
    fpath = required{k, 1};
    desc  = required{k, 2};
    checkName = fpath;

    if isfile(fpath)
        results(end+1) = mkEntry('', checkName, 'PASS', desc); %#ok<AGROW>
    else
        % Determine severity: pipeline-critical files are FAIL, others WARN
        if any(strcmp(fpath, pipelineCritical))
            results(end+1) = mkEntry('', checkName, 'FAIL', ...  %#ok<AGROW>
                sprintf('Missing. Required by dataPreprocess.m and poolData.m. (%s)', desc));
        else
            results(end+1) = mkEntry('', checkName, 'WARN', ...  %#ok<AGROW>
                sprintf('Missing. Required for figure scripts only. (%s)', desc));
        end
    end
end

end

% =========================================================================
function e = mkEntry(subject, check, status, message)
if nargin < 4, message = ''; end
e = struct('subject', subject, 'check', check, 'status', status, 'message', message);
end

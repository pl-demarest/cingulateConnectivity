function config = pf_configureDirectories(mode)
% PF_CONFIGUREDIRECTORIES  Interactively configure project paths and write config.mat.
%
%   config = pf_configureDirectories('full_pipeline')
%   config = pf_configureDirectories('preprocessed_only')
%
%   For 'full_pipeline' mode (Path A):
%     Prompts for the raw data root directory and optionally for the
%     PEABrain path (needed by figure scripts).
%
%   For 'preprocessed_only' mode (Path B):
%     Prompts for the directory containing preprocessed .mat files and
%     optionally for PEABrain.
%
%   Saves config.mat at repo root (current directory). Downstream scripts
%   should load this file instead of using hardcoded paths.
%
%   config fields:
%     rawDirectory        — absolute path to raw data root (Path A) or '' (Path B)
%     dataDirectory       — path to preprocessed .mat files
%     hilbertDirectory    — path to hilbert .mat files
%     peaBrainPath        — path to PEABrain repo (for figure scripts; may be '')
%     preflightDate       — timestamp string
%     preflightMode       — 'full_pipeline' | 'preprocessed_only'
%     preflightPassed     — logical (set to true after full validation)
%     subjectsValidated   — cell array of subject IDs that passed (Path A only)

config = struct();
config.rawDirectory      = '';
config.dataDirectory     = 'data/preprocessed/';
config.hilbertDirectory  = 'data/hilbert/';
config.peaBrainPath      = '';
config.preflightDate     = datestr(now);
config.preflightMode     = mode;
config.preflightPassed   = false;
config.subjectsValidated = {};

fprintf('\n');
fprintf('  ---------------------------------------------------------------\n');
fprintf('  Directory Configuration\n');
fprintf('  ---------------------------------------------------------------\n');

switch mode

    % =====================================================================
    case 'full_pipeline'
    % =====================================================================
        fprintf('\n');
        fprintf('  PATH A: Full pipeline from raw BCI2000 data.\n');
        fprintf('\n');
        fprintf('  Raw data root directory:\n');
        fprintf('    This should be the folder that CONTAINS your subject folders.\n');
        fprintf('    Each subject folder must contain:\n');
        fprintf('      - {SubjectID}_APARC2009_MNIbrain.mat\n');
        fprintf('      - stimulationTable.xlsx\n');
        fprintf('      - channelInspection.mat\n');
        fprintf('      - baseline*.dat\n');
        fprintf('      - ElectricalStimulation_1HzStim/ECOG001/*.dat\n');
        fprintf('\n');

        while true
            rawDir = strtrim(input('  Enter raw data root path: ', 's'));
            if isempty(rawDir)
                fprintf('  Path cannot be empty. Please try again.\n');
                continue
            end
            rawDir = strtrim(rawDir);
            if ~isfolder(rawDir)
                fprintf('  [WARN] Path does not exist: %s\n', rawDir);
                retry = input('  Try again? (y/n): ', 's');
                if strcmpi(strtrim(retry), 'n')
                    break
                end
            else
                config.rawDirectory = rawDir;
                fprintf('  [OK] Raw directory: %s\n', rawDir);
                break
            end
        end

        config.dataDirectory    = 'data/preprocessed/';
        config.hilbertDirectory = 'data/hilbert/';
        fprintf('\n');
        fprintf('  Preprocessed output will be saved to: %s (relative to repo root)\n', ...
            config.dataDirectory);

    % =====================================================================
    case 'preprocessed_only'
    % =====================================================================
        fprintf('\n');
        fprintf('  PATH B: Using existing preprocessed data.\n');
        fprintf('\n');
        fprintf('  Preprocessed data directory:\n');
        fprintf('    This should contain .mat files named in the format:\n');
        fprintf('      {SubjectID}_{BCI2000filename}_{stimulatedRegion}.mat\n');
        fprintf('    Each file must contain the required struct fields\n');
        fprintf('    (validated in the next step).\n');
        fprintf('\n');

        while true
            preprocDir = strtrim(input('  Enter preprocessed data directory path: ', 's'));
            if isempty(preprocDir)
                fprintf('  Path cannot be empty.\n');
                continue
            end
            if ~isfolder(preprocDir)
                fprintf('  [WARN] Path does not exist: %s\n', preprocDir);
                retry = input('  Create it now? (y/n): ', 's');
                if strcmpi(strtrim(retry), 'y')
                    mkdir(preprocDir);
                    fprintf('  Directory created: %s\n', preprocDir);
                    config.dataDirectory = preprocDir;
                    break
                else
                    retry2 = input('  Enter a different path? (y/n): ', 's');
                    if strcmpi(strtrim(retry2), 'n'), break; end
                end
            else
                config.dataDirectory = preprocDir;
                fprintf('  [OK] Preprocessed directory: %s\n', preprocDir);
                break
            end
        end

    otherwise
        error('pf_configureDirectories: unknown mode "%s"', mode);
end

% =========================================================================
% Optional: PEABrain path (for figure scripts)
% =========================================================================
fprintf('\n');
fprintf('  PEABrain path (optional — only needed for 3D brain figure scripts):\n');
fprintf('    PEABrain provides 3D cortical surface rendering used in figures 2-7.\n');
fprintf('    If you do not have PEABrain, press Enter to skip.\n');
fprintf('    GitHub: https://github.com/pl-demarest/PEABrain\n');
fprintf('\n');

peaInput = strtrim(input('  Enter PEABrain path (or press Enter to skip): ', 's'));
if ~isempty(peaInput)
    if isfolder(peaInput)
        config.peaBrainPath = peaInput;
        fprintf('  [OK] PEABrain path: %s\n', peaInput);
    else
        fprintf('  [WARN] Path not found: %s. PEABrain path not set.\n', peaInput);
    end
else
    fprintf('  PEABrain path skipped. Figure scripts will not be able to render 3D brains.\n');
end

% =========================================================================
% Create output directory skeleton (Path A)
% =========================================================================
if strcmp(mode, 'full_pipeline')
    fprintf('\n');
    fprintf('  Creating output directory structure...\n');
    outputDirs = {
        'data/preprocessed/'
        'data/hilbert/'
        'data/coherence/'
        'data/gamma/'
        'data/phase/'
        'data/waveformFeatures/'
        'data/pooled/'
    };
    for d = 1:length(outputDirs)
        mkdir(outputDirs{d});
        fprintf('    %s\n', outputDirs{d});
    end
end

% =========================================================================
% Save config.mat
% =========================================================================
save('config.mat', 'config');
fprintf('\n');
fprintf('  [OK] config.mat saved at repo root.\n');
fprintf('       Load with: load(''config.mat'') — provides config.rawDirectory, etc.\n');

end

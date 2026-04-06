% PREFLIGHT.M  cingulateConnectivity project setup and validation script.
%
%   Run this script BEFORE running the pipeline for the first time, or when
%   adding a new subject. It validates all required data structures and writes
%   a config.mat file that downstream scripts use to find your data.
%
%   USAGE:
%     1. Open MATLAB and set cwd to the repo root (the folder containing this file)
%     2. Run:  preflight
%     3. Follow the on-screen prompts
%
%   MODES:
%     [1] Full pipeline from raw BCI2000 data  (Path A)
%         Validates raw data directory, VERA files, stimulation tables,
%         BCI2000 .dat files, and channelInspection.mat for each subject.
%         Creates output directory skeleton and writes config.mat.
%         After a clean preflight, run:  runScripts.m
%
%     [2] Use existing preprocessed data        (Path B)
%         For users who have pre-built the preprocessed .mat structs using
%         pf_buildPreprocessedData or an equivalent pipeline.
%         Validates struct fields and writes config.mat pointing to your data.
%         After a clean preflight, run:  runScripts.m  (skipping dataPreprocess)
%
%     [3] Environment check only
%         Checks MATLAB version, required toolboxes, and dependency files
%         without prompting for data paths.
%
%   OUTPUT:
%     config.mat          — saved at repo root; read by dataPreprocess.m and figure scripts
%     preflight_report.txt — saved at repo root; share with collaborators or attach to issues
%
%   For DATA_GUIDE, see: DATA_GUIDE.md
%   For project overview, see: PROJECT_MAP.md

clear
addpath(genpath(cd))

fprintf('\n');
fprintf('=================================================================\n');
fprintf('  cingulateConnectivity - Preflight Setup\n');
fprintf('=================================================================\n');
fprintf('\n');
fprintf('  Select mode:\n');
fprintf('    [1]  Full pipeline from raw BCI2000 data\n');
fprintf('    [2]  Use existing preprocessed data\n');
fprintf('    [3]  Environment check only\n');
fprintf('\n');

modeStr = strtrim(input('  Enter choice (1/2/3): ', 's'));
if isempty(modeStr)
    modeStr = '1';
end

allResults = struct('subject', {}, 'check', {}, 'status', {}, 'message', {});

% =========================================================================
% STEP 1: Environment and dependency checks (all modes)
% =========================================================================
fprintf('\n');
fprintf('  ---------------------------------------------------------------\n');
fprintf('  Step 1: Environment\n');
fprintf('  ---------------------------------------------------------------\n');

envResults = pf_checkEnvironment();
allResults = [allResults, envResults];

depResults = pf_checkDependencies();
allResults = [allResults, depResults];

% Check for blocking failures before continuing
nFail = sum(strcmp({allResults.status}, 'FAIL'));
if nFail > 0 && ~strcmp(modeStr, '3')
    fprintf('\n');
    fprintf('  [!] %d environment check(s) failed. Resolve before continuing.\n', nFail);
    pf_report(allResults);
    fprintf('  Preflight stopped. Fix the above issues and re-run preflight.\n\n');
    return
end

if strcmp(modeStr, '3')
    % Environment-only mode — print report and exit
    pf_report(allResults, 'preflight_report.txt');
    return
end

% =========================================================================
% STEP 2: Directory configuration
% =========================================================================
fprintf('\n');
fprintf('  ---------------------------------------------------------------\n');
fprintf('  Step 2: Directory Configuration\n');
fprintf('  ---------------------------------------------------------------\n');

switch modeStr
    case '1'
        config = pf_configureDirectories('full_pipeline');
    case '2'
        config = pf_configureDirectories('preprocessed_only');
    otherwise
        fprintf('  Invalid choice. Running environment check only.\n');
        pf_report(allResults, 'preflight_report.txt');
        return
end

% =========================================================================
% STEP 3: Mode-specific validation
% =========================================================================
fprintf('\n');
fprintf('  ---------------------------------------------------------------\n');
fprintf('  Step 3: Data Validation\n');
fprintf('  ---------------------------------------------------------------\n');

switch modeStr

    % =====================================================================
    case '1'   % Full pipeline from raw data
    % =====================================================================

        if isempty(config.rawDirectory) || ~isfolder(config.rawDirectory)
            allResults(end+1) = mkEntry('', 'Raw directory accessible', 'FAIL', ...
                sprintf('Not a valid folder: %s', config.rawDirectory));
            pf_report(allResults, 'preflight_report.txt');
            return
        end

        % Discover subject folders
        rawContents = dir(config.rawDirectory);
        dirFlags    = [rawContents.isdir];
        allDirs     = rawContents(dirFlags);
        allDirs     = allDirs(~ismember({allDirs.name}, {'.', '..'}));
        subjects    = {allDirs.name};

        if isempty(subjects)
            allResults(end+1) = mkEntry('', 'Subject folders found', 'FAIL', ...
                sprintf('No subdirectories found in: %s', config.rawDirectory));
            pf_report(allResults, 'preflight_report.txt');
            return
        end

        allResults(end+1) = mkEntry('', 'Subject folders found', 'PASS', ...
            sprintf('%d subject(s): %s', length(subjects), strjoin(subjects, ', ')));

        fprintf('\n');
        fprintf('  Found %d subject folder(s). Validating each...\n\n', length(subjects));

        % Deep validation opt-in
        deepInput = strtrim(input('  Run deep VERA struct inspection? (y/n, default n): ', 's'));
        deepMode  = strcmpi(deepInput, 'y');

        passedSubjects = {};

        for s = 1:length(subjects)
            subjectID  = subjects{s};
            subjectDir = fullfile(config.rawDirectory, subjectID);
            fprintf('\n');
            subjResults = pf_validateSubject(subjectDir, subjectID, ...
                'ElectricalStimulation_1HzStim/ECOG001/', deepMode);
            allResults = [allResults, subjResults]; %#ok<AGROW>

            % Count failures for this subject
            subjFails = sum(strcmp({subjResults.status}, 'FAIL'));
            if subjFails == 0
                passedSubjects{end+1} = subjectID; %#ok<AGROW>
                fprintf('    Subject %s: READY\n', subjectID);
            else
                fprintf('    Subject %s: %d issue(s) — review report\n', subjectID, subjFails);
            end
        end

        config.subjectsValidated = passedSubjects;
        config.preflightPassed   = ~isempty(passedSubjects);

    % =====================================================================
    case '2'   % Existing preprocessed data
    % =====================================================================

        fprintf('\n');
        fprintf('  Validating preprocessed data in: %s\n', config.dataDirectory);
        fprintf('\n');
        fprintf('  NOTE: If you built your data with pf_buildPreprocessedData, it should\n');
        fprintf('        already match the required schema. If you hand-crafted the structs,\n');
        fprintf('        ensure they match the field list described in DATA_GUIDE.md Section 2.\n');
        fprintf('\n');

        if isfolder(config.dataDirectory)
            preprocResults = pf_validatePreprocessed(config.dataDirectory);
            allResults = [allResults, preprocResults];
        else
            allResults(end+1) = mkEntry('', 'Preprocessed directory', 'FAIL', ...
                sprintf('Directory not found: %s', config.dataDirectory));
        end

        config.preflightPassed = sum(strcmp({allResults.status}, 'FAIL')) == 0;
        config.subjectsValidated = {};

        fprintf('\n');
        fprintf('  For building preprocessed data from arbitrary inputs, see:\n');
        fprintf('    code/util/preflight/pf_buildPreprocessedData.m\n');
        fprintf('\n');
        fprintf('  For the expected struct schema, see:\n');
        fprintf('    DATA_GUIDE.md\n');
end

% =========================================================================
% STEP 4: Save final config and print report
% =========================================================================
config.preflightDate = datestr(now);
save('config.mat', 'config');
fprintf('\n');
fprintf('  config.mat updated.\n');

% Add PEABrain to path for this session if configured
if ~isempty(config.peaBrainPath) && isfolder(config.peaBrainPath)
    addpath(genpath(config.peaBrainPath));
    fprintf('  PEABrain added to MATLAB path (this session).\n');
    fprintf('  NOTE: Run setupFigurePaths at the start of any new figure session.\n');
elseif ~isempty(config.peaBrainPath)
    fprintf('  [WARN] PEABrain path set but folder not found: %s\n', config.peaBrainPath);
    fprintf('         3D brain figures will fail. Re-run preflight to update the path.\n');
else
    fprintf('  [NOTE] PEABrain path not set.\n');
    fprintf('         Figures 2, 3, 5, 6, suppFig1, and supplementals require PEABrain.\n');
    fprintf('         Re-run preflight to configure the PEABrain path.\n');
end

fprintf('\n');
fprintf('  ---------------------------------------------------------------\n');
fprintf('  Preflight Report\n');
fprintf('  ---------------------------------------------------------------\n');

pf_report(allResults, 'preflight_report.txt');

% =========================================================================
% STEP 5: Next steps
% =========================================================================
totalFails = sum(strcmp({allResults.status}, 'FAIL'));
totalWarns = sum(strcmp({allResults.status}, 'WARN'));

if totalFails == 0
    fprintf('  NEXT STEPS:\n');
    if strcmp(modeStr, '1')
        fprintf('    - Review any [WARN] items above (especially missing channelInspection.mat)\n');
        fprintf('    - If channelInspection.mat is missing: run code/channelInspectionScript.m\n');
        fprintf('      for each subject, then re-run preflight to confirm\n');
        fprintf('    - When all subjects are ready: run main.m\n');
        fprintf('    - Before generating figures in a new session: run setupFigurePaths\n');
    elseif strcmp(modeStr, '2')
        fprintf('    - Your preprocessed data is valid\n');
        fprintf('    - Run the pipeline starting from extractCoherence.m:\n');
        fprintf('        run("extractCoherence.m")\n');
        fprintf('        run("extractResponseFeatures.m")\n');
        fprintf('        run("extractGamma.m")\n');
        fprintf('        run("extractPhase.m")\n');
        fprintf('        run("poolData.m")\n');
        fprintf('        run("compileData.m")\n');
    end
    if totalWarns > 0
        fprintf('    - %d warning(s) present — pipeline can run but review recommended\n', totalWarns);
    end
else
    fprintf('  ACTION REQUIRED:\n');
    fprintf('    - Resolve all [FAIL] items listed above\n');
    fprintf('    - Re-run preflight.m to confirm all issues are resolved\n');
    fprintf('    - Review preflight_report.txt for details\n');
end

fprintf('\n');

% preflight

% =========================================================================
function e = mkEntry(subject, check, status, message)
if nargin < 4, message = ''; end
e = struct('subject', subject, 'check', check, 'status', status, 'message', message);
end

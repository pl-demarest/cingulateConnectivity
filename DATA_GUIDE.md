# cingulateConnectivity — Data Setup Guide

This document is the authoritative reference for preparing the data directory and all required inputs before running the analysis pipeline. Every dependency is described, its required format is specified, and the manual steps needed to prepare each file are explained.

Read this before attempting to add a new subject or run the pipeline on a new machine.

---

## Table of Contents

0. [Preflight Setup](#0-preflight-setup)
1. [Prerequisites](#1-prerequisites)
2. [Raw Data Directory Structure](#2-raw-data-directory-structure)
3. [BCI2000 Data Files](#3-bci2000-data-files)
4. [VERA Brain Structure](#4-vera-brain-structure)
5. [stimulationTable.xlsx](#5-stimulationtablexlsx)
6. [channelInspection.mat](#6-channelinspectionmat)
7. [The Channel Alignment Problem](#7-the-channel-alignment-problem)
8. [code/dependencies/ Files](#8-codedependencies-files)
9. [Hardcoded Parameters](#9-hardcoded-parameters)
10. [New Subject Onboarding Checklist](#10-new-subject-onboarding-checklist)
11. [Verification Before Running](#11-verification-before-running)

---

## 0. Preflight Setup

**Before reading the rest of this guide, run `preflight.m` first.**

`preflight.m` (at repo root) is an interactive setup script that guides you through all data requirements, validates every dependency described in this guide, and writes a `config.mat` file that the pipeline uses to locate your data. It replaces the manual checklist process for first-time setup.

```matlab
% From MATLAB with cwd = repo root:
preflight
```

Two modes are available:

| Mode | When to use |
|------|-------------|
| **[1] Full pipeline from raw BCI2000 data** | You have raw `.dat` files, VERA structures, and stimulation tables. Validates all per-subject files and creates the output directory skeleton. |
| **[2] Use existing preprocessed data** | You have pre-built preprocessed `.mat` structs (e.g., built with `pf_buildPreprocessedData.m`). Validates struct fields. |

After a successful preflight, `config.mat` is saved at repo root. The pipeline uses `config.rawDirectory` instead of the hardcoded `data/raw` path. A `preflight_report.txt` is also saved — share it when reporting issues.

**Preflight package location:** `code/util/preflight/` contains all `pf_*.m` modules called by `preflight.m`. See `pf_buildPreprocessedData.m` for the Path B standalone data builder.

If preflight passes without failures, proceed to the sections below only if you need to understand the underlying requirements or troubleshoot a specific issue.

---

## 1. Prerequisites

The following must be installed and available on the MATLAB path before the pipeline can run:

| Dependency | Location | Provides | Required for |
|------------|----------|----------|--------------|
| MATLAB ≥2021b | System | Core runtime | Everything |
| Signal Processing Toolbox | System | `butter`, `filtfilt`, `findchangepts`, `iirnotch` | Preprocessing, feature extraction |
| Statistics & ML Toolbox | System | `corr`, `ranksum`, `signrank`, `mafdr`, `fitcensemble` | Statistics, ML |
| BCI2000 tools | `code/util/tools/` (gitignored) | `load_bcidat` | Loading raw .dat files |
| EEGLAB 2022.0 | `code/util/eeglab2022.0/` (gitignored) | (available on path) | Not directly called in pipeline; available for ad hoc use |
| UMAP/EPP | `code/util/umapAndEpp/` (tracked) | `run_umap` | `uMapRun.m` (exploratory only) |
| PEABrain project | `/Volumes/Samsung_T5/PEABrain` | `cortOut`, brain surface rendering | Figures 2, 3, 5, 6, suppFig1, and supplemental figures only |

> **Note:** The pipeline (`runScripts.m` → `runFigures.m`) runs without PEABrain. PEABrain is only needed for figures that render 3D brain models.

> **Side effect:** `bandPassData.m` calls `fvtool()` on every invocation, which opens a filter visualization window in MATLAB. This happens many times during preprocessing. Close these windows manually or suppress by commenting out `fvtool(b0_A, a0_A)` on line 16 of `bandPassData.m`.

---

## 2. Raw Data Directory Structure

All raw data must be organized under `data/raw/` in the following structure. The pipeline discovers subjects by listing directories in `data/raw/`.

```
data/
└── raw/
    └── <SubjectID>/                       ← e.g., BJH062
        ├── baseline.dat                   ← BCI2000 baseline recording (REQUIRED)
        ├── baselineIDX.mat                ← (OPTIONAL) baseline index subset
        ├── channelInspection.mat          ← (REQUIRED) manual channel alignment spec
        ├── stimulationTable.xlsx          ← (REQUIRED) stimulation condition lookup table
        ├── <SubjectID>_APARC2009_MNIbrain.mat  ← (REQUIRED) VERA brain structure
        └── ElectricalStimulation_1HzStim/
            └── ECOG001/
                ├── <file1>.dat            ← BCI2000 SPES recordings
                ├── <file2>.dat
                └── ...
```

### Subject ID naming convention

Subject IDs use the format `BJH###` (Barnes Jewish Hospital patient number, e.g., `BJH062`). The subject ID must be consistent across:
- The directory name (`data/raw/BJH062/`)
- The VERA filename (`BJH062_APARC2009_MNIbrain.mat`)

The pipeline reads the subject ID from the directory name and constructs the VERA filename by appending `_APARC2009_MNIbrain.mat`. This is hardcoded in `dataPreprocess.m` (line 41). If your institution uses a different naming convention, that line must be updated.

### Subdirectory for SPES recordings

SPES `.dat` files must live in `ElectricalStimulation_1HzStim/ECOG001/` within the subject folder. This path is hardcoded in `dataPreprocess.m` (line 10):

```matlab
spesFolder = 'ElectricalStimulation_1HzStim/ECOG001/';
```

If your raw data uses a different subfolder name, update this variable.

### Preprocessing sentinel file

When preprocessing completes for a subject, `dataPreprocess.m` writes `preprocessComplete.txt` to the subject folder. On subsequent runs, the subject is skipped. To reprocess a subject, delete this file.

Similarly, individual per-file output files are checked:

```matlab
if ~isfile([saveDirectory currentSubject '_' currentFile '_' namesOut{file} '.mat'])
```

Delete the specific output file to force reprocessing of a single condition.

---

## 3. BCI2000 Data Files

All recordings use BCI2000, a general-purpose brain-computer interface platform. Data files use the `.dat` format and are loaded using `load_bcidat` (provided in `code/util/tools/`, gitignored).

### Baseline recording (`baseline.dat`)

The baseline is a resting-state recording used to establish pre-stimulation signal statistics for z-scoring and artifact removal thresholds.

`importBaseline.m` handles three baseline formats automatically:

| Format | How it's detected | What's used |
|--------|------------------|-------------|
| Clean baseline (no StimulusCode field) | `~isfield(states, 'StimulusCode')` | Entire file |
| BLAES baseline (2 StimulusCode values) | `length(unique(states.StimulusCode)) == 2` | Samples where `StimulusCode == 1` |
| taVNS baseline (>2 StimulusCode values) | `length(unique(states.StimulusCode)) > 2` | Samples where `StimulusCode == 0` |

If the baseline was collected during a different recording session or condition and only a subset of time points should be used, create `baselineIDX.mat` in the subject folder with a variable `baselineIDX` — a vector of sample indices to extract from the baseline file. When this file exists, it overrides the StimulusCode-based logic.

### SPES recordings (`<file>.dat`)

Each `.dat` file corresponds to one stimulation condition (one pair of stimulated electrodes at one set of stimulation parameters). The files should be named consistently and these names must match what appears in the `file` column of `stimulationTable.xlsx`.

**Stimulus trigger channel:** The pipeline detects stimulus onset from the `DC04` digital input channel:

```matlab
stimulation = states.DC04;
spesIndex = findStimulusOnset(stimulation, 4e4);
```

- `DC04` must exist in the BCI2000 states
- The threshold is `4 × 10^4` counts — adjust in `preprocessData.m` (line 23) if this channel records at a different voltage scale
- If `spesIndex` is empty (no triggers detected), preprocessing marks the file with `data.message = 'trigbox error'` and skips it

### Channel names in .dat files

BCI2000 channel names are stored in `params.ChannelNames.Value` (a cell array of strings). These names:
- Must exactly match the channel names in `stimulationTable.xlsx` columns `ch1` and `ch2`
- Must exactly match the channel names in `VERA.channelNames` after alignment

Any mismatch causes `processChannels.m` to return empty indices, which will cause downstream errors or incorrect channel assignments.

### Sampling rate

The pipeline reads sampling rate from `params.SamplingRate.NumericValue`. The feature extraction functions (especially `getPhaseFeatures.m`) have a hardcoded time vector assuming **2000 Hz**:

```matlab
length_samples = 3800;
fs = 2000; % Hz, samples per second
```

If your data uses a different sampling rate, this time vector must be updated in `getPhaseFeatures.m` (lines 26-28). Everything else uses `data.samplingRate` dynamically.

---

## 4. VERA Brain Structure

VERA (Visualization of Electrodes and ROI in Anatomy) is a MATLAB framework that co-registers electrode positions from a CT scan into an MRI-derived brain atlas space. The VERA `.mat` file is the single most critical dependency for this pipeline.

### File naming

The VERA file for each subject must be named exactly:

```
<SubjectID>_APARC2009_MNIbrain.mat
```

This is hardcoded in `dataPreprocess.m`:

```matlab
VERA = load([subjectDirectory currentSubject '_APARC2009_MNIbrain.mat']);
```

### Required atlas: FreeSurfer Destrieux (APARC2009)

The pipeline is built exclusively around the **FreeSurfer Destrieux parcellation** (`aparc.a2009s`), also called APARC2009. The atlas label strings throughout the codebase (in `code/dependencies/cingulateNames.mat`, `compileData.m`, and all figure scripts) use Destrieux region names.

**You cannot substitute a different atlas** (e.g., Desikan-Killiany, AAL, Schaefer) without updating:
- `cingulateID.mat` — atlas IDs for cingulate regions
- `labelTable.txt` — full atlas label table
- `cingulateNames.mat` — full label strings for all 6 CC conditions
- `compileData.m` — hardcoded label strings for ML labels
- All figure scripts that use `leftACC`, `rightACC`, etc.

### Required VERA struct fields

The pipeline accesses the following fields. All must exist and be populated:

| Field | Type | Contents |
|-------|------|----------|
| `VERA.electrodeLabels` | {N×1 cell} | Atlas integer label IDs per electrode |
| `VERA.electrodeNames` | {N×1 cell} | Electrode names (e.g., `'LA1'`) |
| `VERA.electrodeDefinition.Annotation` | {N×1 cell} | Annotation strings |
| `VERA.electrodeDefinition.Label` | {N×1 cell} | Label strings |
| `VERA.electrodeDefinition.DefinitionIdentifier` | {N×1 cell} | Definition identifiers |
| `VERA.tala.electrodes` | N×3 double | MNI coordinates (x, y, z) in millimeters |
| `VERA.tala.activations` | {N×1} | Activation values |
| `VERA.tala.trielectrodes` | N×3 or similar | Triangulated electrode coordinates |
| `VERA.SecondaryLabel` | {N×1 cell} | Nested cell of atlas label strings (see below) |

### VERA.SecondaryLabel format — critical

`VERA.SecondaryLabel` is the primary source of anatomical labels for each electrode. The pipeline accesses it as:

```matlab
VERA.SecondaryLabel = cellfun(@(x)x(end), VERA.SecondaryLabel, 'UniformOutput', false);
```

This means **each element of `VERA.SecondaryLabel` must be a cell array**, and the **last element of that cell array must be the atlas label string** for that electrode.

The required label format for the Destrieux atlas is:

```
{tissue_type}_{hemisphere}_{destrieux_region_name}
```

| Component | Values | Example |
|-----------|--------|---------|
| `tissue_type` | `ctx` (cortex) or `wm` (white matter) | `ctx` |
| `hemisphere` | `lh` (left hemisphere) or `rh` (right hemisphere) | `lh` |
| `destrieux_region_name` | Destrieux atlas region name | `G_and_S_cingul-Ant` |

**Full examples:**
- Gray matter, left ACC: `ctx_lh_G_and_S_cingul-Ant`
- White matter, right MCC: `wm_rh_G_and_S_cingul-Mid-Ant`
- Gray matter, left hippocampus: `ctx_lh_G_hippocampi`

These label strings must match exactly what is in `labelTable.txt` (column Var2), because `poolData.m` uses `intersect()` to match stimulated electrode labels against the atlas table.

### Complete list of cingulate atlas labels used by the pipeline

The following 18 label strings (9 left, 9 right) are the ones relevant to stimulation condition assignment. They must appear verbatim in `labelTable.txt` and be producible by your VERA atlas:

**ACC:**
- `ctx_lh_G_and_S_cingul-Ant`, `ctx_rh_G_and_S_cingul-Ant`
- `wm_lh_G_and_S_cingul-Ant`, `wm_rh_G_and_S_cingul-Ant`

**MCC (anterior):**
- `ctx_lh_G_and_S_cingul-Mid-Ant`, `ctx_rh_G_and_S_cingul-Mid-Ant`
- `wm_lh_G_and_S_cingul-Mid-Ant`, `wm_rh_G_and_S_cingul-Mid-Ant`

**MCC (posterior):**
- `ctx_lh_G_and_S_cingul-Mid-Post`, `ctx_rh_G_and_S_cingul-Mid-Post`
- `wm_lh_G_and_S_cingul-Mid-Post`, `wm_rh_G_and_S_cingul-Mid-Post`

**PCC (dorsal):**
- `ctx_lh_G_cingul-Post-dorsal`, `ctx_rh_G_cingul-Post-dorsal`
- `wm_lh_G_cingul-Post-dorsal`, `wm_rh_G_cingul-Post-dorsal`

**PCC (ventral):**
- `ctx_lh_G_cingul-Post-ventral`, `ctx_rh_G_cingul-Post-ventral`
- `wm_lh_G_cingul-Post-ventral`, `wm_rh_G_cingul-Post-ventral`

---

## 5. stimulationTable.xlsx

This Excel file is the lookup table that maps each BCI2000 `.dat` SPES recording to its stimulation parameters and the two electrodes that were stimulated.

### Required columns

The pipeline reads these columns from the table using MATLAB `readtable`. Column names must match exactly (case-sensitive):

| Column | Type | Description |
|--------|------|-------------|
| `file` | string | Filename of the corresponding `.dat` file, **without** the `.dat` extension (e.g., `ECOGS001R01`) |
| `ch1` | string | Name of stimulation electrode 1 — must exactly match the channel name as it appears in the `.dat` file |
| `ch2` | string | Name of stimulation electrode 2 — must exactly match the channel name as it appears in the `.dat` file |
| `currentAmplitude` | numeric | Stimulation current in milliamps (mA) |
| `frequency` | numeric | Stimulation frequency in Hz |

### Columns added automatically by the pipeline (do not pre-populate)

After `processChannels.m` runs, the following columns are added and the table is saved back to disk:

| Column | Contents |
|--------|----------|
| `ch1ID` | Atlas label string for electrode 1 (from VERA.SecondaryLabel) |
| `ch2ID` | Atlas label string for electrode 2 (from VERA.SecondaryLabel) |
| `ch1Number` | Index of electrode 1 within the VERA electrode list |
| `ch2Number` | Index of electrode 2 within the VERA electrode list |

> **Warning:** The pipeline overwrites the `stimulationTable.xlsx` file with these additional columns (`writetable` on line 47 of `dataPreprocess.m`). Make a backup before first processing if you want to preserve the original.

### Filtering behavior

The pipeline processes only rows where:
- `currentAmplitude == 6` (6 mA)
- `frequency == 0.5` (0.5 Hz / 1 Hz SPES)
- At least one of the two stimulated electrodes is anatomically located in a cingulate region

This filter is hardcoded in `dataPreprocess.m`:

```matlab
[VERA, stimTable, EEGChannels, filesOut, namesOut] = processChannels(..., regionNames, 6, 0.5);
```

If your dataset uses different stimulation parameters, update the `6` and `0.5` arguments.

### Creating the table

Before any processing, the `stimulationTable.xlsx` should have one row per `.dat` file in `ElectricalStimulation_1HzStim/ECOG001/`. Include all stimulation files, not just cingulate ones — the pipeline filters for cingulate conditions automatically. The table can include additional informational columns; the pipeline only reads the five required columns above.

---

## 6. channelInspection.mat

This is the most critical manually created file. It bridges the mismatch between the VERA electrode list (all implanted electrodes) and the BCI2000 `.dat` channel list (only the electrodes that were actively recording during the session).

### Required fields

| Field | Type | Description |
|-------|------|-------------|
| `removeFromData` | numeric vector | **Column indices** (1-based) in the `.dat` file of channels to remove from sEEG analysis. Typically includes: EEG electrodes, inactive sEEG electrodes, reference channels |
| `removeFromVera` | numeric vector | **Row indices** (1-based) in the VERA electrode list of electrodes that are NOT in the `.dat` file at all. These are electrodes implanted in the patient but not recorded |
| `eegElectrodes` | numeric vector | **Column indices** (1-based) in the `.dat` file of scalp EEG channels. These are used to build the surface EEG output. Leave empty `[]` if no scalp EEG was recorded |
| `switchChannelsFrom` | numeric vector | VERA electrode indices to move (see Section 7). Leave `[]` if no switching is needed |
| `switchChannelsTo` | numeric vector | Destination VERA indices for the switched channels. Leave `[]` if no switching is needed |

### Example

From `channelInspectionScript.m` (BJH062 example):

```matlab
channelInspection.eegElectrodes = [232:254];     % EEG channels are .dat columns 232 through 254
channelInspection.removeFromVera = [26,27,67,...]; % These VERA electrodes have no corresponding .dat channel
channelInspection.removeFromData = [5,6,232:256]; % Remove these .dat channels from sEEG analysis
channelInspection.switchChannelsFrom = [];
channelInspection.switchChannelsTo = [];

save('data/raw/BJH062/channelInspection.mat', 'channelInspection')
```

In this example:
- The `.dat` file has 256 channels total
- Columns 232–254 are scalp EEG electrodes
- Columns 5, 6, and 232–256 are excluded from sEEG analysis (EEG channels + a couple of bad channels)
- Some VERA electrode entries (26, 27, 67, etc.) correspond to electrodes that were implanted but not in this recording session

### Creating this file

Use `code/channelInspectionScript.m` as a template. Modify it for each new subject and run it once to generate and save the `.mat` file. Steps:

1. Load the `.dat` file to inspect channel count and names
2. Load the VERA file to inspect electrode count
3. Determine which VERA electrodes are absent from the .dat (→ `removeFromVera`)
4. Determine which .dat channels are EEG (→ `eegElectrodes`)
5. Determine which .dat channels to exclude from sEEG analysis (→ `removeFromData`)
6. Determine if VERA and .dat are in the same channel order (→ `switchChannelsFrom/To`)

---

## 7. The Channel Alignment Problem

This is the core manual preprocessing challenge. The VERA file and the `.dat` file must represent exactly the same set of electrodes in exactly the same order after the `channelInspection` adjustments are applied.

### Why mismatches occur

1. **Extra VERA electrodes:** VERA contains all implanted electrodes, including those that were turned off, disconnected, or recorded in a different session. These must be listed in `removeFromVera`.

2. **Extra .dat channels:** The recording amplifier may record EEG electrodes, reference channels, or other auxiliary signals in addition to sEEG. These must be handled by `removeFromData` and `eegElectrodes`.

3. **Order mismatch:** In rare cases, the order of electrodes in the VERA file may not match the order in which channels appear in the `.dat` file. This requires `switchChannelsFrom/To`.

### The alignment check

After `processChannels.m` applies all adjustments, this validation fires:

```matlab
if length(VERA.electrodeLabels) ~= length(ChannelNames)
    error('The number of channels between VERA and .dat are not equal');
end
```

If this error occurs during preprocessing, the `channelInspection` is incorrect. Debug by:
1. Counting VERA electrodes after `removeNonExistantChannels` is applied
2. Counting `.dat` channels after `removeFromData` is applied
3. The two counts must be equal

### Using `switchChannelsFrom/To`

If the electrode order differs between VERA and `.dat` (after removal), you can reorder VERA entries using the switch mechanism. This swaps a block of channels at position `switchFrom` with the block at position `switchTo`, shifting intermediate channels to fill the gap.

Example: If VERA has electrodes in order A, B, C but the `.dat` has them as B, C, A:
```matlab
channelInspection.switchChannelsFrom = [1];    % move VERA position 1 (electrode A)
channelInspection.switchChannelsTo = [3];      % to VERA position 3
```

The switch moves the block starting at `switchFrom(1)` to the position of `switchTo`. Use this carefully and verify the resulting alignment after applying it. The `switchChannelsFrom` and `switchChannelsTo` vectors must be index vectors of the same length.

### Verification

After creating `channelInspection.mat`, verify alignment before running the full pipeline:

```matlab
% In MATLAB, from repo root:
addpath(genpath(cd))
subjectDirectory = 'data/raw/BJH062/';
load([subjectDirectory 'channelInspection.mat']);
VERA = load([subjectDirectory 'BJH062_APARC2009_MNIbrain.mat']);
stimTable = readtable([subjectDirectory 'stimulationTable.xlsx']);
[baseSig, baseStates, baseParams] = importBaseline(subjectDirectory);
regionNames = {'G_and_S_cingul-Ant'}; % minimal test
[VERA_out, stimTable_out, EEGChans, filesOut, namesOut] = processChannels(VERA, channelInspection, stimTable, baseParams.ChannelNames.Value, regionNames, 6, 0.5);
% Should complete without error if alignment is correct
fprintf('VERA channels after alignment: %d\n', length(VERA_out.electrodeLabels));
fprintf('DAT channels after alignment: %d\n', length(VERA_out.channelNames));
```

---

## 8. code/dependencies/ Files

These files are static metadata that the pipeline uses for anatomical labeling and region classification. They are committed to git and should not need to be changed unless the atlas or recording system changes.

### `cingulateID.mat`

Variable: `cingulateID` — numeric vector of Destrieux atlas integer IDs corresponding to cingulate cortex regions.

**How it's used:** `dataPreprocess.m` loads this and cross-references `labelTable.txt` to get the string names of cingulate regions (`regionNames`). These string names are used by `processChannels.m` to identify which stimulation files involve cingulate stimulation.

**If you change the atlas:** The numeric IDs must be updated to match the new atlas's integer ID assignments.

### `labelTable.txt`

Variables: Loaded as a table with columns `Var1` (integer atlas ID) and `Var2` (full label string).

**Required format of `Var2`:** Full FreeSurfer Destrieux label strings including tissue type and hemisphere prefix:
```
ctx_lh_G_and_S_cingul-Ant
ctx_rh_G_and_S_cingul-Ant
wm_lh_G_and_S_cingul-Ant
...
```

**Critical constraint:** The label strings in `Var2` must be byte-for-byte identical to what appears in `VERA.SecondaryLabel` (after the `x(end)` extraction). Any difference in capitalization, spacing, or prefix format will cause the `intersect()` call in `poolData.m` to return no matches, resulting in missing or incorrect stimulation region assignments.

**How to verify consistency:**
```matlab
labelTable = readtable('code/dependencies/labelTable.txt');
% Load a preprocessed file:
data = load('data/preprocessed/BJH062_<file>_<region>.mat');
% Check that the stimulated region matches the label table:
stimRegion = data.stimulatedRegion;
regionNames = {labelTable.Var2{:}};
[match, ~, ~] = intersect(vertcat(stimRegion{:}), regionNames);
disp(match); % Should show the matching cingulate region name
```

### `cingulateNames.mat`

Variables:
- `cingulateNamesSimple` — {5×1 cell} — short Destrieux region names (no hemisphere or tissue prefix):
  - `{'G_and_S_cingul-Ant'; 'G_and_S_cingul-Mid-Ant'; 'G_and_S_cingul-Mid-Post'; 'G_cingul-Post-dorsal'; 'G_cingul-Post-ventral'}`
- `leftACC`, `rightACC`, `leftMCC`, `rightMCC`, `leftPCC`, `rightPCC` — {cell arrays} of full FreeSurfer label strings for each subregion and hemisphere (including both `ctx_` and `wm_` variants)

**How it's used:** Loaded by all figure scripts and `extractInterChanCoherence.m` to define which pooledData channels belong to each stimulation condition.

**If the atlas changes:** These variables must be regenerated with the correct label strings for the new atlas.

### `SEEGClinical22ChanLoc_xyz.mat`

Variable: `EEGChans` — struct array with scalp EEG channel metadata.

Field `.labels` — cell array of channel name strings (e.g., `'Fp1'`, `'Fz'`, etc.).

**How it's used:** Loaded in `dataPreprocess.m`, `poolData.m`, and several figure scripts to label EEG channels. The number of channels (22) must match the number of `eegElectrodes` entries in `channelInspection.mat`. If your recording uses a different EEG montage, this file must be regenerated.

### `regionCategories.xlsx`

Table with columns:
- `Name` — Destrieux region short name (e.g., `G_and_S_cingul-Ant`, without tissue/hemisphere prefix)
- `Class` — broad anatomical category (e.g., `'Cingulate cortex'`, `'Frontal Lobe'`, `'Hippocampus'`)

**How it's used:** Used by figure scripts to assign colors and group regions for network visualization plots. The `Name` values are matched against electrode labels using `contains()`.

**Region classes present in the table:**
`Orbitofrontal cortex`, `Frontal Lobe`, `Cingulate cortex`, `Motor Cortex`, `Somatosensory Cortex`, `Operculum`, `Temporal Lobe`, `Hippocampus`, `Amygdala`, `Insula`, `Parietal Lobe`, `Occipital Lobe`, `Thalamus`, `White Matter`, `Other`

Note: Figures that use this table merge `Motor Cortex` and `Somatosensory Cortex` into `Somato-Motor Cortex`, and remove `Occipital Lobe`, `Other`, `White Matter`, and `White matter` entries.

### `templateBrain.mat`, `templateLHip.mat`, `templateRHip.mat`

**`templateBrain.mat`:** Contains `templateBrain.regions` — struct where each field is a brain region with `.tri` (triangulation faces) and `.vert` (vertex coordinates) for 3D rendering. Also contains `templateBrain.regionList` (cell array of region names). Used by figure scripts as the background brain mesh.

**`templateLHip.mat`, `templateRHip.mat`:** Hippocampus surface templates for 3D visualization.

These files are used only by figure scripts, not the analysis pipeline. If the templates are missing, analysis runs correctly but brain visualizations cannot be rendered.

### `listAmyg.mat`, `listHip.mat`

Cell arrays of amygdala (`listAmyg`) and hippocampus (`listHip`) region label strings. Used in figure scripts to exclude these structures from certain visualizations (e.g., removing subcortical structures from brain models):

```matlab
hipAmyg = [listAmyg, listHip];
hipAmygBool = contains(templateBrain.regionList, hipAmyg);
```

### `mniMRI.mat`

MNI standard brain MRI volume, used for certain visualizations. Not required for the analysis pipeline.

---

## 9. Hardcoded Parameters

These parameters are embedded directly in the code and must be changed manually if your recording protocol differs. Each entry includes the file and line number where the value appears.

| Parameter | Value | Location | What to change if different |
|-----------|-------|----------|-----------------------------|
| Raw SPES subfolder | `'ElectricalStimulation_1HzStim/ECOG001/'` | `dataPreprocess.m:10` | Update `spesFolder` variable |
| Stimulation amplitude filter | `6` (mA) | `dataPreprocess.m:46` | Change `6` in `processChannels(...)` call |
| Stimulation frequency filter | `0.5` (Hz) | `dataPreprocess.m:46` | Change `0.5` in `processChannels(...)` call |
| VERA filename format | `'<SubjectID>_APARC2009_MNIbrain.mat'` | `dataPreprocess.m:41` | Update the `load(...)` call |
| Stimulus trigger channel | `states.DC04` | `preprocessData.m:22` | Change `DC04` to your trigger channel name |
| Stimulus detection threshold | `4e4` counts | `preprocessData.m:23` | Adjust threshold in `findStimulusOnset(...)` call |
| Small Laplace radius | `5` mm | `preprocessData.m:81` | Change the `5` in `smallLaplace(slSig, VERA.tala.electrodes, 5, [])` |
| Artifact removal window | `15` samples | `preprocessData.m:77` | Change in `getCleanData(sig, data.samplingRate, spesIndex, 15)` |
| Highpass cutoff | `0.5` Hz | `getCleanData.m:3` | Change `hp_cutoff` variable |
| Lowpass cutoff (CCEP visualization) | `40` Hz | `preprocessData.m:88` | Change in `getLowPassData(slSig, 40, 5, data.samplingRate)` |
| Notch filter frequency | `60` Hz | `getCleanData.m:11` | Change in `multi_iirnotch_filtering(hp_signal, samplingRate, 60)` |
| Notch filter harmonics | NOT removed | `multi_iirnotch_filtering.m` | Function only removes the single frequency passed; add `[60,120,180,240]` to remove harmonics |
| Epoch duration | `±0.95` s | `preprocessData.m:95-98` | Change `timeBefore/timeAfter = .95` in all `epochData(...)` and `getAllBandpassedData(...)` calls |
| Phase feature time vector | `fs = 2000` Hz | `getPhaseFeatures.m:27` | Update to match your actual sampling rate |
| N of angle characterizations | `3` | `extractPhase.m:34` | Change `numPhases` argument in `getPhaseFeatures(...)` call |
| Coherence baseline window | `1 to 0.85×sr` | `extractCoherence.m:28-29` | Update window indices |
| Coherence task window | `0.95×sr to 0.95×sr + 0.7×sr` | `extractCoherence.m:30` | Update window indices |
| N1 peak window | `10–50 ms` post-stim | `getPeaks.m:16-17` | Update `n1Window` calculation |
| N2 peak window | `60–700 ms` post-stim | `getPeaks.m:18` | Update `n2Window` calculation |
| Peak detection threshold | `5×` baseline SD | `getPeaks.m:29` | Change the `*5` multiplier |
| ML label classes | 6 classes (lACC/rACC/lMCC/rMCC/lPCC/rPCC) | `compileData.m:81-105` | Add or remove condition blocks |
| PEABrain path | `'/Volumes/Samsung_T5/PEABrain'` | 8+ figure scripts | Change or centralize in `setupCingulatePaths.m` |

---

## 10. New Subject Onboarding Checklist

Follow these steps when adding a new subject to the dataset.

### Step 1: Prepare raw files

- [ ] Create subject directory: `data/raw/<BJH###>/`
- [ ] Copy `baseline.dat` to subject directory
- [ ] Create subdirectory: `data/raw/<BJH###>/ElectricalStimulation_1HzStim/ECOG001/`
- [ ] Copy all SPES `.dat` files into the above subdirectory
- [ ] Copy `<BJH###>_APARC2009_MNIbrain.mat` to subject directory — **verify the filename prefix matches the directory name exactly**

### Step 2: Create stimulationTable.xlsx

- [ ] Create an Excel file with columns: `file`, `ch1`, `ch2`, `currentAmplitude`, `frequency`
- [ ] Add one row per `.dat` file in `ElectricalStimulation_1HzStim/ECOG001/`
- [ ] Verify `file` values match `.dat` filenames without extension
- [ ] Verify `ch1` and `ch2` values exactly match channel names in the `.dat` files

### Step 3: Verify VERA structure

Open MATLAB and run:

```matlab
addpath(genpath(cd))
VERA = load('data/raw/<BJH###>/<BJH###>_APARC2009_MNIbrain.mat');
VERA = VERA.VERA;

% Check required fields exist:
assert(isfield(VERA, 'electrodeLabels'), 'Missing: VERA.electrodeLabels');
assert(isfield(VERA, 'electrodeNames'), 'Missing: VERA.electrodeNames');
assert(isfield(VERA, 'tala') && isfield(VERA.tala, 'electrodes'), 'Missing: VERA.tala.electrodes');
assert(isfield(VERA, 'SecondaryLabel'), 'Missing: VERA.SecondaryLabel');

% Check SecondaryLabel format:
testLabel = VERA.SecondaryLabel{1};
assert(iscell(testLabel), 'VERA.SecondaryLabel must be a cell of cells');
fprintf('Sample label: %s\n', testLabel{end});
% Expected format: 'ctx_lh_<Destrieux name>' or 'wm_lh_<Destrieux name>'

% Check electrode count:
fprintf('VERA electrode count: %d\n', length(VERA.electrodeLabels));
```

### Step 4: Inspect channel counts

```matlab
[~, ~, params] = load_bcidat('data/raw/<BJH###>/baseline.dat');
fprintf('.dat channel count: %d\n', length(params.ChannelNames.Value));
disp(params.ChannelNames.Value(1:10)); % Print first 10 channel names
```

Compare the `.dat` channel count to the VERA electrode count. The difference reveals how many entries will go into `removeFromVera` and/or `removeFromData`.

### Step 5: Create channelInspection.mat

- [ ] Identify which VERA electrodes have no corresponding `.dat` channel (→ `removeFromVera`)
- [ ] Identify which `.dat` channels are scalp EEG (→ `eegElectrodes`)
- [ ] Identify which `.dat` channels to exclude from sEEG analysis (→ `removeFromData`)
- [ ] Determine if channel order is consistent between VERA and `.dat` (→ `switchChannelsFrom/To`)
- [ ] Create the struct and save: `save('data/raw/<BJH###>/channelInspection.mat', 'channelInspection')`

### Step 6: Verify alignment

Run the alignment verification from Section 7. Confirm no error is thrown and channel counts match.

### Step 7: Test preprocessing on one file

Before running the full pipeline, test preprocessing on a single cingulate-stimulation file:

```matlab
clear; addpath(genpath(cd))
% Temporarily modify dataPreprocess.m to process only one file,
% or manually call preprocessData.m for a known cingulate file.
% Confirm output file appears in data/preprocessed/
```

### Step 8: Run the full pipeline

```matlab
run('runScripts.m')
```

Monitor for errors. The most common issues:
- Channel count mismatch (fix `channelInspection.mat`)
- `spesIndex` empty / 'trigbox error' (check DC04 channel and threshold)
- `intersect` returning empty match (check atlas label format consistency)

---

## 11. Verification Before Running

Quick checklist to confirm everything is ready before executing `runScripts.m`:

### Per-subject file checklist

For each subject in `data/raw/`:

| File | Exists? | Format correct? |
|------|---------|-----------------|
| `<BJH###>_APARC2009_MNIbrain.mat` | ☐ | VERA struct with Destrieux APARC2009 labels |
| `baseline.dat` | ☐ | BCI2000 format, DC04 channel present |
| `stimulationTable.xlsx` | ☐ | `file`, `ch1`, `ch2`, `currentAmplitude`, `frequency` columns |
| `channelInspection.mat` | ☐ | All 5 fields; `removeFromVera` + `removeFromData` consistent with VERA/dat |
| `ElectricalStimulation_1HzStim/ECOG001/*.dat` | ☐ | Filenames match `stimulationTable.file` column |

### Atlas consistency check

```matlab
addpath(genpath(cd))
load('code/dependencies/cingulateID.mat')
labelTable = readtable('code/dependencies/labelTable.txt');
regionIDX = find(ismember(labelTable.Var1, cingulateID));
regionNames = {labelTable.Var2{regionIDX}}';
disp('Cingulate region names from labelTable:')
disp(regionNames)
% Should list the 9+ cingulate label strings (G_and_S_cingul-Ant, etc.)
% These must match what appears in VERA.SecondaryLabel{i}{end}
```

### Quick pipeline smoke test (one subject, one file)

Manually run the preprocessing steps on a single known-good cingulate file and inspect the output struct before running `runScripts.m` on the full dataset:

```matlab
addpath(genpath(cd))
data = load('data/preprocessed/<BJH###>_<file>_<region>.mat');
fprintf('Subject: %s\n', data.subjectName)
fprintf('Stimulated region: %s / %s\n', data.stimulatedRegion{1}, data.stimulatedRegion{2})
fprintf('Channels: %d, Samples: %d, Trials: %d\n', size(data.spesSmallLaplaceZScore))
fprintf('Sampling rate: %d Hz\n', data.samplingRate)
% Spot check the atlas label against cingulateNames.mat:
load('code/dependencies/cingulateNames.mat')
isCC = any(contains(data.stimulatedRegion, cingulateNamesSimple));
fprintf('Is a cingulate condition: %d\n', isCC)
```

---

*This document should be updated whenever a new subject format is encountered, a hardcoded parameter is changed, or the atlas/VERA pipeline is updated.*

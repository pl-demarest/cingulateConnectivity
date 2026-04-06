# cingulateConnectivity

MATLAB pipeline for characterizing human cingulate cortex (CC) effective connectivity via cortico-cortical evoked potentials (CCEPs).

---

## Overview

Patients with epilepsy undergoing presurgical monitoring at Barnes Jewish Hospital have sEEG electrodes implanted across the cortex. Single-pulse electrical stimulation (SPES) of cingulate subregions — **anterior (ACC)**, **mid (MCC)**, and **posterior (PCC)** — elicits CCEPs at all recording sites. This pipeline extracts six feature families from those CCEPs, pools them into a multi-feature connectivity model, and validates feature discriminability across stimulation sites using a 6-class random forest classifier. Simultaneous scalp EEG recordings relate intracranial findings to non-invasive signatures.

**Six feature families:**
- Pairwise Spearman coherence (trial-to-trial signal similarity)
- N1/N2 peak morphology (10–50 ms and 60–700 ms post-stimulus)
- Broadband gamma envelope (70–170 Hz, changepoint-based)
- Low-frequency phase/magnitude (5–40 Hz, changepoint-based)
- RMS power (task vs. baseline)
- Inter-channel CCEP coherence (cross-channel network connectivity)

**Stack:** MATLAB ≥ 2021b · Signal Processing Toolbox · Statistics and Machine Learning Toolbox

---

## Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Full pipeline map: entry points, stage-by-stage I/O, figure scripts, directory structure, data flow diagrams |
| [DATA_GUIDE.md](DATA_GUIDE.md) | Authoritative data setup guide: raw data structure, BCI2000 formats, VERA alignment, per-subject onboarding checklist |
| [PROJECT_MAP.md](PROJECT_MAP.md) | Scientific and structural reference: anatomy, experimental design, complete I/O schemas, config contract |

---

## Quick Start

```matlab
% Step 1: Add everything to the path (run from repo root)
addpath(genpath(cd))

% Step 2: First-time setup — validates data, environment, writes config.mat
preflight

% Step 3: Run the full pipeline
main
```

> **New machine or new subject?** Run `preflight` first, every time. It validates all data dependencies, checks MATLAB toolboxes and BCI2000 tools, and writes `config.mat` so the pipeline knows where your data lives.

---

## Prerequisites

| Dependency | Where | Required for |
|------------|-------|--------------|
| MATLAB ≥ 2021b | System | Everything |
| Signal Processing Toolbox | System | Filtering, Hilbert, changepoint detection |
| Statistics & ML Toolbox | System | `corr`, `ranksum`, `mafdr`, `fitcensemble` |
| BCI2000 tools (`load_bcidat`) | `code/util/tools/` *(gitignored)* | Loading raw `.dat` files |
| PEABrain project | `/Volumes/Samsung_T5/PEABrain` | 3D brain rendering in figures 2, 3, 5, 6, suppFig1 only |

PEABrain is a companion project providing cingulate surface meshes and electrode rendering. The analysis pipeline runs without it; only figures that render 3D brain models require it.

---

## Repository Structure

```
cingulateConnectivity/
├── main.m                        # Full pipeline entry point
├── preflight.m                   # First-run validation and setup
├── buildStimConfig.m             # Discovers stim conditions, writes stim_filter.txt
├── stim_filter.txt               # User-editable processing filter (auto-generated)
├── config.mat                    # Directory paths written by preflight (gitignored)
├── ARCHITECTURE.md               # Full pipeline and data flow documentation
├── DATA_GUIDE.md                 # Data setup and onboarding guide
├── PROJECT_MAP.md                # Scientific and structural reference
├── code/
│   ├── engine/                   # Pipeline stages (dataPreprocess.m → compileData.m)
│   ├── figures/                  # Manuscript figure scripts (figure2.m – figure7.m)
│   ├── util/
│   │   ├── functions/            # Core shared library
│   │   └── preflight/            # pf_*.m validation modules
│   ├── dependencies/             # Static reference data (.mat, atlas files)
│   └── legacy/                   # Archived exploratory scripts
└── data/                         # All data (gitignored — must be restored locally)
    ├── raw/                      # Input: per-subject BCI2000 recordings
    ├── preprocessed/             # Stage 1 output
    ├── hilbert/                  # Stage 1 output (Hilbert envelopes)
    ├── coherence/                # Stage 2 output
    ├── waveformFeatures/         # Stage 3 output
    ├── gamma/                    # Stage 4 output
    ├── phase/                    # Stage 5 output
    ├── pooledData.mat            # Stage 6 output
    ├── compiledData.mat          # Stage 7 output
    ├── compiledDataMatrix.mat    # Stage 7 output (ML-ready feature matrix)
    ├── interChannelCoherenceSignificant.mat  # Stage 8 output
    └── figures/                  # Figure output (.svg / .png)
```

---

## Pipeline Stages

The pipeline is orchestrated by `main.m`. Each stage reads from disk and writes to disk, so any stage can be re-run independently. All stages are idempotent — existing output files are not recomputed unless deleted.

| Stage | Script | Description |
|-------|--------|-------------|
| 1 | `code/engine/dataPreprocess.m` | Per-subject, per-condition preprocessing: artifact removal, highpass filter, notch filter, Laplace + CAR re-reference, lowpass, Hilbert (7 bands), epoch ±0.95 s, z-score |
| 2 | `code/engine/extractCoherence.m` | Pairwise Spearman ρ across all trial combinations per channel; Cohen's d, Wilcoxon p, mean rho |
| 3 | `code/engine/extractResponseFeatures.m` | N1 peak (10–50 ms) and N2 peak (60–700 ms) amplitude and latency from mean CCEP |
| 4 | `code/engine/extractGamma.m` | Changepoint detection on z-scored broadband gamma (70–170 Hz) envelope; response onset, offset, peak amplitude |
| 5 | `code/engine/extractPhase.m` | Changepoint detection on broadband LF (5–40 Hz) magnitude; 3 most prominent phase extrema |
| 6 | `code/engine/poolData.m` | Concatenates all per-file outputs; annotates electrode coordinates and atlas labels; computes RMS p-values |
| 7 | `code/engine/compileData.m` | Reshapes pooled data into a feature matrix with 6-class labels (right/left × ACC/MCC/PCC) for ML |
| 8* | `code/engine/extractInterChanCoherence.m` | Cross-channel CCEP coherence across brain region pairs *(computationally intensive; run manually)* |

*Stage 8 is optional. Run separately before generating Figure 4.

**Figure generation:** `code/engine/runFigures.m` runs all manuscript figures (2–7) and supplementals in sequence. Call directly or let `main.m` invoke it at the end of the pipeline.

---

## Configuration

### `stim_filter.txt` — Processing filter

Controls which stimulation conditions are included in the analysis. Auto-generated by `buildStimConfig()` from the raw data; edit manually to include or exclude specific conditions.

```
[amplitudes_mA]
6    % include 6mA trials

[frequencies_Hz]
0.5  % include 0.5Hz trials

[epoch_window_sec]
timeBefore = 0.95   % must be > 0.9 to allow baseline window
timeAfter  = 0.95

[regions]
G_and_S_cingul-Ant         % ACC
G_and_S_cingul-Mid-Ant     % MCC anterior
G_and_S_cingul-Mid-Post    % MCC posterior
G_cingul-Post-dorsal       % PCC dorsal
G_cingul-Post-ventral      % PCC ventral
```

Lines starting with `%` are excluded. Regenerate from the raw data at any time:
```matlab
buildStimConfig()
```

### `config.mat` — Directory paths

Written by `preflight.m`. Fields:
- `rawDirectory` — absolute path to raw data root
- `dataDirectory` — path to preprocessed `.mat` files
- `peaBrainPath` — optional PEABrain installation path
- `preflightPassed`, `preflightMode`, `subjectsValidated`, `preflightDate`

To change the raw data location, re-run `preflight.m`.

---

## Adding a New Subject

1. Create `data/raw/<BJH###>/` with the required files (see [DATA_GUIDE.md](DATA_GUIDE.md) for full spec):
   - `baseline.dat` — resting-state BCI2000 recording
   - `<BJH###>_APARC2009_MNIbrain.mat` — VERA brain structure
   - `stimulationTable.xlsx` — stimulation condition table
   - `channelInspection.mat` — channel removal/swap spec
   - `ElectricalStimulation_1HzStim/ECOG001/*.dat` — SPES recordings
2. Run `preflight.m` to validate all files and update `config.mat`.
3. Re-run `buildStimConfig()` to include any new stimulation conditions.
4. Run `main.m` — the pipeline will pick up the new subject automatically.

To reprocess an existing subject, delete `data/raw/<BJH###>/preprocessComplete.txt`.

---

## Figures

| Script | Figure | Primary inputs |
|--------|--------|----------------|
| `code/figures/figure2.m` | Coherence distributions and connectivity maps | `pooledData.mat`, `compiledData.mat`, `templateBrain.mat` |
| `code/figures/figure3.m` | Spatial connectivity distributions | same + `pooledBrain.mat` |
| `code/figures/figure4.m` | Inter-channel coherence network | `interChannelCoherenceSignificant.mat` |
| `code/figures/figure5.m` | Response latency / temporal dynamics | `pooledData.mat`, `compiledData.mat`, `pooledBrain.mat` |
| `code/figures/figure6.m` | Gamma response vs. effective connectivity | same as Fig 5 + `gammaP` |
| `code/figures/figure7.m` | Random forest classifier performance | `randomForestResults/result.mat`, `pooledData.mat` |
| `code/figures/suppFig2.m` | Supplemental Fig 2 | `pooledData.mat` |
| `code/figures/suppFig3.m` | Supplemental Fig 3 | `pooledData.mat` |

Figures are saved to `data/figures/` as `.svg` and `.png`.

> **Note:** Figures 1 and Supp Fig 1 require `pooledBrain.mat` (pre-computed brain mesh) and must be run manually. Figure 4 requires running Stage 8 (`extractInterChanCoherence.m`) first.

---

## Epoch and Feature Conventions

| Parameter | Value |
|-----------|-------|
| Sampling rate | 2000 Hz |
| Epoch length | ±0.95 s = 3800 samples |
| Stimulus sample index | 1900 (1-indexed) |
| Baseline window (z-score) | Samples 1–1800 (0–900 ms pre-stim) |
| N1 window | 10–50 ms post-stim (samples 1910–1990) |
| N2 window | 60–700 ms post-stim (samples 2020–3320) |
| Coherence baseline | 0–850 ms pre-stim (samples 1–1700) |
| Coherence task | Stim to +570 ms (samples 1900–3040) |
| Gamma baseline/task | 0–900 ms pre / stim+100 ms to end |
| Significance | Benjamini-Hochberg FDR at 0.0001 |
| Coherence metric | Spearman rank correlation |

**Cingulate subregion colors** (used throughout all figures):
- ACC: `[162, 127, 184]./255` (lush lilac)
- MCC: `[122, 191, 165]./255` (celadon porcelain)
- PCC: `[34, 175, 194]./255` (lago blue)

---

## Project Status

**Phase: Manuscript revision / figure completion**

| Component | Status |
|-----------|--------|
| Data collection | Complete |
| Preprocessing pipeline | Complete |
| Feature extraction (all 6 families) | Complete |
| Data pooling and compilation | Complete |
| Random forest classifier | Complete |
| Figures 1, 2, 3, 7, supplementals | Complete |
| Figures 4, 5, 6 | In progress |
| Preflight validation system | Complete |
| README / documentation | Complete |
| GitHub sync | Pending |
| Manuscript | Active revision (submitted to *Imaging Neuroscience*) |

---

## Known Issues

1. **Bare `load()` in `extractCoherence.m:25` and `extractResponseFeatures.m:24`** — fails when cwd ≠ `data/preprocessed/`. Fix: prepend `dataDirectory` to the load path.
2. **Hardcoded PEABrain path** — 8+ figure scripts use `addpath(genpath('/Volumes/Samsung_T5/PEABrain'))`. If PEABrain moves, all affected figures break. Planned fix: centralize in a shared `setupCingulatePaths.m`.
3. **`dataPreprocess.m` hardcoded raw path** — reads `data/raw` directly instead of `config.rawDirectory`. Foundation for the fix is in place via `preflight.m`; refactor pending.
4. **`getAllBandpassedData.m` broadbandLFSignal bug** — line 45 references a cleared variable. No downstream code currently uses this output; remove or fix before enabling.
5. **`pf_validateStimTable.m` hardcodes 6mA/0.5Hz** — this preflight check should read `stim_filter.txt` when available. Minor; WARN-level only.

See [PROJECT_MAP.md — Known Gaps](PROJECT_MAP.md) for the complete list with fix guidance.

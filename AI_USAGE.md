# AI Usage Statement

This document describes how artificial intelligence tools were used in the development of this project. It is intended for transparency in scientific reporting and to satisfy AI usage disclosure requirements where applicable.

---

## Summary

AI assistance (Claude, Anthropic) was used exclusively for **software engineering and project infrastructure** tasks. All scientific decisions — including experimental design, choice of analysis methods, interpretation of results, and manuscript content — were made by the authors independently of AI tools.

---

## Specific uses

### Code organization and project structure

As the project matured toward manuscript submission, AI assistance was used to organize the repository into a clean, reproducible structure. This included reorganizing scripts from a flat root layout into a logical directory hierarchy (`code/engine/` for pipeline stages, `code/util/` for shared functions, `code/figures/` for figure generation, `code/legacy/` for archived exploratory scripts), creating a unified `main.m` entry point with annotated stage descriptions, and authoring `PROJECT_MAP.md` and `DATA_GUIDE.md` as comprehensive technical references for the codebase.

### Helper function and tooling development

AI was used to generate several infrastructure scripts that are not part of the core scientific analysis:

- **`preflight.m` and the `pf_*.m` module suite** (`code/util/preflight/`) — a first-run validation system that checks data dependencies, environment compatibility, and directory configuration before pipeline execution.
- **`buildStimConfig.m` and `readStimFilter.m`** — a configuration system that discovers stimulation conditions present in the data across all subjects and writes a user-editable filter file (`stim_filter.txt`) controlling which conditions, amplitudes, and epoch windows are processed.
- **`channelInspectionScript.m`** — rewritten as a guided, parameterized setup script for aligning electrode channel lists between recording hardware and the VERA anatomical framework.

### Debugging and code review

AI assisted with identifying and documenting known issues in the codebase, including a bare `load()` path bug in two pipeline scripts, a variable reference error in `getAllBandpassedData.m`, and a cell array syntax error in `pf_checkDependencies.m` that was caught during testing. These were documented in the project state document and, where appropriate, fixed.

### Idea generation and planning

In later stages of the project, AI was used as a sounding board for infrastructure design decisions — for example, evaluating approaches for making the preprocessing pipeline configurable across stimulation conditions and epoch parameters, and structuring the repository for eventual public release alongside the manuscript. AI contributed to planning the architecture of solutions, but implementation decisions and scientific trade-offs were made by the authors.

---

## What AI was not used for

- Experimental design or data collection
- Selection or implementation of core analysis methods (CCEP feature extraction, coherence computation, peak detection, changepoint detection, random forest classification)
- Statistical methodology or threshold selection
- Scientific interpretation of results
- Manuscript writing, figure design, or conclusions

---

## Tools

| Tool | Version / Model | Use |
|------|----------------|-----|
| Claude (Anthropic) | Claude Sonnet 4.6 / Opus 4.6 | Code generation, debugging, documentation, planning |

AI assistance was provided through the Claude Code CLI in interactive sessions. All AI-generated code was reviewed, tested, and approved by the authors before incorporation into the project.

# EEG Preprocessing Stage Documentation (Phases 1-3)

This directory is dedicated to the sensor-space preprocessing, patient-control normalization, and source-space average ROI projection of the EEG signals (Stages 1-3).

---

## Stages & Outputs Overview

The preprocessing pipeline comprises the following processing stages and outputs:

### 0. Data Reordering & Coordinates (Phase 0)
*   **Purpose**: Verify if raw EEG data has electrode labels. If missing, assign coordinates from templates or standard BioSemi lists (e.g. `Cap_coords_all.xlsx`) and format the output into BIDS structure.
*   **Workflow**: Check labels in EEGLAB. If missing, find coordinates (e.g., from [BioSemi Downloads](https://www.biosemi.com/download.htm)). Run `mainReorderData.m` to generate the correct BIDS folder structure per subject.
*   **Location**: This phase operates externally to the main pipeline (usually in `fase_0` folder) and outputs the raw `.set` files needed for Phase 1.

### 1. Preprocessing (`Preprocessing`)
*   **Purpose**: Downsampling, filtering, artifact correction (ASR), independent component analysis (ICA), component rejection, and bad channel interpolation.
*   **Input Files**: BIDS-structured raw data.
*   **Output Files**: Preprocessed sensor-space `.set` (EEGLAB) and `.fdt` (binary data) files.
*   **Location**: `[database_root]/pipeline-metrics/preprocessing/salida/Preprocessing/Step6_BadChanInterpolation/[subject]/eeg/*.set`

### 2. Normalization (`Normalization`)
*   **Purpose**: Normalizes the sensor power spectra of patients relative to a reference healthy control group.
*   **Input Files**: Preprocessed `.set` files from Step 6.
*   **Output Files**: Normalized sensor-space `.set` and `.fdt` files.
*   **Location**: `[database_root]/pipeline-metrics/preprocessing/salida/Normalization/Step2_PatientControlNorm/[subject]/eeg/*.set`

### 3. Sourceavg ROI Transformation (`SourceTransformation` & `SourceNoNormalizedTransformation`)
*   **Purpose**: Projects sensor-space signals onto a cortical head model to extract source-space signals mapped to 81 cortical Regions of Interest (ROIs).
*   **Input Files**: Cleaned/normalized sensor-space `.set` files.
*   **Output Files**: 
    *   **Normalized Source (`SourceTransformation`)**: `.mat` files containing an `EEG_like` structure with a `data` field (matrix size: `81 ROIs × timepoints`). Location: `salida/SourceTransformation/Step2_SourceAvgROI/[subject]/eeg/*.mat`
    *   **Unnormalized Source (`SourceNoNormalizedTransformation`)**: `.txt` files containing the ROI timeseries matrix. Location: `salida/SourceNoNormalizedTransformation/*[subject]*Rois.txt`

---

## Execution Workflow

The overall processing flow is as follows:

```mermaid
graph TD
    Z[Raw EDF/BDF Data] --> |mainReorderData.m & Coordinates| A
    A[BIDS Raw Data .set] --> B[Preprocessing: downsampling, filtering, ASR, ICA, interpolation]
    B --> C[Sensor-space Preprocessed .set]
    C --> D[Normalization: Z-scoring relative to healthy controls]
    D --> E[Sensor-space Normalized .set]
    E --> F[Source Transformation: eLORETA cortical projections]
    F --> G[Source-space ROI avg .mat / .txt]
```

---

## How to Run Preprocessing in MATLAB

All stages of preprocessing, normalization, and source projection are orchestrated through MATLAB:

### Step 1: Install Dependencies
To run the preprocessing pipeline, a third-party user **MUST** install the following MATLAB Toolboxes/Plugins:
1. **EEGLAB**: The core framework for EEG processing.
2. **FieldTrip**: Used for specific spatial and source-level functions.
3. **EEGLAB Plugins**: `clean_rawdata`, `ICLabel`, `dipfit`, `firfilt`, `bva-io`. (EEGLAB will usually attempt to auto-install these if missing).
4. **MATLAB Toolboxes** (Optional but recommended): *Wavelet Toolbox* (used by eyeCatch; if missing, the pipeline gracefully falls back to ICLabel).

### Step 2: Configure Paths
1. Start MATLAB.
2. Open `runMainPipeline_.m`. At the top of the file, you must specify the absolute paths to your local EEGLAB and FieldTrip installations. For example:
   ```matlab
   eeglab_path = 'C:/Users/your_user/AppData/Roaming/MathWorks/MATLAB Add-Ons/Collections/EEGLAB/eeglab.m';
   fieldtrip_path = 'C:/Users/your_user/AppData/Roaming/MathWorks/MATLAB Add-Ons/Collections/FieldTrip/ft_defaults.m';
   ```
   *(If you installed them via MATLAB Add-Ons on Windows, they are typically located in `%APPDATA%\MathWorks\MATLAB Add-Ons\Collections\`)*.

### Step 3: Configure and Run the Orchestrator
1. Open `runMainPipeline_.m` or create a similar batch script (like `run_turkey.m`).
2. The script uses a **relative path** to locate the BIDS database automatically (`databasePath`). 
3. If your EEG data does not have built-in coordinates (e.g., standard 10-20 system), you can pass a `.ced` or `.locs` file to the pipeline automatically using the `chanlocsFile` parameter in the `f_mainPipeline` call.
   ```matlab
   f_mainPipeline(databasePath, 'signalType', 'RS', 'runPrepro', true, ...
       'newPath', 'salida_turquia', ...
       'chanlocsFile', 'C:/path/to/your/IUEFM_additional.ced');
   ```
4. The pipeline uses MATLAB's `usejava('desktop')` to detect how it is being run. If run directly inside the MATLAB GUI window, it will prompt the user to manually select bad channels (Interactive/Manual mode). If run via command line batch mode (`matlab -batch "runMainPipeline_"`), it will execute fully automatically without any user prompts.
5. The output will automatically be saved into the specified `newPath` folder.

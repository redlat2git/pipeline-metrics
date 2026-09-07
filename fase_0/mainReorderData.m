% mainReorderData.m
% 
% Description:
% This script is part of PHASE 0. It takes raw EEG files (e.g., .edf, .bdf),
% injects the corresponding channel coordinates (labels), and restructures 
% them into a BIDS-compliant directory format required by the Preprocessing pipeline.
%
% Instructions:
% Modify the "USER CONFIGURATION" section below to match your dataset's paths and parameters.

clear all; close all; clc;

%% ========================================================================
%  USER CONFIGURATION
%  ========================================================================

% 1. Path where your raw files are located (do not include the trailing slash)
mainPath = 'C:\ruta\a\tu\data_cruda';

% 2. File extension of your raw data (e.g., '*.edf', '*.bdf', '*.cnt')
fileExtension = '*.edf';

% 3. Path to the channel coordinates file (.ced, .locs, .elp, .sfp)
%    Leave empty ('') if your raw data already has coordinates built-in.
chanlocsFile = 'C:\ruta\a\tu\plantilla\coordenadas.ced';

% 4. Output dataset prefix (e.g., 'sub-3', 'sub-2000')
%    The script will append the file index to this prefix (e.g. sub-3001)
subPrefix = 'sub-3000'; 

% 5. Output task suffix (e.g., 'rs', 'task', 'HEP')
taskSuffix = 'rs';

%% ========================================================================
%  EXECUTION (Do not modify below unless necessary)
%  ========================================================================

% Initialize EEGLAB in background to load plugins
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% Find all raw files in the main directory
rawFiles = dir(fullfile(mainPath, fileExtension));
nSub = length(rawFiles);

if nSub == 0
    disp(['ERROR: No files found matching ' fileExtension ' in ' mainPath]);
    return;
end

fprintf('Found %d files to process.\n', nSub);

for j = 1:nSub
    jName = rawFiles(j).name;
    fprintf('\n---> Processing file %d/%d: %s\n', j, nSub, jName);
    
    % 1. Load the raw data
    % pop_biosig is a general loader for EDF/BDF files
    try
        EEG = pop_biosig(fullfile(mainPath, jName));
    catch ME
        fprintf('Error loading file with pop_biosig, trying pop_loadcnt... (%s)\n', ME.message);
        try
            EEG = pop_loadcnt(fullfile(mainPath, jName));
        catch
            disp('ERROR: Could not load the raw file. Ensure the required EEGLAB plugin (e.g., biosig) is installed.');
            continue;
        end
    end
    
    % 2. Inject channel locations if provided
    if ~isempty(chanlocsFile) && exist(chanlocsFile, 'file')
        if endsWith(chanlocsFile, '.ced') || endsWith(chanlocsFile, '.locs')
            EEG = pop_chanedit(EEG, 'load', {chanlocsFile, 'filetype', 'autodetect'});
        else
            EEG = pop_chanedit(EEG, 'lookup', chanlocsFile);
        end
    elseif ~isempty(chanlocsFile)
        disp(['WARNING: chanlocsFile not found at ' chanlocsFile '. Proceeding without injecting coordinates.']);
    end
    
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    
    % 3. Generate BIDS names and paths
    newName = sprintf('%s%d_%s_eeg.set', subPrefix, j, taskSuffix);
    bidsFolder = sprintf('%s%d', subPrefix, j);
    
    newDir = fullfile(mainPath, 'prepro_analysis', bidsFolder, 'eeg');
    if ~isfolder(newDir)
        mkdir(newDir);
    end
    
    % 4. Save the dataset in EEGLAB format (.set / .fdt)
    EEG = pop_saveset(EEG, 'filename', newName, 'filepath', newDir);
    
    % 5. Copy accompanying TSV files if they exist (BIDS events/channels)
    baseName = jName(1:find(jName=='.', 1, 'last')-1); % Name without extension
    
    channel_name = [baseName, '_channels.tsv']; 
    events_name = [baseName, '_events.tsv'];
    
    if exist(fullfile(mainPath, channel_name), 'file')
        copyfile(fullfile(mainPath, channel_name), fullfile(newDir, channel_name));
    end
    if exist(fullfile(mainPath, events_name), 'file')
        copyfile(fullfile(mainPath, events_name), fullfile(newDir, events_name));
    end
    
    fprintf('Saved successfully in: %s\n', fullfile(newDir, newName));
end

disp('========================================================================');
disp('PHASE 0 COMPLETED: All data has been reordered into BIDS format.');
disp('========================================================================');

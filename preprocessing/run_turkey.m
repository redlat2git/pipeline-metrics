% Script to run Turkey dataset through Preprocessing automatically
clear all; close all; clc;

% Initialize EEGLAB (nogui mode)
eeglab_dir = 'C:/Users/eguen/AppData/Roaming/MathWorks/MATLAB Add-Ons/Collections/EEGLAB';
addpath(eeglab_dir);
eeglab nogui;

% Set paths
currentDir = pwd;
databasePath = 'C:\Users\eguen\Documents\Githubs-Redlat\A_Pipeline_Metricas\comparacion\2_prepro_analysis';
outPath = fullfile(currentDir, 'salida_turquia');
chanlocs = 'C:\Users\eguen\Documents\Githubs-Redlat\A_Pipeline_Metricas\fase_0\IUEFM_additional.ced';

disp('========================================================================');
disp('STARTING TURKEY DATASET PROCESSING (AUTOMATIC)');
disp('========================================================================');

% Run pipeline
f_mainPipeline(databasePath, 'signalType', 'RS', 'runPrepro', true, ...
    'newPath', outPath, ...
    'chanlocsFile', chanlocs, ...
    'runSpatialNorm', false, 'runChansToSource', false, 'runSourceAvgROI', false, ...
    'runPatientControlNorm', false, 'runClassifier', false);

disp('========================================================================');
disp('TURKEY PREPROCESSING COMPLETED');
disp('========================================================================');

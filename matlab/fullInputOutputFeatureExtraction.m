function [inputFeatures] = fullInputOutputFeatureExtraction(fullFilePath,opts)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    
dataFile = fopen(opts.segmented_file_dir + fileList(idx).name);
data = cell2mat(textscan( dataFile, ...
 '%f %f %f', 'TreatAsEmpty', '-', 'EmptyValue', 0));
fclose(dataFile);

inputFeatures = containers.Map(); %using a key-value pair to store features

time = data(:,1);
abp_wave = data(:,2);
ppg_wave = data(:,3);

[sys,dias,feet] = findPPGPeaks(ppg_wave, opts.samp_freq);
sortedFeatures = sortPPGPeaks(sys, dias, feet);

systolic_peak_amplitude = mean(ppg_wave(sortedFeatures(:,2)));
systolic_peak_amplitude = (systolic_peak_amplitude-opts.sysPeakAmpMean)/(3*opts.sysPeakAmpSD);
inputFeatures('SysPeakAmp') = systolic_peak_amplitude;

diastolic_peak_amplitude = mean(ppg_wave(sortedFeatures(:,3)));
diastolic_peak_amplitude = (diastolic_peak_amplitude-opts.diasPeakAmpMean)/(3*opts.diasPeakAmpSD);
inputFeatures('DiasPeakAmp') = diastolic_peak_amplitude;

feet_amplitude = mean(ppg_wave(sortedFeatures(:,1)));
feet_amplitude = (feet_amplitude - opts.feetAmplitudeMean)/(3*opts.feetAmplitudeSD);
inputFeatures('feetAmp') = feet_amplitude;

heart_rate = heartRateFromPPG(sortedFeatures(:,1), sortedFeatures(:,4), opts.samp_freq);
heart_rate = (heart_rate-opts.heartRateMean)/(3*heartRateSD);
inputFeatures('HR') = heart_rate;

resp_rate =  getRespiratoryRateFreq(time, ppg_wave);
resp_rate = (resp_rate-opts.respRateMean)/(3*opts.respRateSD);
inputFeatures('RespRate') = resp_rate;

[PA, IPA, AI] = ppgAreaAndHeightFeatures(data(:,3), sortedFeatures);
PA = (PA-opts.PAMean)/(3*opts.PASD);
inputFeatures('PA') = PA;
IPA = (IPA-opts.IPAMean)/(3*opts.IPASD);
inputFeatures('IPA') = IPA;
AI = (PA-opts.AIMean)/(3*opts.AISD);
inputFeatures('AI') = AI;

deltaT = mean((sortedFeatures(:,3)-sortedFeatures(:,2))./opts.samp_freq);
deltaT = (deltaT-opts.deltaTMean)/(3*opts.deltaTSD);
inputFeatures('deltaT') = deltaT;

CT = mean((sortedFeatures(:,2)-sortedFeatures(:,1))./opts.samp_freq);
CT = (CT-opts.CTMean)/(3*opts.CTSD);
inputFeatures('CT') = CT;

% STILL NEED THE FREQUENCY FEATURES FOR THE INPUT

% STILL NEED ALL FEATURES FOR THE OUTPUT

end
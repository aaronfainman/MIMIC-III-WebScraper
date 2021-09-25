function [inputFeatures] = fullInputOutputFeatureExtraction(fullFilePath,opts)
%UNTITLED Extraction and scaling of features from file
%   Detailed explanation goes here

if(nargin == 1)
    opts.PPGMean = 0.9706;
    opts.PPGSD = 0.3254;
    opts.ABPMean = 79.6121;
    opts.ABPSD = 22.2472;
    opts.sysPeakAmpMean = 1.3836;
    opts.sysPeakAmpSD = 0.1669;
    opts.diasPeakAmpMean = 0.9013;
    opts.diasPeakAmpSD = 0.2232;
    opts.feetAmplitudeMean = 0.6989;
    opts.feetAmplitudeSD = 0.1564;
    opts.heartRateMean = 45.5135;
    opts.heartRateSD = 47.1093;
    opts.respRateMean = 0.1247;
    opts.respRateSD = 0.1259;
    opts.PAMean = 30.2371;
    opts.PASD = 30.3701;
    opts.IPAMean = 0.2650;
    opts.IPASD = 0.3202;
    opts.AIMean = 0.6307;
    opts.AISD = 0.1586;
    opts.deltaTMean = 0.2904;
    opts.deltaTSD = 0.1019;
    opts.CTMean = 0.1781;
    opts.CTSD = 0.0343;
end
    
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
heart_rate = (heart_rate-opts.heartRateMean)/(3*opts.heartRateSD);
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
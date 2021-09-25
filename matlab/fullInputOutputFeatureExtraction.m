function [inputFeatures, outputFeatures] = fullInputOutputFeatureExtraction(segmentName,opts, normalisationFactorsPath)
%UNTITLED Extraction and scaling of features from file
%   Detailed explanation goes here

normFactors = load(normalisationFactorsPath);
normFactors = normFactors.normFactors;

dataFile = fopen(opts.segmented_file_dir + segmentName);
if(dataFile == -1)
    inputFeatures = [];
    fprintf("%s not found. Returning from function.", opts.segmented_file_dir+segmentName)
        return; 
end
data = cell2mat(textscan( dataFile, ...
 '%f %f %f', 'TreatAsEmpty', '-', 'EmptyValue', 0));
fclose(dataFile);

inputFeatures = containers.Map(); %using a key-value pair to store features

time = data(:,1);
abp_wave = data(:,2);
ppg_wave = data(:,3);

%*************** TIME INPUT FETAURE EXTRACTION, SCALING *****************

[sys,dias,feet] = findPPGPeaks(ppg_wave, opts.samp_freq);
sortedFeatures = sortPPGPeaks(sys, dias, feet);

systolic_peak_amplitude = mean(ppg_wave(sortedFeatures(:,2)))
systolic_peak_amplitude = (systolic_peak_amplitude-normFactors('sysPeakAmpMean'))/(normFactors('sysPeakAmpScale'));
inputFeatures('SysPeakAmp') = systolic_peak_amplitude;

diastolic_peak_amplitude = mean(ppg_wave(sortedFeatures(:,3)));
diastolic_peak_amplitude = (diastolic_peak_amplitude-normFactors('diasPeakAmpMean'))/(normFactors('diasPeakAmpScale'));
inputFeatures('DiasPeakAmp') = diastolic_peak_amplitude;

feet_amplitude = mean(ppg_wave(sortedFeatures(:,1)));
feet_amplitude = (feet_amplitude - normFactors('feetAmpMean'))/(normFactors('feetAmpScale'));
inputFeatures('feetAmp') = feet_amplitude;

heart_rate = heartRateFromPPG(sortedFeatures(:,1), sortedFeatures(:,4), opts.samp_freq);
heart_rate = (heart_rate-normFactors('HRMean'))/(normFactors('HRScale'));
inputFeatures('HR') = heart_rate;

resp_rate =  getRespiratoryRateFreq(time, ppg_wave);
resp_rate = (resp_rate-normFactors('RRMean'))/(normFactors('RRScale'));
inputFeatures('RespRate') = resp_rate;

[PA, IPA, AI] = ppgAreaAndHeightFeatures(data(:,3), sortedFeatures);
PA = (mean(PA)-normFactors('PAMean'))/(normFactors('PAScale'));
inputFeatures('PA') = PA;
IPA = (mean(IPA)-normFactors('IPAMean'))/(normFactors('IPAScale'));
inputFeatures('IPA') = IPA;
AI = (mean(AI)-normFactors('AIMean'))/(normFactors('AIScale'));
inputFeatures('AI') = AI;

deltaT = mean((sortedFeatures(:,3)-sortedFeatures(:,2))./opts.samp_freq);
deltaT = (deltaT-normFactors('deltaTMean'))/(normFactors('deltaTScale'));
inputFeatures('deltaT') = deltaT;

CT = mean((sortedFeatures(:,2)-sortedFeatures(:,1))./opts.samp_freq);
CT = (CT-normFactors('CTMean'))/(normFactors('CTScale'));
inputFeatures('CT') = CT;

%*************** FREQ INPUT FETAURE EXTRACTION, SCALING *****************

[pkIndices, pkFreqs, pkMags, pkPhases,power, bandwidth] = extractNFrequencyComponents(time, ppg_wave, opts.num_components, opts.bandwidth_criterion);
%SCALE POWER
inputFeatures('PPGPower') = power;
%SCALE BW
inputFeatures('PPGBW') = bandwidth;
%SCALE FREQ COMPONENTS
for i=1:opts.num_components
    keyName = "Freq"+num2str(i, "%03.f");
    inputFeatures(keyName) = pkFreqs(i); 
    keyName = "Mag"+num2str(i, "%03.f");
    inputFeatures(keyName) = pkMags(i);
    keyName = "Phase"+num2str(i, "%03.f");
    inputFeatures(keyName) = pkPhases(i);
end

%*************** OUTPUT FETAURE EXTRACTION, SCALING *****************
outputFeatures = containers.Map(); 
[pkIndices, pkFreqs, pkMags, pkPhases,power, bandwidth] = extractNFrequencyComponents(time, abp_wave, opts.num_components, opts.bandwidth_criterion);
%SCALE POWER
outputFeatures('ABPPower') = power;
%SCALE BW
outputFeatures('ABPBW') = bandwidth;
%SCALE FREQ COMPONENTS
for i=1:opts.num_components
    keyName = "Freq"+num2str(i, "%03.f");
    outputFeatures(keyName) = pkFreqs(i); 
    keyName = "Mag"+num2str(i, "%03.f");
    outputFeatures(keyName) = pkMags(i);
    keyName = "Phase"+num2str(i, "%03.f");
    outputFeatures(keyName) = pkPhases(i);
end

end
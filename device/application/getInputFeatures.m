function [inputFeatures] = getInputFeatures(ppg_wave, samp_freq)
%GETINPUTFEATURES Summary of this function goes here
%   Detailed explanation goes here

inputFeaturesKeyVal = containers.Map(); %using a key-value pair to store features

normFactors = load('NormalisationFactors');
normFactors = normFactors.normFactors;

[sys,dias,feet] = findPPGPeaks(ppg_wave, samp_freq);
sortedFeatures = sortPPGPeaks(sys, dias, feet);

systolic_peak_amplitude = mean(ppg_wave(sortedFeatures(:,2)));
systolic_peak_amplitude = (systolic_peak_amplitude-normFactors('sysPeakAmpMean'))/(normFactors('sysPeakAmpScale'));
inputFeaturesKeyVal('SysPeakAmp') = systolic_peak_amplitude;

diastolic_peak_amplitude = mean(ppg_wave(sortedFeatures(:,3)));
diastolic_peak_amplitude = (diastolic_peak_amplitude-normFactors('diasPeakAmpMean'))/(normFactors('diasPeakAmpScale'));
inputFeaturesKeyVal('DiasPeakAmp') = diastolic_peak_amplitude;

feet_amplitude = mean(ppg_wave(sortedFeatures(:,1)));
feet_amplitude = (feet_amplitude - normFactors('feetAmpMean'))/(normFactors('feetAmpScale'));
inputFeaturesKeyVal('feetAmp') = feet_amplitude;

heart_rate = heartRateFromPPG(sortedFeatures(:,1), sortedFeatures(:,4), samp_freq);
heart_rate = (heart_rate-normFactors('HRMean'))/(normFactors('HRScale'));
inputFeaturesKeyVal('HR') = heart_rate;

time = (0:length(ppg_wave)-1).*1/samp_freq;
resp_rate =  getRespiratoryRateFreq(time, ppg_wave);
resp_rate = (resp_rate-normFactors('RRMean'))/(normFactors('RRScale'));
inputFeaturesKeyVal('RespRate') = resp_rate;

[PA, IPA, AI] = ppgAreaAndHeightFeatures(ppg_wave, sortedFeatures);
PA = (mean(PA)-normFactors('PAMean'))/(normFactors('PAScale'));
inputFeaturesKeyVal('PA') = PA;
IPA = (mean(IPA)-normFactors('IPAMean'))/(normFactors('IPAScale'));
inputFeaturesKeyVal('IPA') = IPA;
AI = (mean(AI)-normFactors('AIMean'))/(normFactors('AIScale'));
inputFeaturesKeyVal('AI') = AI;

deltaT = mean((sortedFeatures(:,3)-sortedFeatures(:,2))./samp_freq);
deltaT = (deltaT-normFactors('deltaTMean'))/(normFactors('deltaTScale'));
inputFeaturesKeyVal('deltaT') = deltaT;

CT = mean((sortedFeatures(:,2)-sortedFeatures(:,1))./samp_freq);
CT = (CT-normFactors('CTMean'))/(normFactors('CTScale'));
inputFeaturesKeyVal('CT') = CT;

inputFeatures = zeros(1, inputFeaturesKeyVal.Count );
% allKeys = inputFeaturesKeyVal.keys;
% for i=1:inputFeaturesKeyVal.Count
%     fprintf("%s, %f \n", allKeys{i}, inputFeaturesKeyVal( allKeys{i} ) )
%     inputFeatures(i) = inputFeaturesKeyVal( allKeys{i} );
% end
% 
%  AI         CT       DiasPeakAmp      HR         IPA          PA       RespRate    SysPeakAmp     deltaT     feetAmp
inputFeatures(1) = inputFeaturesKeyVal('AI');
inputFeatures(2) = inputFeaturesKeyVal('CT');
inputFeatures(3) = inputFeaturesKeyVal('DiasPeakAmp');
inputFeatures(4) = inputFeaturesKeyVal('HR');
inputFeatures(5) = inputFeaturesKeyVal('IPA');
inputFeatures(6) = inputFeaturesKeyVal('PA');
inputFeatures(7) = inputFeaturesKeyVal('RespRate');
inputFeatures(8) = inputFeaturesKeyVal('SysPeakAmp');
inputFeatures(9) = inputFeaturesKeyVal('deltaT');
inputFeatures(10) = inputFeaturesKeyVal('feetAmp');
end


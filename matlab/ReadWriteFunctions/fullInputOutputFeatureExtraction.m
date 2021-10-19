function [inputFeatures, outputFeatures] = fullInputOutputFeatureExtraction(segmentName,opts)
%UNTITLED Extraction and scaling of features from file
%   Detailed explanation goes here

normFactors = load(opts.normalisation_file_name);
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

%*************** TIME INPUT FEATURE EXTRACTION, SCALING *****************
time_width_features = getppgfeatures(ppg_wave, opts.samp_freq);
if(isempty(time_width_features))
    return;
end

for i=1:length(time_width_features)
    inputFeatures("time"+num2str(i, '%02i')) = time_width_features(i);
end

[sys,dias,feet] = findPPGPeaks(ppg_wave, opts.samp_freq);
sortedFeatures = sortPPGPeaks(sys, dias, feet);

systolic_peak_amplitude = mean(ppg_wave(sortedFeatures(:,2)));
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


%*************** FREQ INPUT FEATURE EXTRACTION, SCALING *****************
% 
% [pkIndices, pkFreqs, pkMags, pkPhases,power, bandwidth] = extractNFrequencyComponents(time, ppg_wave, opts.num_freq_components, opts.bandwidth_criterion);
% inputFeatures('PPGPower') = power/(normFactors('PPGPower'));
% inputFeatures('PPGBW') = bandwidth/normFactors('PPGBW');
% if(numel(pkFreqs) < opts.num_freq_components); pkFreqs = zeropad(pkFreqs, opts.num_freq_components-numel(pkFreqs)+1, "post" );end
% if(numel(pkMags) < opts.num_freq_components); pkMags = zeropad(pkMags, opts.num_freq_components-numel(pkMags)+1, "post" );end
% if(numel(pkPhases) < opts.num_freq_components); pkPhases = zeropad(pkPhases, opts.num_freq_components-numel(pkPhases)+1, "post" );end
% %SCALE FREQ COMPONENTS
% % magNormFactorsPPG = normFactors('pkPPGMags');
% for i=1:opts.num_freq_components
%     keyName = "Freq"+num2str(i, "%03.f");
%     inputFeatures(keyName) = pkFreqs(i)/normFactors('FreqScalePPG'); 
%     keyName = "Mag"+num2str(i, "%03.f");
% %     inputFeatures(keyName) = pkMags(i)/magNormFactorsPPG(i);
%     inputFeatures(keyName) = pkMags(i);
%     keyName = "Phase"+num2str(i, "%03.f");
%     inputFeatures(keyName) = pkPhases(i)/pi;
% end
% 
% %*************** OUTPUT FETAURE EXTRACTION, SCALING *****************
 outputFeatures = containers.Map(); 

% [pkIndices, pkFreqs, pkMags, pkPhases,power, bandwidth] = extractNFrequencyComponents(time, abp_wave, opts.num_freq_components, opts.bandwidth_criterion);
% outputFeatures('ABPPower') = power/(normFactors('ABPPower'));
% outputFeatures('ABPBW') = bandwidth/normFactors('ABPBW');
% if(numel(pkFreqs) < opts.num_freq_components); pkFreqs = zeropad(pkFreqs, opts.num_freq_components-numel(pkFreqs)+1, "post" );end
% if(numel(pkMags) < opts.num_freq_components); pkMags = zeropad(pkMags, opts.num_freq_components-numel(pkMags)+1, "post" );end
% if(numel(pkPhases) < opts.num_freq_components); pkPhases = zeropad(pkPhases, opts.num_freq_components-numel(pkPhases)+1, "post" );end
% % magNormFactorsABP = normFactors('pkABPMags');
% %SCALE FREQ COMPONENTS
% for i=1:opts.num_freq_components
%     keyName = "Freq"+num2str(i, "%03.f");
%     outputFeatures(keyName) = pkFreqs(i)/normFactors('FreqScaleABP'); 
%     keyName = "Mag"+num2str(i, "%03.f");
% %     outputFeatures(keyName) = pkMags(i)/magNormFactorsABP(i);
%     outputFeatures(keyName) = pkMags(i);
%     keyName = "Phase"+num2str(i, "%03.f");
%     outputFeatures(keyName) = pkPhases(i)/pi;
%end

[~, ~, meanSBP, meanDBP, MAP] = findABPPeaks(data(:,2), opts.samp_freq,false,false);

outputFeatures('MeanSBP') = (meanSBP-normFactors('ABPAmpMean'))/normFactors('ABPAmpScale') ;
outputFeatures('MeanDBP') = (meanDBP-normFactors('ABPAmpMean'))/normFactors('ABPAmpScale') ;
outputFeatures('MAP') = (MAP-normFactors('ABPAmpMean'))/normFactors('ABPAmpScale') ;

end

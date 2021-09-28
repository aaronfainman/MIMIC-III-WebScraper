function [] = standaloneFindFeatureNormalisation(saveFactors, fileName)
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

addSubPaths();
opts = readOptionsStruct();

if nargin<2
    fileName='NormalisationFactors';
elseif nargin<1
    saveFactors=false;
end

%Structure of each scaling variable = [mean, variance] where each row represents
%   a different file
fileList = dir(opts.segmented_file_dir+"*.txt");
numFiles = length(fileList)
ppg = zeros(numFiles,2);
abp = zeros(numFiles,2);
systolic_peak_amplitudes = zeros(numFiles,2);
diastolic_peak_amplitudes = zeros(numFiles,2);
feet_amplitudes = zeros(numFiles,2);
%the features below will be single valued ie just store the mean and the
%variance is calculated at the end
PA = zeros(numFiles,1);
IPA = zeros(numFiles,1);
AI = zeros(numFiles,1);
deltaT = zeros(numFiles,1);
CT = zeros(numFiles,1);
heart_rate = zeros(numFiles,1);
resp_rate = zeros(numFiles,1);

pkABPFreqs = zeros(numFiles,1);
pkABPMags = zeros(numFiles,opts.num_freq_components+1);
ABPPower = zeros(numFiles,1);
ABPBW = zeros(numFiles,1);
pkPPGFreqs = zeros(numFiles,1);
pkPPGMags = zeros(numFiles,opts.num_freq_components+1);
PPGPower = zeros(numFiles,1);
PPGBW = zeros(numFiles,1);



parfor (idx = 1:numFiles)
%     fprintf('\b\b\b\b\b %i', idx)
    
     dataFile = fopen(opts.segmented_file_dir + fileList(idx).name);
     data = cell2mat(textscan( dataFile, ...
         '%f %f %f', 'TreatAsEmpty', '-', 'EmptyValue', 0));
     fclose(dataFile);
     
     abp_wave = data(:,2);
     ppg_wave = data(:,3);
     
     abp(idx,:) = [mean(abp_wave), max(abp_wave)];
     ppg(idx,:) = [mean(ppg_wave), max(ppg_wave)];
     
    [sys,dias,feet] = findPPGPeaks(ppg_wave, opts.samp_freq);
    sortedFeatures = sortPPGPeaks(sys, dias, feet);
     
%     systolic_peak_amplitudes(idx,:) = [mean(ppg_wave(sortedFeatures(:,2))), std(ppg_wave(sortedFeatures(:,2)))^2];
%     diastolic_peak_amplitudes(idx,:) = [mean(ppg_wave(sortedFeatures(:,3))), std(ppg_wave(sortedFeatures(:,3)))^2];
%     feet_amplitudes(idx,:) = [mean(ppg_wave(sortedFeatures(:,1))), std(ppg_wave(sortedFeatures(:,1)))^2];

    systolic_peak_amplitudes(idx,:) = [mean(ppg_wave(sortedFeatures(:,2))), max(ppg_wave(sortedFeatures(:,2)))];
    diastolic_peak_amplitudes(idx,:) = [mean(ppg_wave(sortedFeatures(:,3))), max(ppg_wave(sortedFeatures(:,3)))];
    feet_amplitudes(idx,:) = [mean(ppg_wave(sortedFeatures(:,1))), max(ppg_wave(sortedFeatures(:,1)))];
   
    heart_rate = [heart_rate; heartRateFromPPG(sortedFeatures(:,1), sortedFeatures(:,4), opts.samp_freq)];
    
    resp_rate = [resp_rate; getRespiratoryRateFreq(data(:,1), ppg_wave)];
    
    [currPA, currIPA, currAI] = ppgAreaAndHeightFeatures(data(:,3), sortedFeatures);
    PA(idx,:) = [mean(currPA)];
    IPA(idx,:) = [mean(currIPA)];
    AI(idx,:) = [mean(currAI)];
    deltaT(idx,:) = [mean((sortedFeatures(:,3)-sortedFeatures(:,2))./opts.samp_freq)];
    CT(idx,:) = [mean((sortedFeatures(:,2)-sortedFeatures(:,1))./opts.samp_freq)];

    [pkIndices, pkFreqsCurr, pkMags, pkPhases,power, bandwidth] = extractNFrequencyComponents(data(:,1), data(:,2), opts.num_freq_components, opts.bandwidth_criterion);
    pkABPFreqs(idx, :) = max(pkFreqsCurr);
    if(numel(pkMags) < opts.num_freq_components)
        pkMags = zeropad(pkMags, opts.num_freq_components-numel(pkMags)+1, "post" );
    end
    pkABPMags(idx, :) = pkMags';
    ABPPower(idx, :) = power;
    ABPBW(idx,:) = bandwidth;

    [pkIndices, pkFreqsCurr, pkMags, pkPhases,power, bandwidth] = extractNFrequencyComponents(data(:,1), data(:,3), opts.num_freq_components, opts.bandwidth_criterion);
    pkPPGFreqs(idx, :) = max(pkFreqsCurr);
    if(numel(pkMags) < opts.num_freq_components)
        pkMags = zeropad(pkMags, opts.num_freq_components-numel(pkMags)+1,"post" );
    end
    pkPPGMags(idx, :) = pkMags';
    PPGPower(idx, :) = power;
    PPGBW(idx,:) = bandwidth;

end

normFactors = containers.Map();
normFactors('PPGAmpMean') = mean(ppg(:,1));
normFactors('PPGAmpScale') = max(ppg(:,2))-mean(ppg(:,1));
normFactors('ABPAmpMean') = mean(abp(:,1));
normFactors('ABPAmpScale') = max(abp(:,2))-mean(abp(:,1));
normFactors('sysPeakAmpMean') = mean(systolic_peak_amplitudes(:,1));
normFactors('sysPeakAmpScale') = max(systolic_peak_amplitudes(:,2))-mean(systolic_peak_amplitudes(:,1));
normFactors('diasPeakAmpMean') = mean(diastolic_peak_amplitudes(:,1));
normFactors('diasPeakAmpScale') = max(diastolic_peak_amplitudes(:,2))-mean(diastolic_peak_amplitudes(:,1));
normFactors('feetAmpMean') = mean(feet_amplitudes(:,1));
normFactors('feetAmpScale') = max(feet_amplitudes(:,2))-mean(feet_amplitudes(:,1));;
%the features below will be single valued ie just store the mean and the
%variance is calculated at the end
normFactors('PAMean') = mean(PA) ;
normFactors('PAScale') = max(PA)-mean(PA);
normFactors('IPAMean') = mean(IPA) ;
normFactors('IPAScale') = max(IPA)-mean(IPA);
normFactors('AIMean') = mean(AI) ;
normFactors('AIScale') = max(AI)-mean(AI);
normFactors('deltaTMean') = mean(deltaT);
normFactors('deltaTScale')=   max(deltaT)-mean(deltaT);
normFactors('CTMean') = mean(CT);
normFactors('CTScale') = max(CT)- mean(CT);
normFactors('HRMean') = mean(heart_rate);
normFactors('HRScale') = max(heart_rate)-mean(heart_rate);
normFactors('RRMean') = mean(resp_rate);
normFactors('RRScale') = max(resp_rate)-mean(resp_rate);

normFactors('FreqScalePPG') = max(pkPPGFreqs); 
normFactors('FreqScaleABP') = max(pkABPFreqs);
normFactors('PPGPower') = max(PPGPower); 
normFactors('ABPPower') = max(ABPPower);
normFactors('PPGBW') = max(PPGBW); 
normFactors('ABPBW') = max(ABPBW);
normFactors('pkPPGMags') = [max(pkPPGMags)];
normFactors('pkABPMags') = [max(pkABPMags)];


if saveFactors
    save(fileName, 'normFactors')
end

end
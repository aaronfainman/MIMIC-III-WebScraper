function [sysPts, diasPts, meanSBP, meanDBP, MAP] = findBAPPeaks(abp_wave,samp_freq)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

abp_wave_norm = normalize(abp_wave);
%Chowdhury: Esimating blood pressure from the photoplethysmogram ... p.6
%   uses a zero phase IIR butterworth filter, 6th order with fc=25 Hz
filt_design = designfilt('lowpassiir','FilterOrder',6, ...
    'HalfPowerFrequency',30/samp_freq,'DesignMethod','butter');
abp_wave_norm = filtfilt(filt_design, abp_wave_norm);

sysPts = find(islocalmax(abp_wave_norm, 'MinSeparation', 60)==1);

diasPts = find( islocalmin(abp_wave_norm,'MinSeparation', 60)==1);

meanSBP = mean(abp_wave(sysPts));
meanDBP = mean(abp_wave(diasPts));
MAP = mean(abp_wave(sysPts(1):sysPts(end)));

end


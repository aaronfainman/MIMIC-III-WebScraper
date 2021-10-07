function [sysPts, diasPts, meanSBP, meanDBP, MAP] = findBAPPeaks(abp_wave,samp_freq, must_normalize, must_filter)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if(nargin==2 || must_normalize); abp_wave = normalize(abp_wave); end;
%Chowdhury: Esimating blood pressure from the photoplethysmogram ... p.6
%   uses a zero phase IIR butterworth filter, 6th order with fc=25 Hz
if(nargin==2 || must_filter)
    filt_design = designfilt('lowpassiir','FilterOrder',6, ...
        'HalfPowerFrequency',30/samp_freq,'DesignMethod','butter');
    abp_wave = filtfilt(filt_design, abp_wave);
end

sysPts = [];diasPts=[];meanSBP=[]; meanDBP=[];MAP=[];
sysPts = find(islocalmax(abp_wave, 'MinSeparation', 60)==1);
if(isempty(sysPts)); return; end;
diasPts = find( islocalmin(abp_wave,'MinSeparation', 60)==1);
if(isempty(diasPts)); return; end;

meanSBP = mean(abp_wave(sysPts));
meanDBP = mean(abp_wave(diasPts));
MAP = mean(abp_wave(sysPts(1):sysPts(end)));

end


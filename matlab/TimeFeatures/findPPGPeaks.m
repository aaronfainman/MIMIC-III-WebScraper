function [systolicPeakLocs, diastolicPeakLocs, feetLocs] = findPPGPeaks(ppg_wave, samp_freq)
%FINDSYSTOLICPEAKS Summary of this function goes here
%   Detailed explanation goes here

ppg_wave = normalize(ppg_wave);
%Chowdhury: Esimating blood pressure from the photoplethysmogram ... p.6
%   uses a zero phase IIR butterworth filter, 6th order with fc=25 Hz
filt_design = designfilt('lowpassiir','FilterOrder',6, ...
    'HalfPowerFrequency',30/samp_freq,'DesignMethod','butter');
ppg_wave = filtfilt(filt_design, ppg_wave);

diff_signal = diff(ppg_wave);

[pks, pk_idx] = findpeaks(diff_signal, 'MinPeakHeight', 0.08, 'MinPeakDistance', 30);

systolicPeakLocs = [];
numSysPeaks = 0;
diastolicPeakLocs = [];
numDiasPeaks = 0;
feetLocs = [];
numFeet = 0;


for i=1:length(pks)-1
    band = [pk_idx(i), pk_idx(i+1)];
    
    systolicLocation = find(diff_signal(band(1):band(2))<0, 1);
    if(isempty(systolicLocation)); continue; end;
    systolicLocation = systolicLocation - 1 + band(1);
    
    numSysPeaks =  numSysPeaks+1;
    systolicPeakLocs(numSysPeaks) = systolicLocation;
    
    
    % moving backwards in derivative signal, foot is where derivative moves
    % from positive to negative and is usually the last turning point
    % before the steep rise to systolic peak
    footLocation = find(diff_signal( band(2)-5:-1:band(1))<0,1);
    if(isempty(footLocation)); continue; end;
    footLocation = band(2)-footLocation+1-5+1;
    
    numFeet = numFeet+1;
    feetLocs(numFeet) = footLocation;
    
    %Finding the diastolic peak: all possible locations between systolic
    %peak and foot are considered. These locations are local minima in the
    %second derivative of the signal (M. Elgendi, On the analysis of
    %fingertip photoplethysmogram signals p. 6). A scoring matrix is then
    %used to find the highest point in the PPG with the flattest
    %derivative. Something worth exploring is the movvar of the ppg signal
    sec_diff_signal = diff(diff_signal(systolicLocation+5:footLocation));
    

    potDiastolicLocs = find(islocalmin(sec_diff_signal));
    if(isempty(potDiastolicLocs)); continue; end;
    potDiastolicLocs = potDiastolicLocs + systolicLocation+5;
    
    score = [potDiastolicLocs, abs(diff_signal(potDiastolicLocs)),abs(sec_diff_signal(potDiastolicLocs-systolicLocation-5)), ppg_wave(potDiastolicLocs)];
    
    score(:,2:end) = [normalize(score(:,2:end), 'range')];
    
    score(:,5) = (1-score(:,2))+0.1.*(1-score(:,3))+score(:,4);
    
    [~,best_score_idx] = max(score(:,5));
    
    diastolicLocation = score(best_score_idx, 1);


    numDiasPeaks = numDiasPeaks+1;
    diastolicPeakLocs(numDiasPeaks) = diastolicLocation;
     
end



end


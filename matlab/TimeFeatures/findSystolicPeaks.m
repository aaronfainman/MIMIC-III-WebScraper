function [systolicPeakLocs, diastolicPeakLocs, feetLocs] = findSystolicPeaks(ppg_wave)
%FINDSYSTOLICPEAKS Summary of this function goes here
%   Detailed explanation goes here

ppg_wave = normalize(ppg_wave);

diff_signal = movmean(diff(ppg_wave),10);

[pks, pk_idx] = findpeaks(diff_signal, 'MinPeakHeight', 0.08, 'MinPeakDistance', 30);

systolicPeakLocs = [];
numSysPeaks = 0;
diastolicPeakLocs = [];
numDiasPeaks = 0;
feetLocs = [];
numFeet = 0;

figure;hold on;
for i=1:length(pks)-1
    band = [pk_idx(i), pk_idx(i+1)];
    
    systolicLocation = find(diff_signal(band(1):band(2))<0, 1);
    if(isempty(systolicLocation)); continue; end;
    systolicLocation = systolicLocation - 1 + band(1);
    
    numSysPeaks =  numSysPeaks+1;
    systolicPeakLocs(numSysPeaks) = systolicLocation;
    
    
    % moving backwards in derivative signal, foot is where derivative moves
    % from positive to negative. We move backwards because it is easier to
    % avoid working out whether the diacrotic nothc is present or not
    footLocation = find(diff_signal( band(2)-5:-1:band(1))<0,1);
    if(isempty(footLocation)); continue; end;
    footLocation = band(2)-footLocation+1-5;
    
    numFeet = numFeet+1;
    feetLocs(numFeet) = footLocation;
    
    %Elgendi: diastolic peak has a negative peak in second deriv
    sec_diff_signal = diff(diff_signal(systolicLocation+10:footLocation));
    
    potDiastolicLocs = find(islocalmin(sec_diff_signal)==1);
    [~, diastolicLocation] = mink(sec_diff_signal(potDiastolicLocs),2);
    diastolicLocation = diastolicLocation(2) + systolicLocation+10;
%     (abs(diff_signal(systolicLocation+10:footLocation))<2e-2);%.*ppg_wave(systolicLocation:footLocation);
    
%     clf
%     plot(ppg_wave)
%     hold on
% %     plot(10.*abs(diff_signal))
%     scatter(potDiastolicLocs, ppg_wave(potDiastolicLocs));

%      % moving backwards in derivative signal, foot is where derivative moves
%     % from negative to positive to negative
%      diastolicLocation = find(diff_sig(footLocation-1:-1:band(1))<0,1);
     if(isempty(diastolicLocation)); continue; end;
%      diastolicLocation = footLocation - diastolicLocation;
%      
     numDiasPeaks = numDiasPeaks+1;
     diastolicPeakLocs(numDiasPeaks) = diastolicLocation;
     
end

% beats =find( islocalmax(diff_sig, 'MinSeparation', 30)==1);
% 
clf
t = 1:length(ppg_wave);
plot(t(1:end),ppg_wave)
hold on
% % plot(t(1:end-1),10.*diff_sig)%ppg_wave)
% 
scatter(t(systolicPeakLocs), ppg_wave(systolicPeakLocs), 'LineWidth',2);
scatter(t(feetLocs), ppg_wave(feetLocs), 'x', 'LineWidth',2);
scatter(t(diastolicPeakLocs), ppg_wave(diastolicPeakLocs), 's', 'LineWidth',2);
% 
% scatter(t(beats), diff_sig(beats), 'x');

diastolicPeakLocs

end

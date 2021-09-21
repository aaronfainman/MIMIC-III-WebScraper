function [systolicPeakLocs] = findSystolicPeaks(ppg_wave)
%FINDSYSTOLICPEAKS Summary of this function goes here
%   Detailed explanation goes here

diff_sig = movmean(diff(ppg_wave),10);

[pks, pk_idx] = findpeaks(diff_sig, 'MinPeakHeight', 0.002, 'MinPeakDistance', 30);

systolicPeakLocs = [];
numSysPeaks = 0;

for i=1:length(pks)-1
    band = [pk_idx(i), pk_idx(i+1)];
    
    sysLoc = find(diff_sig(band(1):band(2))<0, 1) - 1 + band(1);
    if(isempty(sysLoc)); continue; end;
    
    numSysPeaks =  numSysPeaks+1;
    
    systolicPeakLocs(numSysPeaks) = sysLoc;
end

clf
t = 1:length(ppg_wave);
plot(t,ppg_wave)
hold on
scatter(t(systolicPeakLocs), ppg_wave(systolicPeakLocs));

end


function [amplitude_pts, mean_amp, dev_amp, max_amp, min_amp] = peakAmplitudes(ppg_wave,samp_freq, feature)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if strcmp(lower(feature), 'systolic')
    amplitude_pts = ppg_wave( beatLocsFromPPG(ppg_wave, 220,samp_freq, 'systolic'));
else
    amplitude_pts = ppg_wave( beatLocsFromPPG(ppg_wave, 220,samp_freq, 'diastolic'));
end

mean_amp = mean(amplitude_pts);
dev_amp = std(amplitude_pts);
min_amp = min(amplitude_pts);
max_amp = max(amplitude_pts);

end


function [avg_hr, max_hr, most_recent_hr] = heartRateFromBeatLocs(beat_locs, sampling_rate)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

hr_bpm = 60./(diff(beat_locs)./sampling_rate);

avg_hr = mean(hr_bpm);
max_hr = max(hr_bpm);
most_recent_hr = hr_bpm(end);

end

function [avg_hr, max_hr, most_recent_hr] = heartRate(segment_name, abp_segment_dir, sampling_rate)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

segment_name = char(segment_name);

abp_beat_locs = importdata(abp_segment_dir+string(segment_name(1:17))+"b.txt");

hr_bpm = 60./(diff(abp_beat_locs)./sampling_rate);

avg_hr = mean(hr_bpm);
max_hr = max(hr_bpm);
most_recent_hr = hr_bpm(end);

end


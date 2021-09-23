function [avg_hr, max_hr, most_recent_hr] = heartRateFromPPG(first_ppg_feet, last_ppg_feet, sampling_rate)
%HR: gets estimate of HR from feet of ppg waveform
%   Detailed explanation goes here

foot_to_foot_interval = last_ppg_feet - first_ppg_feet;
hr_bpm = 60./(foot_to_foot_interval./sampling_rate);

avg_hr = mean(hr_bpm);
max_hr = max(hr_bpm);
most_recent_hr = hr_bpm(end);

end


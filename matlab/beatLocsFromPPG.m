function beat_locs = beatLocsFromPPG(ppg_wave, max_hr_bpm, sampling_rate)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

if(nargin==1)
    max_hr_bpm = 220
    sampling_rate = 125;
end

%double the max hr set since this will be used for filtering and must be
%   doubled based off of Nyquist's criterion
max_hr_bpm = 2*max_hr_bpm;

%Find the minimum number of indices that separates each beat
% 1/(beats/s) gives min time between beats in seconds * sampling rate 
%       to give min number of indices
min_sep_btwn_beats = round(1/(220/60)*sampling_rate); 

filt_ppg_wave = movmean(ppg_wave, min_sep_btwn_beats);

beats = islocalmin(filt_ppg_wave,'MinSeparation', min_sep_btwn_beats);

beat_locs = find(beats==1);

end


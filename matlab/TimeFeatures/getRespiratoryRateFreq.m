function [resp_rate] = getRespiratoryRateFreq(time,ppg_wave)
%UNTITLED4 Return respiratory rate in Hz
%   Detailed explanation goes here

%Approach 2: take fft and find frequency indices between 0.05 and 0.47 Hz
%   find frequency with max component in that interval by using max
%   component or a weighted average
[freq,ppg_fft] = singlesidedFFT( time,ppg_wave);
start_idx = find(freq>=0.05, 1);
end_idx = find(freq>=0.47, 1)-1;

%This code gives the maximum frequency component in that band
% [~,freq_resp_idx] = max(ppg_fft(start_idx:end_idx));
% resp_rate = freq(freq_resp_idx);

%This gives the weighted avergae frequency in the band of interest
resp_rate = freq(start_idx:end_idx)*abs(ppg_fft(start_idx:end_idx))/sum(abs(ppg_fft(start_idx:end_idx)));




% %Approach 2: moving average filter capture slowly varying baseline sinusoid
% %-> envelope -> freq estimation
% min_samples_space = round(1/(2*cutoff_freq)*samp_freq)
% 
% ppg_filt = movmean(ppg_wave, 2*min_samples_space);
% 
% [~,resp_wave] = envelope(ppg_filt, min_samples_space,'peak');
% 
% %find peaks (maxima) of respiratory rate wave to estimate resp rate
% resp_max_locs = find(islocalmax(resp_wave, 'MinSeparation', min_samples_space)==1)
% 
% %resp period (s/beat) is time difference between beat maxima divided by
% %samp freq. Respiratory rate is inverse of this
% 
% resp_rate = samp_freq/mean(diff(resp_max_locs));
% 
% if( isnan(resp_rate))
%      %assume no resp signal isolated because rate varies too slowly
%     resp_rate = -1;
% end

end


function [freqVector, freqSpectrum] = singlesidedFFT(timeVector, timeSignal)
   n = length(timeVector);
   dT = mean(diff(timeVector));
   df = 1/dT;
   %freqVector = (-n/2:(n/2-1))* (df/n);
   freqVector = (0:(n/2 -1)) * (df/n);
   freqSpectrum = fft(timeSignal)/df;
   freqSpectrum(round(n/2+1) : end) = [];
   freqSpectrum(2:end) = freqSpectrum(2:end) * 2;
end


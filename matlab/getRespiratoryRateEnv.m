function [resp_rate] = getRespiratoryRateEnv(ppg_wave, samp_freq, cutoff_freq)

%Approach 2: moving average filter capture slowly varying baseline sinusoid
%-> envelope -> freq estimation
min_samples_space = round(1/(2*cutoff_freq)*samp_freq);

ppg_filt = movmean(ppg_wave, 2*min_samples_space);

[~,resp_wave] = envelope(ppg_filt, min_samples_space,'peak');

%find peaks (maxima) of respiratory rate wave to estimate resp rate
resp_max_locs = find(islocalmax(resp_wave, 'MinSeparation', min_samples_space)==1);

%resp period (s/beat) is time difference between beat maxima divided by
%samp freq. Respiratory rate is inverse of this

resp_rate = samp_freq/mean(diff(resp_max_locs));

if( isnan(resp_rate))
     %assume no resp signal isolated because rate varies too slowly
    resp_rate = -1;
end

end
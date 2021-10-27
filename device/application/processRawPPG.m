function [ppg_sig] = processRawPPG(ppg_sig, ppgSF, ppgMF, ppgScale, ppgMean)
%PROCESSRAWPPG Summary of this function goes here
%   Detailed explanation goes here


%filt_design = designfilt('bandpassiir','FilterOrder',2, ...
%    'HalfPowerFrequency1',[0.1/125 5/125],'DesignMethod','butter');

filt_design = designfilt('bandpassiir','FilterOrder',4, ...
         'HalfPowerFrequency1',0.3,'HalfPowerFrequency2',5, ...
         'SampleRate',125);


ppg_sig = filter(filt_design, ppg_sig);
ppg_sig = min(3, max(-2, ppg_sig));
%ppg_sig = hampel(ppg_sig, 125);

ppg_sig = movmean(ppg_sig, 5);
%ppg_sig = -1.*ppg_sig+3;

if nargin > 1
    %ppg_sig = (ppg_sig - mean(ppg_sig))*(ppgScale/ppgSF) + (ppgMean/ppgMF)*mean(ppg_sig);
    ppg_sig = (ppg_sig - mean(ppg_sig))*(ppgScale/range(ppg_sig)) + ppgMean;
    
end


ppg_flats = findFlatRegionsFast(ppg_sig, 0.004,400, 0.4); 

[ppg_regions, num_reg] = removeInvalidFromPPG(ppg_flats, 375, ppg_sig);
if(isempty(ppg_regions))
    ppg_sig = [];
    return;
end

longest = 0;
longest_idx = 0;
%find longest region
for i=1:width(ppg_regions)
    if( height(ppg_regions{i}{1}{1}) > longest )
        longest =  height(ppg_regions{i}{1}{1});
        longest_idx = i;
    end
end
ppg_sig = ppg_regions{longest_idx}{1}{1};

end


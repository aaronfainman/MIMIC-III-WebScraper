function [pearsonCorrCoeff, timeDiff, ppg_shift, abp_shift, t_shift] = checkCorrelation(t, abp, ppg)

Ts = mean(diff(t));

[~,~, timeDiff] = crossCorrelation(t, abp, ppg);

shift = round(timeDiff/Ts);

if (shift > 0)
    ppg_shift = ppg(shift:end);
    abp_shift = abp(1:length(ppg_shift));
    t_shift = t(1:length(ppg_shift));
elseif (shift < 0)
    abp_shift = abp(-shift:end);
    ppg_shift = ppg(1:length(abp_shift));
    t_shift = t(1:length(abp_shift));
end

pearsonCorrCoeff = pearsonCoeff(ppg_shift, abp_shift);



end


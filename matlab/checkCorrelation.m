function [pearsonCorrCoeff, timeShift] = checkCorrelation(t, abp, ppg)

Ts = mean(diff(t));

[~,~, timeShift] = crossCorrelation(t, abp, ppg);

shift = round(timeShift/Ts);

if (shift > 0)
    ppg_ = ppg(shift:end);
    abp_ = abp(1:length(ppg_));
elseif (shift < 0)
    abp_ = abp(-shift:end);
    ppg_ = ppg(1:length(abp_));
end

pearsonCorrCoeff = pearsonCoeff(ppg_, abp_);

end


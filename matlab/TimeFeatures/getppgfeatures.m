function [features] = getppgfeatures(ppg, Ts)

[sbpPks, dbpPks, feetLocs] = findPPGPeaks(ppg, Ts);

if (isempty(sbpPks)|| isempty(feetLocs))
    features = [];
    return
end

if (sbpPks(1) < feetLocs(1))
    sbpPks(1) = [];
end

if (length(feetLocs) > length(sbpPks)+1)
    feetLocs(length(sbpPks)+2:end) = [];
end

if (length(sbpPks) == length(feetLocs))
    sbpPks(end) = [];
end

if (isempty(sbpPks)|| isempty(feetLocs))
    features = [];
    return
end

if (length(sbpPks)~=(length(feetLocs)-1))
    features = [];
    return
end

cardiac_period = mean(diff(feetLocs))*Ts;

sys_uptime = sbpPks - feetLocs(1:end-1);
sys_uptime = mean(sys_uptime)*Ts;

dias_time = feetLocs(2:end) - sbpPks;
dias_time = mean(dias_time)*Ts;

numCycles = length(sbpPks);

t = (0:(length(ppg) - 1)) * Ts;

pVals = [0.1, 0.25, 0.33, 0.5, 0.67, 0.75, 0.9];

sd_width_vals = zeros(numCycles, length(pVals)*2);

width_vals = zeros(numCycles,length(pVals));

width_ratios = zeros(numCycles,length(pVals));

for i=1:numCycles
    ppg_i = ppg(feetLocs(i):feetLocs(i+1)-1);

    sys_half = ppg_i(1:(sbpPks(i)-feetLocs(i)));

    sys_half = sys_half - min(sys_half);

    dias_half = ppg_i(sbpPks(i)-feetLocs(i)+1:end);

    dias_half = dias_half - min(dias_half);

    sys_h = range(sys_half);
    dias_h = range(dias_half);

    for p = 1:length(pVals)
        [~,sid] = min(abs(sys_half-pVals(p)*sys_h));
        sw = t(sbpPks(i)) - t(feetLocs(i)+sid);

        [~,did] = min(abs(dias_half-pVals(p)*dias_h));
	dw = t(feetLocs(i)+did) - t(sbpPks(i));

        sd_width_vals(i, p*2-1) = sw;
        sd_width_vals(i, p*2) = dw;

        width_vals(i, p) = sw+dw;

        width_ratios(i, p) = dw/sw;
    end
end

sd_width_vals = mean(sd_width_vals,1);
width_vals = mean(width_vals,1);
width_ratios = mean(width_ratios,1);

features = [cardiac_period, sys_uptime, dias_time, ...
    sd_width_vals, width_vals, width_ratios];

end

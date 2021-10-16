function [features] = getppgfeatures(ppg, Ts)

[sbpPks, dbpPks, feetLocs] = findPPGPeaks(ppg, Ts);

if (sbpPks(1) < feetLocs(1))
    sbpPks(1) = [];
    dbpPks(1) = [];
end

if (length(feetLocs) > length(sbpPks)+1)
    feetLocs(length(sbpPks)+2:end) = [];
end

if (length(sbpPks) == length(feetLocs))
    sbpPks(end) = [];
end
if (length(dbpPks) == length(feetLocs))
    dbpPks(end) = [];
end

cardiac_period = mean(diff(feetLocs))*Ts;

sys_uptime = sbpPks - feetLocs(1:end-1);
sys_uptime = mean(sys_uptime)*Ts;

dias_time = feetLocs(2:end) - dbpPks;
dias_time = mean(dias_time)*Ts;

numCycles = length(sbpPks);

t = (0:(length(ppg) - 1)) * Ts;

pVals = [0.1, 0.25, 0.33, 0.5, 0.67, 0.75, 0.9];

sd_width_vals = zeros(numCycles, length(pVals)*2);

width_vals = zeros(numCycles,length(pVals));

width_ratios = zeros(numCycles,length(pVals));

for i=1:numCycles
    ppg_i = ppg(feetLocs(i):feetLocs(i+1)-1);
    
    h = ppg(sbpPks(i))- ppg(feetLocs(i));

    ppg_i = ppg_i - ppg_i(1);

    sys_half = ppg_i(1:(sbpPks(i)-feetLocs(i)));
    dias_half = ppg_i(sbpPks(i)-feetLocs(i)+1:end);

    for p = 1:length(pVals)
        idx = find(abs(sys_half-pVals(p)*h) < 0.005);
        sw = t(feetLocs(i)+sbpPks(i)) - t(feetLocs(i)+idx(1));

        idx = find(abs(dias_half-pVals(p)*h) < 0.005);
        dw = t(feetLocs(i)+idx(1)) - t(feetLocs(i)+sbpPks(i));

        sd_width_vals(i, p*2-1) = sw;
        sd_width_vals(i, p*2) = dw;

        width_vals(i, p) = sw+dw;

        width_ratios(i, p) = dw/sw;
    end
end

sd_width_vals = mean(sd_width_vals);
width_vals = mean(width_vals);
width_ratios = mean(width_ratios);

features = [cardiac_period, sys_uptime, dias_time, ...
    sd_width_vals, width_vals, width_ratios];

end
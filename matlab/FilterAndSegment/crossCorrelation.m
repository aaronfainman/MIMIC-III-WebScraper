function [g, T, shiftT] = crossCorrelation(t, abp, ppg)
% Computes the cross correlation between the two signals. Allows for the
% lag/lead to be quantified. The maximum peak of the cross corr signal
% shows the time delay.
% See Harfiya et al. for more.
L = length(t);
Ts = mean(diff(t));

if mod(L,2) == 0
    t = (-L/2):(L/2-1) * Ts;
else
    t = (-(L-1)/2):((L-1)/2) * Ts;
end

T = (-3:Ts:3)';
n = length(T);

g = zeros(size(T));

i0 = find(t==0);

w = round((n-1)/2);

ABP = abp(i0-w:i0+w);
    
for i = 1:length(T)
    nT = round(T(i)/Ts);
    shiftPPG = ppg(i0-w+nT:i0+w+nT);
    corr = ABP.*shiftPPG;
    
    g(i) = sum(corr);
end

[~, maxLoc] = max(g);

shiftT = T(maxLoc);

end


function pwrCont = getPowerContributors(ssPSD, percent, onlyPeaks)

[~, maxInd] = sort(ssPSD, 'desc');

if onlyPeaks
    localMaxima = islocalmax(ssPSD);
    localMaxima(1) = 1;
    localMaxima = localMaxima(maxInd);
    maxInd(~localMaxima) = [];
end


totalPower = sum(ssPSD);
pwr = 0;
i = 0;
while (pwr/totalPower < percent/100)
    i = i+1;
    pwr = pwr + ssPSD(maxInd(i));
end

pwrCont = maxInd(1:i);



end


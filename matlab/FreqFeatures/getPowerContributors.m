function pwrCont = getPowerContributors(ssPSD, percent)

[~, maxInd] = sort(ssPSD, 'desc');

totalPower = sum(ssPSD);
pwr = 0;
i = 0;
while (pwr/totalPower < percent/100)
    i = i+1;
    pwr = pwr + ssPSD(maxInd(i));
end

pwrCont = maxInd(1:i);



end


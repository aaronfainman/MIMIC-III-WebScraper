function abpWave = predictABP(ppgWave, nnets, normVals)

abpPred = predict(nnets.wave,ppgWave);

sbp = predict(nnets.sbp, ppgFeats).*normVals(1) + normVals(2);

dbp = predict(nnets.dbp, ppgFeats).*normVals(1) + normVals(2);

mapVal = predict(nnets.map, ppgFeats).*normVals(1) + normVals(2);

mapApprox = (sbp+2*dbp)/3;

if (abs(mapVal-mapApprox)/mapApprox < 0.1)
    map = mapVal;
else
    map = mapApprox;
end

irange = range(abpPred);
imean = mean(abpPred);

abpWave = (abpPred-imean)*((sbp-dbp)/irange) + map;

%abpWave = filtfilt(filt, abpWave);

end


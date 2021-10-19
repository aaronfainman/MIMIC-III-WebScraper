function [abpWave, sbp, dbp, map] = predictABP(ppgWave, nnets)

abpPred = predict(nnets.wave,ppgWave);

ppgFeats = getInputFeatures(ppgWave, 125);



sbp = predict(nnets.sbp, ppgFeats).*nnets.abpScale + nnets.abpMean;

dbp = predict(nnets.dbp, ppgFeats).*nnets.abpScale + nnets.abpMean;

map = predict(nnets.map, ppgFeats).*nnets.abpScale + nnets.abpMean;

mapApprox = (sbp+2*dbp)/3;

if (abs(map-mapApprox)/mapApprox < 0.1)
    map = map;
else
    map = mapApprox;
end

irange = range(abpPred);
imean = mean(abpPred);

abpWave = (abpPred-imean)*((sbp-dbp)/irange) + map;

%abpWave = filtfilt(filt, abpWave);

end


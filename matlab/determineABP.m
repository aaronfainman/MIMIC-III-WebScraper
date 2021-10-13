function abpWave = determineABP(ppgWave, nnetWave, nnetBP, normVals)

% Once 2nd NNET is done we can have 2 nnet options and not pass in the
% triple

abpPred = predict(nnetWave,ppgWave);

bpVals = predict(nnetBP, ppgWave').*normVals(1) + normVals(2);

sbp = bpVals(1);
dbp = bpVals(2);

mapVal = bpVals(3);
mapApprox = (sbp+2*dbp)/3;

if (abs(mapVal-mapApprox)/mapApprox > 0.9)
    map = mapVal;
else
    map = mapApprox;
end

irange = range(abpPred);
imean = mean(abpPred);

abpWave = (abpPred-imean)*((sbp-dbp)/irange) + map;

%abpWave = filtfilt(filt, abpWave);

end


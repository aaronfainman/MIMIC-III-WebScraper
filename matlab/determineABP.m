function abpWave = determineABP(ppgWave, sbp, dbp, map, nnet, filt)

% Once 2nd NNET is done we can have 2 nnet options and not pass in the
% triple

abpPred = predict(nnet,ppgWave);

irange = range(abpPred);
imean = mean(abpPred);

abpWave = (abpPred-imean)*((sbp-dbp)/irange) + map;

abpWave = filtfilt(filt, abpWave);

end


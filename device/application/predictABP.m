function [abpWave, sbp, dbp, map] = predictABP(ppgWave, nnets, isNorm)

if (~isNorm)
    ppgWaveNorm = (ppgWave-nnets.ppgMean)./nnets.ppgScale;
else
    ppgWaveNorm = ppgWave;
end

abpPred = predict(nnets.wave,ppgWaveNorm);

if (isNorm)
    ppgWaveDenorm = ppgWave.*nnets.ppgScale + nnets.ppgMean;
else
    ppgWaveDenorm = ppgWave;
end

%ppgProcessed = processRawPPG(ppgWaveDenorm);
% ppgProcessed = ppgWaveDenorm;
% 
% if isempty(ppgProcessed)
%     abpWave = [];
%     sbp = 0;
%     dbp = 0;
%     map = 0;
%     return;
% end


ppgFeats = getInputFeatures(ppgWaveDenorm, 125);


if isempty(ppgFeats)
    abpWave = [];
    sbp = 0;
    dbp = 0;
    map = 0;
    return;
end

sbp = predict(nnets.sbp, ppgFeats).*nnets.abpScale + nnets.abpMean;

dbp = predict(nnets.dbp, ppgFeats).*nnets.abpScale + nnets.abpMean;

map = predict(nnets.map, ppgFeats).*nnets.abpScale + nnets.abpMean;

mapApprox = (sbp+2*dbp)/3;

if (abs(map-mapApprox)/mapApprox < 0.05)
    map = map;
else
    map = mapApprox;
end

irange = range(abpPred);
imean = mean(abpPred);

abpWave = (abpPred-imean)*((sbp-dbp)/irange) + map;

%abpWave = filtfilt(filt, abpWave);

end


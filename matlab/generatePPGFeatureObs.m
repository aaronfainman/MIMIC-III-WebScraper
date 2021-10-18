function generatePPGFeatureObs(dataFileName)

addSubPaths();

disp('Reading data from mat file...');
dataMatFile = load(dataFileName);

ppgData = dataMatFile.inputFeats;

% [SBP, DBP, MAP]
abpVals = dataMatFile.outputFeatsBP;

normFactors = dataMatFile.normFactors;

ppgMean = normFactors('PPGAmpMean');
ppgRange = normFactors('PPGAmpScale');
abpMean = normFactors('ABPAmpMean');
abpRange = normFactors('ABPAmpScale');

trainingIndices = dataMatFile.trainingIndices;
testIndices = dataMatFile.testIndices;
validIndices = dataMatFile.validIndices;

startId = 876;
endId = 1250;

Fs = 125;

numFeats = length(getppgfeatures(ppgData(1, startId:endId), Fs));

ppgFeats = zeros(height(ppgData), numFeats);

parfor k = 1:height(ppgData)
    feats_k = getppgfeatures(ppgData(k, startId:endId), Fs);
    if (isempty(feats_k))
        ppgFeats(k,:) = zeros(1, numFeats);
    else
        ppgFeats(k,:) = feats_k;
    end
end

invalid = ismember(ppgFeats, zeros(1, numFeats), 'rows');

zeroMat = zeros(height(ppgData),1);

ppgFeats(invalid, :) = [];
abpVals(invalid, :) = [];

ids = zeroMat;
ids(trainingIndices) = true;
trainingIndices = ids;

ids = zeroMat;
ids(testIndices) = true;
testIndices = ids;

ids = zeroMat;
ids(validIndices) = true;
validIndices = ids;

testIndices(invalid) = [];
trainingIndices(invalid) = [];
validIndices(invalid) = [];

trainingIndices = logical(trainingIndices);
testIndices = logical(testIndices);
validIndices = logical(validIndices);

normFactors = struct;
normFactors.abpMean = abpMean;
normFactors.abpRange = abpRange;
normFactors.ppgMean = ppgMean;
normFactors.ppgRange = ppgRange;


save('widthFeatureObservations.mat', 'ppgFeats', 'abpVals', 'normFactors', 'testIndices', 'trainingIndices', 'validIndices');

end

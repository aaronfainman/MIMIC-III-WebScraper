function [outputArg1,outputArg2] = generatePPGFeatureObs(dataFileName)

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

startId = 1001;
endId = 1250;

Ts = 125;

numFeats = length(getppgfeatures(ppgData(1, startId:endId), Ts));

ppgFeats = zeros(height(ppgData), numFeats);

parfor i = 1:height(ppgData)
    ppgFeats(i,:) = getppgfeatures(ppgData(i, startId:endId), Ts);
end

normFactors = struct;
normFactors.abpMean = abpMean;
normFactors.abpRange = abpRange;
normFactors.ppgMean = ppgMean;
normFactors.ppgRange = ppgRange;


save('featureObservations.mat', 'ppgFeats', 'abpVals', 'normFactors', 'testIndices', 'trainingIndices', 'validIndices');

end
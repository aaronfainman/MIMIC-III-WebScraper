addSubPaths();

disp('Reading data from mat file...');
dataMatFile = load('widthFeatureObservations.mat');
ppgFeats = dataMatFile.ppgFeats;
% [SBP, DBP, MAP]
abpVals = dataMatFile.abpVals;

ppgFeats = ppgFeats(:,1:end-1);

normFactors = dataMatFile.normFactors;

ppgMean = normFactors.ppgMean;
ppgRange = normFactors.ppgRange;
abpMean = normFactors.abpMean;
abpRange = normFactors.abpMean;

disp('Separating train and test data...');
% partition_variable = cvpartition(height(ppgData), "Holdout",0.25);

trainingIndices = dataMatFile.trainingIndices;
trainInput = ppgFeats(trainingIndices, :);
trainOutput = abpVals(trainingIndices, :);

testIndices = dataMatFile.testIndices;
testInput = ppgFeats(testIndices, :);
testOutput = abpVals(testIndices, :);

validateIndices = dataMatFile.validIndices;
validateInput = ppgFeats(validateIndices, :);
validateOutput = abpVals(validateIndices, :);

numInPoints = size(trainInput, 2);
numOutPoints = size(trainOutput,2);



disp('Fitting model...');

fitr_sbp = fitrnet(trainInput, trainOutput(:,1), 'LayerSizes', [1024,1024,1024], 'Standardize', true,  'Verbose',1,'VerboseFrequency',5, 'IterationLimit', 8000, 'Lambda', 0, 'ValidationData', {validateInput(:,:), validateOutput(:,1)}, 'ValidationPatience', inf);

disp('Evaluating performance...');

predOutput = predict(fitr_sbp, testInput);

predBP = (predOutput.*abpRange)+abpMean;
trueBP = (testOutput(:,1).*abpRange)+abpMean;

errorBP = predBP - trueBP;

rmseBP = sqrt(mean(errorBP.^2))

thresh = 10;
mapAccuracy = sum(abs(errorBP) < thresh)/length(errorBP)

save('Fitr_SBP_211018_3.mat','fitr_sbp');

disp("Complete")





addSubPaths();

disp('Reading data from mat file...');
dataMatFile = load('timeObservationsWithLastSecond.mat');
ppgData = dataMatFile.inputFeats;
% abpOutData = dataMatFile.outputFeatsWave;

% [SBP, DBP, MAP]
abpVals = dataMatFile.outputFeatsBP;

abpVals = abpVals(:,1);

normFactors = dataMatFile.normFactors;

ppgMean = normFactors('PPGAmpMean');
ppgRange = normFactors('PPGAmpScale');
abpMean = normFactors('ABPAmpMean');
abpRange = normFactors('ABPAmpScale');


disp('Separating train and test data...');
% partition_variable = cvpartition(height(ppgData), "Holdout",0.25);

trainingIndices = dataMatFile.trainingIndices;
trainInput = ppgData(trainingIndices,:);
trainOutput = abpVals(trainingIndices,:);

testIndices = dataMatFile.testIndices;
testInput = ppgData(testIndices,:);
testOutput = abpVals(testIndices,:);

validateIndices = dataMatFile.validIndices;
validateInput = ppgData(validateIndices,:);
validateOutput = abpVals(validateIndices,:);

numInPoints = size(trainInput, 2);
numOutPoints = size(trainOutput,2);

disp("Training model...");

rgpMdl = fitrgp(trainInput, trainOutput, "Verbose", 1,'FitMethod','fic', 'PredictMethod','fic');

disp("Evaluating performance...");

predOut = predict(rgpMdl, testInput);

predBP = (predOutput.*abpRange)+abpMean;
trueBP = (testOutput.*abpRange)+abpMean;

predSBP = predBP(:,1);
trueSBP = trueBP(:,1);

errorBP = predBP - trueBP;

rmseBP = sqrt(mean(errorBP.^2))

thresh = 10;
accuracy = sum(abs(errorBP) < thresh)/length(errorBP)




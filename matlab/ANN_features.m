addSubPaths();

disp('Reading data from mat file...');
dataMatFile = load('featureObservations.mat');
ppgFeats = dataMatFile.ppgFeats;
% [SBP, DBP, MAP]
abpVals = dataMatFile.abpVals;

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

useNetwork = 0;

if (~useNetwork)

disp('Creating neural network...');

numUnits = 128;

layers = [ ...
    featureInputLayer(numInPoints)
    fullyConnectedLayer(numUnits)
    batchNormalizationLayer
    reluLayer
    dropoutLayer(0.01);
    fullyConnectedLayer(numUnits)
    batchNormalizationLayer
    reluLayer
    dropoutLayer(0.01);
    fullyConnectedLayer(numUnits)
    batchNormalizationLayer
    reluLayer
    dropoutLayer(0.01);
    fullyConnectedLayer(numOutPoints)
    reluLayer
    regressionLayer];

else
    disp("Loading network...");

    netANN = load('ANN_features_211016_1.mat').netANN;
end

maxEpochs = 50;
miniBatchSize = 150;
validationFrequency = floor(length(trainInput)/miniBatchSize);
options = trainingOptions('adam', ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'InitialLearnRate',0.0001, ...
    'ExecutionEnvironment', 'gpu', ...
    'ValidationData',{validateInput,validateOutput}, ...
    'ValidationFrequency',validationFrequency, ...
    'GradientThreshold',1, ...
    'Shuffle','never', ...
    'Verbose',1);

disp('Training NN...');


if (~useNetwork)
    [netANN, netInfo] = trainNetwork(trainInput,trainOutput, layers, options);
else
    [netANN, netInfo] = trainNetwork(trainInput,trainOutput, netANN.Layers, options);    
end

disp('Evaluating performance...');

predOutput = predict(netANN,testInput, 'MiniBatchSize',miniBatchSize);

pearsonCoeffs = zeros(length(testOutput),1);

for i = 1:length(pearsonCoeffs)
    pearsonCoeffs(i) = pearsonCoeff(predOutput{i}, testOutput{i});
end

meanPearsonCorrelation = mean(pearsonCoeffs)

predBP = (predOutput.*abpRange)+abpMean;
trueBP = (testOutput.*abpRange)+abpMean;

errorBP = predBP - trueBP;

rmseBP = sqrt(mean(errorBP.^2))

thresh = 10;
mapAccuracy = sum(abs(errorBP) < thresh)/length(errorBP)

save('ANN_features_211017.mat','netANN','netInfo');

disp("Complete")





addSubPaths();

disp('Reading data from mat file...');
dataMatFile = load('timeObservationsWithLastSecond.mat');
ppgData = dataMatFile.inputFeats;
abpOutData = dataMatFile.outputFeatsWave;

% [SBP, DBP, MAP]
abpVals = dataMatFile.outputFeatsBP;

normFactors = dataMatFile.normFactors;

ppgMean = normFactors('PPGAmpMean');
ppgRange = normFactors('PPGAmpScale');
abpMean = normFactors('ABPAmpMean');
abpRange = normFactors('ABPAmpScale');


disp('Separating train and test data...');
% partition_variable = cvpartition(height(ppgData), "Holdout",0.25);

trainingIndices = dataMatFile.trainingIndices;
trainInput = num2cell(ppgData(trainingIndices,:)',1)';
trainOutput = num2cell(abpOutData(trainingIndices,:)',1)';

testIndices = dataMatFile.testIndices;
testInput = num2cell(ppgData(testIndices,:)',1)';
testOutput = num2cell(abpOutData(testIndices,:)',1)';

validateIndices = dataMatFile.validIndices;
validateInput = num2cell(ppgData(validateIndices,:)',1)';
validateOutput = num2cell(abpOutData(validateIndices,:)',1)';


numInPoints = size(trainInput{1}, 1);
numOutPoints = size(trainOutput{1},1);

disp('Creating neural network...');

numLstmUnits = 1024;

layers = [ ...
    sequenceInputLayer(numInPoints)
    bilstmLayer(numLstmUnits, 'OutputMode','sequence')
    dropoutLayer(0.2)
    bilstmLayer(numLstmUnits, 'OutputMode','sequence')
    dropoutLayer(0.2)
    fullyConnectedLayer(numOutPoints)
    pearsonRegressionLayer('Output')];

maxEpochs = 15;
miniBatchSize = 200;
validationFrequency = floor(length(trainInput)/miniBatchSize);
options = trainingOptions('sgdm', ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'InitialLearnRate',0.01, ...
    'ExecutionEnvironment', 'gpu', ...
    'ValidationData',{validateInput,validateOutput}, ...
    'ValidationFrequency',validationFrequency, ...
    'GradientThreshold',1, ...
    'Shuffle','never', ...
    'Verbose',1);

disp('Training NN...');

[netLSTM, netInfo] = trainNetwork(trainInput,trainOutput,layers, options);

disp('Evaluating performance...');

predOutput = predict(netLSTM,testInput, 'MiniBatchSize',miniBatchSize);

pearsonCoeffs = zeros(length(testOutput),1);

for i = 1:length(pearsonCoeffs)
    pearsonCoeffs(i) = pearsonCoeff(predOutput{i}, testOutput{i});
end

meanPearsonCorrelation = mean(pearsonCoeffs)

predBP_norm = reshape(cell2mat(predOutput),[numOutPoints length(predOutput)]);
trueBP_norm = reshape(cell2mat(testOutput),[numOutPoints length(predOutput)]);

predBP = (predBP_norm.*abpRange)+abpMean;
trueBP = (trueBP_norm.*abpRange)+abpMean;

predMAP = mean(predBP);
trueMAP = mean(trueBP);

errorMAP = predMAP - trueMAP;

rmseMAP = sqrt(mean(errorMAP.^2))

thresh = 10;
mapAccuracy = sum(abs(errorMAP) < thresh)/length(errorMAP)

save('biLSTM_pearson_211010.mat','netLSTM','netInfo');


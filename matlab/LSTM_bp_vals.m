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
trainInput = num2cell(ppgData(trainingIndices,:)',1)';
% trainOutput = num2cell(abpVals(trainingIndices,:)',1)';
trainOutput = abpVals(trainingIndices,:);

testIndices = dataMatFile.testIndices;
testInput = num2cell(ppgData(testIndices,:)',1)';
% testOutput = num2cell(abpVals(testIndices,:)',1)';
testOutput = abpVals(testIndices,:);

validateIndices = dataMatFile.validIndices;
validateInput = num2cell(ppgData(validateIndices,:)',1)';
%validateOutput = num2cell(abpVals(validateIndices,:)',1)';
validateOutput = abpVals(validateIndices,:);


numInPoints = size(trainInput{1}, 1);
numOutPoints = size(trainOutput,2);



disp('Creating neural network...');

numLstmUnits = 1024;

layers = [ ...
    sequenceInputLayer(numInPoints)
    lstmLayer(numLstmUnits, 'OutputMode','last')
    dropoutLayer(0.2)
    lstmLayer(numLstmUnits, 'OutputMode','last')
    dropoutLayer(0.2)
    lstmLayer(numLstmUnits, 'OutputMode','last')
    dropoutLayer(0.2)
    lstmLayer(numLstmUnits, 'OutputMode','last')
    dropoutLayer(0.2)
    fullyConnectedLayer(numOutPoints)
    regressionLayer];

maxEpochs = 10;
miniBatchSize = 250;
validationFrequency = floor(length(trainInput)/miniBatchSize);
options = trainingOptions('adam', ...
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

%predBP_norm = reshape(cell2mat(predOutput),[numOutPoints length(predOutput)]);
%trueBP_norm = reshape(cell2mat(testOutput),[numOutPoints length(predO-utput)]);

predBP = (predOutput.*abpRange)+abpMean;
trueBP = (testOutput.*abpRange)+abpMean;

predSBP = predBP(:,1);
trueSBP = trueBP(:,1);

errorBP = predBP - trueBP;

rmseBP = sqrt(mean(errorBP.^2))

thresh = 10;
accuracy = sum(abs(errorBP) < thresh)/length(errorBP)

save('LSTM_SBP_211015_2.mat','netLSTM','netInfo');

disp("Complete");

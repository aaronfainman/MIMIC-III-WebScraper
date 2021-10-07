addSubPaths();

disp('Reading data from mat file...');
dataMatFile = load('timeObservationsWithLastSecond.mat');
ppgData = num2cell((dataMatFile.inputFeats)',1);
abpOutData = num2cell((dataMatFile.outputFeatsWave)',1);

normFactors = load('NormalisationFactors.mat').normFactors;

ppgMean = normFactors('PPGAmpMean');
ppgRange = normFactors('PPGAmpScale');
abpMean = normFactors('ABPAmpMean');
abpRange = normFactors('ABPAmpScale');

partition_variable = cvpartition(length(ppgData), "Holdout",0.25);

trainingIndices = training(partition_variable);
trainInput = ppgData(trainingIndices);
trainOutput = abpOutData(trainingIndices);

testIndices = test(partition_variable);
testInput = ppgData(testIndices);
testOutput = abpOutData(testIndices);

numInPoints = size(trainInput{1}, 1);
numOutPoints = size(trainOutput{1},1);

disp('Creating NN...');

numLstmUnits = 1024;

layers = [ ...
    sequenceInputLayer(numInPoints)
    bilstmLayer(numLstmUnits, 'OutputMode','sequence')
    dropoutLayer(0.2)
    bilstmLayer(numLstmUnits, 'OutputMode','sequence')
    dropoutLayer(0.2)
    fullyConnectedLayer(numOutPoints)
    regressionLayer];

maxEpochs = 10;
miniBatchSize = 30;
validationFrequency = floor(length(trainInput)/miniBatchSize);
options = trainingOptions('sgdm', ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'InitialLearnRate',0.01, ...
    'ExecutionEnvironment', 'gpu', ...
    'ValidationData',{testInput,testOutput}, ...
    'ValidationFrequency',validationFrequency, ...
    'GradientThreshold',1, ...
    'Shuffle','never', ...
    'Verbose',1);

disp('Training NN...');


[lstmNN, lstmInfo] = trainNetwork(trainInput,trainOutput,layers, options);

disp('Evaluating performance...');

predOutput = predict(lstmNN,testInput, 'MiniBatchSize',miniBatchSize);

pearsonCoeffs = zeros(length(testOutput),1);

for i = 1:length(pearsonCoeffs)
    pearsonCoeffs(i) = pearsonCoeff(predOutput{i}, testOutput{i});
end

meanPearsonCorrelation = mean(pearsonCoeffs)

predBP_norm = cell2mat(predOutput');
trueBP_norm = cell2mat(testOutput);

predBP = (predBP_norm.*abpRange)+abpMean;
trueBP = (trueBP_norm.*abpRange)+abpMean;

predMAP = mean(predBP);
trueMAP = mean(trueBP);

errorMAP = predMAP - trueMAP;

rmseMAP = sqrt(mean(errorMAP.^2))

thresh = 10;
accuracy = sum(abs(errorMAP)< thresh)/length(errorMAP)

rnd = randperm(length(testOutput), 5);

for i = 1:length(rnd)
    figure;
    plot(trueBP(:,rnd(i)));
    hold on;
    plot(predBP(:,rnd(i)));
    hold off;
end

trainTestIndices = {trainingIndices, testIndices};

save('211007_biLSTM.mat', 'lstmNN', 'trainTestIndices');





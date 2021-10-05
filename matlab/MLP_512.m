addSubPaths()

disp("Reading data...")

[input_tbl, output_tbl, normFactors] = MLFeatureRead();

input = table2array(input_tbl);
output = table2array(output_tbl);

partition_variable = cvpartition(height(input), "Holdout",0.25);

trainingIndices = training(partition_variable);
trainInput = input(trainingIndices,:);
trainOutput = output(trainingIndices,:);

testIndices = test(partition_variable);
testInput = input(testIndices,:);
testOutput = output(testIndices,:);

numFeatures = size(trainInput, 2);
numResponses = size(trainOutput, 2);

disp("Creating network...")

layers = [...
    featureInputLayer(numFeatures)
    fullyConnectedLayer(2048)
    reluLayer
    fullyConnectedLayer(1024)
    reluLayer
    fullyConnectedLayer(512)
    reluLayer
    fullyConnectedLayer(1024)
    reluLayer
    fullyConnectedLayer(2048)
    reluLayer
    fullyConnectedLayer(numResponses)
    regressionLayer];

maxEpochs = 100;
miniBatchSize = 16;
validationFrequency = floor(length(trainInput)/miniBatchSize);

options = trainingOptions('adam', ...
    'Shuffle','every-epoch', ...
    'MaxEpochs',maxEpochs, ...
    'Plots','training-progress', ...
    'InitialLearnRate',0.0001, ...
    'ValidationData',{testInput,testOutput}, ...
    'ValidationFrequency',validationFrequency, ...
    'Verbose', true);

disp("Training network...")

[mlpNN, nnInfo] = trainNetwork(trainInput,trainOutput,layers,options);

predOutput = predict(mlpNN,testInput);

outputHeaders = output_tbl.Properties.VariableNames;

freqHeaders = 3:202;
magsHeaders = 204:403;
phaseHeaders = 406:605;
otherHeaders = 1:605;
otherHeaders([phaseHeaders freqHeaders magsHeaders]) = [];

ABPBW_Header = 1;
ABPPower_Header = 2;
MAP_Header = 203;
MeanDBP_Header = 404;
MeanSBP_Header = 405;

predBP = (predOutput(:,[203 404 405])* normFactors('ABPAmpScale')) + normFactors('ABPAmpMean');
trueBP = (testOutput(:,[203 404 405])* normFactors('ABPAmpScale')) + normFactors('ABPAmpMean');

predictionError =  trueBP - predBP;

% for MAP:
thresh = 10;
numCorrect = [ sum(abs(predictionError(:,1)) < thresh) sum(abs(predictionError(:,2)) < thresh) sum(abs(predictionError(:,3)) < thresh)];
numTestSamples = length(testOutput);

disp("For MAP, DBP, SBP:");
accuracy = numCorrect./numTestSamples

squares = predictionError.^2;
rmse = sqrt(mean(squares))

save('211004_MLP.mat','mlpNN', '-v7.3');



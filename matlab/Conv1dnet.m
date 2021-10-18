%% 1D Conv
addSubPaths();

disp('Reading data from mat file...');
dataMatFile = load('timeObservationsWithLastSecond.mat');
ppgData = dataMatFile.inputFeats;
% abpOutData = dataMatFile.outputFeatsWave;

% [SBP, DBP, MAP]
abpVals = dataMatFile.outputFeatsBP;

abpVals = abpVals(:,1:2);

normFactors = dataMatFile.normFactors;

ppgMean = normFactors('PPGAmpMean');
ppgRange = normFactors('PPGAmpScale');
abpMean = normFactors('ABPAmpMean');
abpRange = normFactors('ABPAmpScale');


disp('Separating train and test data...');
% partition_variable = cvpartition(height(ppgData), "Holdout",0.25);

% trainingIndices = dataMatFile.trainingIndices;
trainInputT = dataMatFile.trainInputT;
trainOutputT = dataMatFile.trainOutputT;

testInputT = dataMatFile.testInputT;
testOutputT = dataMatFile.testOutputT;

validInputT = dataMatFile.validInputT;
validOutputT = dataMatFile.validOutputT;

%%
numInPoints = size(trainInputT, 2);
numOutPoints = size(trainOutputT,2);

disp('Creating neural network...');


numFilters = 64;
filterSize = 5;
dropoutFactor = 0.005;
numBlocks = 4;

layer = sequenceInputLayer(numInPoints,Normalization="rescale-symmetric",Name="input");
lgraph = layerGraph(layer);

outputName = layer.Name;

for i = 1:numBlocks
    dilationFactor = 2^(i-1);
    
    layers = [
        convolution1dLayer(filterSize,numFilters,DilationFactor=dilationFactor,Padding="causal",Name="conv1_"+i)
        layerNormalizationLayer
        dropoutLayer(dropoutFactor)
        convolution1dLayer(filterSize,numFilters,DilationFactor=dilationFactor,Padding="causal")
        layerNormalizationLayer
        reluLayer
        dropoutLayer(dropoutFactor)
        additionLayer(2,Name="add_"+i)];

    % Add and connect layers.
    lgraph = addLayers(lgraph,layers);
    lgraph = connectLayers(lgraph,outputName,"conv1_"+i);

    % Skip connection.
    if i == 1
        % Include convolution in first skip connection.
        layer = convolution1dLayer(1,numFilters,Name="convSkip");

        lgraph = addLayers(lgraph,layer);
        lgraph = connectLayers(lgraph,outputName,"convSkip");
        lgraph = connectLayers(lgraph,"convSkip","add_" + i + "/in2");
    else
        lgraph = connectLayers(lgraph,outputName,"add_" + i + "/in2");
    end
    
    % Update layer output name.
    outputName = "add_" + i;
end

layers = [
    fullyConnectedLayer(numOutPoints,Name="fc")
    reluLayer
    regressionLayer];
lgraph = addLayers(lgraph,layers);
lgraph = connectLayers(lgraph,outputName,"fc");

options = trainingOptions('adam',...
    'MaxEpochs',200,...
    'ExecutionEnvironment', 'gpu',...
    'L2Regularization', 0, ...
    'InitialLearnRate', 5e-5,...
    'MiniBatchSize',height(trainInputT),...
    'ValidationData', {validInputT', validOutputT(:,1)'}, ...
    'VerboseFrequency',5, ...
    'ValidationFrequency', 5);

[convNet_sbp, info] = trainNetwork(trainInputT(1:end,:)', trainOutputT(1:end,1)', lgraph, options);

actualTestSBP = testOutputT(:,1)*normFactors('ABPAmpScale')+normFactors('ABPAmpMean');
predictedTestSBP = predict(convNet_sbp, testInputT')*normFactors('ABPAmpScale')+normFactors('ABPAmpMean');
testingErrorSBP = (predictedTestSBP-actualTestSBP');

MAE = mean(abs(testingErrorSBP))

accuracy = sum(abs(testingErrorSBP)<10)/length(testingErrorSBP)
fitlm(actualTestSBP, predictedTestSBP)
scatter(actualTestSBP, predictedTestSBP, '.'); xlabel("Actual (mmHg)"); ylabel("Predicted (mmHg)"); grid on;
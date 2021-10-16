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

trainingIndices = dataMatFile.trainingIndices;
trainInput = ppgData(trainingIndices,:);
trainInput = reshape(trainInput', [1, 1250, 1, length(trainInput)]);
trainOutput = abpVals(trainingIndices,:);

testIndices = dataMatFile.testIndices;
testInput = ppgData(testIndices,:);
testInput = reshape(testInput', [1, 1250, 1, length(testInput)]);
testOutput = abpVals(testIndices,:);

validateIndices = dataMatFile.validIndices;
validateInput = ppgData(validateIndices,:);
validateInput = reshape(validateInput', [1, 1250,1, length(validateInput)]);
validateOutput = abpVals(validateIndices,:);

numInPoints = size(trainInput, 2);
numOutPoints = size(trainOutput,2);

disp('Creating neural network...');

numFilters = 125;
filterSize = 10;
dropoutFactor = 0.005;
numBlocks = 1;



layer = imageInputLayer([1 1250],Name="input");
lgraph = layerGraph(layer);

outputName = layer.Name;

for i = 1:numBlocks
    dilationFactor = 2^(i-1);

    layers = [
        convolution2dLayer([1 filterSize],numFilters,DilationFactor=dilationFactor,Padding="same",Name="conv1_"+i)
        layerNormalizationLayer(Name="norm1_"+i)
        dropoutLayer(dropoutFactor, Name="conv1d_"+i)
        convolution2dLayer([1 filterSize],numFilters,DilationFactor=dilationFactor,Padding="same",Name="conv2_"+i)
        layerNormalizationLayer(Name="norm2_"+i)
        reluLayer(Name="relu_"+i)
        dropoutLayer(dropoutFactor,Name="conv2d_"+i)
        additionLayer(2,Name="add_"+i)];

    % Add and connect layers.
    lgraph = addLayers(lgraph,layers);
    lgraph = connectLayers(lgraph,outputName,"conv1_"+i);

    % Skip connection.
    if i == 1
        % Include convolution in first skip connection.
        layer = convolution2dLayer([1 1],numFilters,Name="convSkip");

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
    reluLayer(Name="relu")
    regressionLayer(Name="Output")];
lgraph = addLayers(lgraph,layers);
lgraph = connectLayers(lgraph,outputName,"fc");

maxEpochs = 50;
miniBatchSize = 200;
validationFrequency = floor(length(trainInput)/miniBatchSize);
options = trainingOptions('sgdm', ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'InitialLearnRate',0.01, ...
    'ExecutionEnvironment', 'gpu', ...
    'ValidationData',{validateInput,validateOutput}, ...
    'ValidationFrequency',validationFrequency, ...
    'Verbose',1);

disp('Training NN...');

[netCNN, netInfo] = trainNetwork(trainInput,trainOutput,lgraph, options);

disp('Evaluating performance...');

predOutput = predict(netCNN,testInput, 'MiniBatchSize',miniBatchSize);

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

save('CNN_1D_BP_211016.mat','netCNN','netInfo');

disp("Complete");

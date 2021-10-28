addSubPaths();

if (exist('cwtData') ~= 1)

    disp("Loading image data...");

    cwtData = load('CNN_data.mat');

    trainInput = cwtData.trainInput;
    testInput = cwtData.testInput;

    abpScale = cwtData.abpScale;
    abpMean = cwtData.abpMean;

    testOutput = cwtData.testOutput;
    trainOutput = cwtData.trainOutput;

    testOutput = (testOutput - abpMean)./abpScale;
    trainOutput = (trainOutput - abpMean)./abpScale;
else
    disp("Data already in workspace...")
end

numOutputs = size(testOutput,2);

disp("Creating CNN...");


% RESNET18 EDITED VIA DEEP NETWORK DESIGNER

params = load("OldFeatureFiles/resnet18_params.mat");

lgraph = layerGraph();

tempLayers = [
    imageInputLayer([224 224 3],"Name","data","Normalization","zscore","Mean",params.data.Mean,"StandardDeviation",params.data.StandardDeviation)
    convolution2dLayer([7 7],64,"Name","conv1","BiasLearnRateFactor",0,"Padding",[3 3 3 3],"Stride",[2 2],"Bias",params.conv1.Bias,"Weights",params.conv1.Weights)
    batchNormalizationLayer("Name","bn_conv1","Offset",params.bn_conv1.Offset,"Scale",params.bn_conv1.Scale,"TrainedMean",params.bn_conv1.TrainedMean,"TrainedVariance",params.bn_conv1.TrainedVariance)
    reluLayer("Name","conv1_relu")
    maxPooling2dLayer([3 3],"Name","pool1","Padding",[1 1 1 1],"Stride",[2 2])];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([3 3],64,"Name","res2a_branch2a","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Bias",params.res2a_branch2a.Bias,"Weights",params.res2a_branch2a.Weights)
    batchNormalizationLayer("Name","bn2a_branch2a","Offset",params.bn2a_branch2a.Offset,"Scale",params.bn2a_branch2a.Scale,"TrainedMean",params.bn2a_branch2a.TrainedMean,"TrainedVariance",params.bn2a_branch2a.TrainedVariance)
    reluLayer("Name","res2a_branch2a_relu")
    convolution2dLayer([3 3],64,"Name","res2a_branch2b","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Bias",params.res2a_branch2b.Bias,"Weights",params.res2a_branch2b.Weights)
    batchNormalizationLayer("Name","bn2a_branch2b","Offset",params.bn2a_branch2b.Offset,"Scale",params.bn2a_branch2b.Scale,"TrainedMean",params.bn2a_branch2b.TrainedMean,"TrainedVariance",params.bn2a_branch2b.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    additionLayer(2,"Name","res2a")
    reluLayer("Name","res2a_relu")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([3 3],64,"Name","res2b_branch2a","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Bias",params.res2b_branch2a.Bias,"Weights",params.res2b_branch2a.Weights)
    batchNormalizationLayer("Name","bn2b_branch2a","Offset",params.bn2b_branch2a.Offset,"Scale",params.bn2b_branch2a.Scale,"TrainedMean",params.bn2b_branch2a.TrainedMean,"TrainedVariance",params.bn2b_branch2a.TrainedVariance)
    reluLayer("Name","res2b_branch2a_relu")
    convolution2dLayer([3 3],64,"Name","res2b_branch2b","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Bias",params.res2b_branch2b.Bias,"Weights",params.res2b_branch2b.Weights)
    batchNormalizationLayer("Name","bn2b_branch2b","Offset",params.bn2b_branch2b.Offset,"Scale",params.bn2b_branch2b.Scale,"TrainedMean",params.bn2b_branch2b.TrainedMean,"TrainedVariance",params.bn2b_branch2b.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    additionLayer(2,"Name","res2b")
    reluLayer("Name","res2b_relu")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([1 1],128,"Name","res3a_branch1","BiasLearnRateFactor",0,"Stride",[2 2],"Bias",params.res3a_branch1.Bias,"Weights",params.res3a_branch1.Weights)
    batchNormalizationLayer("Name","bn3a_branch1","Offset",params.bn3a_branch1.Offset,"Scale",params.bn3a_branch1.Scale,"TrainedMean",params.bn3a_branch1.TrainedMean,"TrainedVariance",params.bn3a_branch1.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([3 3],128,"Name","res3a_branch2a","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Stride",[2 2],"Bias",params.res3a_branch2a.Bias,"Weights",params.res3a_branch2a.Weights)
    batchNormalizationLayer("Name","bn3a_branch2a","Offset",params.bn3a_branch2a.Offset,"Scale",params.bn3a_branch2a.Scale,"TrainedMean",params.bn3a_branch2a.TrainedMean,"TrainedVariance",params.bn3a_branch2a.TrainedVariance)
    reluLayer("Name","res3a_branch2a_relu")
    convolution2dLayer([3 3],128,"Name","res3a_branch2b","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Bias",params.res3a_branch2b.Bias,"Weights",params.res3a_branch2b.Weights)
    batchNormalizationLayer("Name","bn3a_branch2b","Offset",params.bn3a_branch2b.Offset,"Scale",params.bn3a_branch2b.Scale,"TrainedMean",params.bn3a_branch2b.TrainedMean,"TrainedVariance",params.bn3a_branch2b.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    additionLayer(2,"Name","res3a")
    reluLayer("Name","res3a_relu")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([3 3],128,"Name","res3b_branch2a","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Bias",params.res3b_branch2a.Bias,"Weights",params.res3b_branch2a.Weights)
    batchNormalizationLayer("Name","bn3b_branch2a","Offset",params.bn3b_branch2a.Offset,"Scale",params.bn3b_branch2a.Scale,"TrainedMean",params.bn3b_branch2a.TrainedMean,"TrainedVariance",params.bn3b_branch2a.TrainedVariance)
    reluLayer("Name","res3b_branch2a_relu")
    convolution2dLayer([3 3],128,"Name","res3b_branch2b","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Bias",params.res3b_branch2b.Bias,"Weights",params.res3b_branch2b.Weights)
    batchNormalizationLayer("Name","bn3b_branch2b","Offset",params.bn3b_branch2b.Offset,"Scale",params.bn3b_branch2b.Scale,"TrainedMean",params.bn3b_branch2b.TrainedMean,"TrainedVariance",params.bn3b_branch2b.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    additionLayer(2,"Name","res3b")
    reluLayer("Name","res3b_relu")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([1 1],256,"Name","res4a_branch1","BiasLearnRateFactor",0,"Stride",[2 2],"Bias",params.res4a_branch1.Bias,"Weights",params.res4a_branch1.Weights)
    batchNormalizationLayer("Name","bn4a_branch1","Offset",params.bn4a_branch1.Offset,"Scale",params.bn4a_branch1.Scale,"TrainedMean",params.bn4a_branch1.TrainedMean,"TrainedVariance",params.bn4a_branch1.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([3 3],256,"Name","res4a_branch2a","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Stride",[2 2],"Bias",params.res4a_branch2a.Bias,"Weights",params.res4a_branch2a.Weights)
    batchNormalizationLayer("Name","bn4a_branch2a","Offset",params.bn4a_branch2a.Offset,"Scale",params.bn4a_branch2a.Scale,"TrainedMean",params.bn4a_branch2a.TrainedMean,"TrainedVariance",params.bn4a_branch2a.TrainedVariance)
    reluLayer("Name","res4a_branch2a_relu")
    convolution2dLayer([3 3],256,"Name","res4a_branch2b","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Bias",params.res4a_branch2b.Bias,"Weights",params.res4a_branch2b.Weights)
    batchNormalizationLayer("Name","bn4a_branch2b","Offset",params.bn4a_branch2b.Offset,"Scale",params.bn4a_branch2b.Scale,"TrainedMean",params.bn4a_branch2b.TrainedMean,"TrainedVariance",params.bn4a_branch2b.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    additionLayer(2,"Name","res4a")
    reluLayer("Name","res4a_relu")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([3 3],256,"Name","res4b_branch2a","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Bias",params.res4b_branch2a.Bias,"Weights",params.res4b_branch2a.Weights)
    batchNormalizationLayer("Name","bn4b_branch2a","Offset",params.bn4b_branch2a.Offset,"Scale",params.bn4b_branch2a.Scale,"TrainedMean",params.bn4b_branch2a.TrainedMean,"TrainedVariance",params.bn4b_branch2a.TrainedVariance)
    reluLayer("Name","res4b_branch2a_relu")
    convolution2dLayer([3 3],256,"Name","res4b_branch2b","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Bias",params.res4b_branch2b.Bias,"Weights",params.res4b_branch2b.Weights)
    batchNormalizationLayer("Name","bn4b_branch2b","Offset",params.bn4b_branch2b.Offset,"Scale",params.bn4b_branch2b.Scale,"TrainedMean",params.bn4b_branch2b.TrainedMean,"TrainedVariance",params.bn4b_branch2b.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    additionLayer(2,"Name","res4b")
    reluLayer("Name","res4b_relu")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([1 1],512,"Name","res5a_branch1","BiasLearnRateFactor",0,"Stride",[2 2],"Bias",params.res5a_branch1.Bias,"Weights",params.res5a_branch1.Weights)
    batchNormalizationLayer("Name","bn5a_branch1","Offset",params.bn5a_branch1.Offset,"Scale",params.bn5a_branch1.Scale,"TrainedMean",params.bn5a_branch1.TrainedMean,"TrainedVariance",params.bn5a_branch1.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([3 3],512,"Name","res5a_branch2a","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Stride",[2 2],"Bias",params.res5a_branch2a.Bias,"Weights",params.res5a_branch2a.Weights)
    batchNormalizationLayer("Name","bn5a_branch2a","Offset",params.bn5a_branch2a.Offset,"Scale",params.bn5a_branch2a.Scale,"TrainedMean",params.bn5a_branch2a.TrainedMean,"TrainedVariance",params.bn5a_branch2a.TrainedVariance)
    reluLayer("Name","res5a_branch2a_relu")
    convolution2dLayer([3 3],512,"Name","res5a_branch2b","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Bias",params.res5a_branch2b.Bias,"Weights",params.res5a_branch2b.Weights)
    batchNormalizationLayer("Name","bn5a_branch2b","Offset",params.bn5a_branch2b.Offset,"Scale",params.bn5a_branch2b.Scale,"TrainedMean",params.bn5a_branch2b.TrainedMean,"TrainedVariance",params.bn5a_branch2b.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    additionLayer(2,"Name","res5a")
    reluLayer("Name","res5a_relu")];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    convolution2dLayer([3 3],512,"Name","res5b_branch2a","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Bias",params.res5b_branch2a.Bias,"Weights",params.res5b_branch2a.Weights)
    batchNormalizationLayer("Name","bn5b_branch2a","Offset",params.bn5b_branch2a.Offset,"Scale",params.bn5b_branch2a.Scale,"TrainedMean",params.bn5b_branch2a.TrainedMean,"TrainedVariance",params.bn5b_branch2a.TrainedVariance)
    reluLayer("Name","res5b_branch2a_relu")
    convolution2dLayer([3 3],512,"Name","res5b_branch2b","BiasLearnRateFactor",0,"Padding",[1 1 1 1],"Bias",params.res5b_branch2b.Bias,"Weights",params.res5b_branch2b.Weights)
    batchNormalizationLayer("Name","bn5b_branch2b","Offset",params.bn5b_branch2b.Offset,"Scale",params.bn5b_branch2b.Scale,"TrainedMean",params.bn5b_branch2b.TrainedMean,"TrainedVariance",params.bn5b_branch2b.TrainedVariance)];
lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    additionLayer(2,"Name","res5b")
    reluLayer("Name","res5b_relu")
    globalAveragePooling2dLayer("Name","pool5")
    fullyConnectedLayer(1000,"Name","fc1000","Bias",params.fc1000.Bias,"Weights",params.fc1000.Weights)
    fullyConnectedLayer(3,"Name","fcOut")
    reluLayer("Name","relu")
    regressionLayer("Name","output")];
lgraph = addLayers(lgraph,tempLayers);

% clean up helper variable
clear tempLayers;

lgraph = connectLayers(lgraph,"pool1","res2a_branch2a");
lgraph = connectLayers(lgraph,"pool1","res2a/in2");
lgraph = connectLayers(lgraph,"bn2a_branch2b","res2a/in1");
lgraph = connectLayers(lgraph,"res2a_relu","res2b_branch2a");
lgraph = connectLayers(lgraph,"res2a_relu","res2b/in2");
lgraph = connectLayers(lgraph,"bn2b_branch2b","res2b/in1");
lgraph = connectLayers(lgraph,"res2b_relu","res3a_branch1");
lgraph = connectLayers(lgraph,"res2b_relu","res3a_branch2a");
lgraph = connectLayers(lgraph,"bn3a_branch1","res3a/in2");
lgraph = connectLayers(lgraph,"bn3a_branch2b","res3a/in1");
lgraph = connectLayers(lgraph,"res3a_relu","res3b_branch2a");
lgraph = connectLayers(lgraph,"res3a_relu","res3b/in2");
lgraph = connectLayers(lgraph,"bn3b_branch2b","res3b/in1");
lgraph = connectLayers(lgraph,"res3b_relu","res4a_branch1");
lgraph = connectLayers(lgraph,"res3b_relu","res4a_branch2a");
lgraph = connectLayers(lgraph,"bn4a_branch1","res4a/in2");
lgraph = connectLayers(lgraph,"bn4a_branch2b","res4a/in1");
lgraph = connectLayers(lgraph,"res4a_relu","res4b_branch2a");
lgraph = connectLayers(lgraph,"res4a_relu","res4b/in2");
lgraph = connectLayers(lgraph,"bn4b_branch2b","res4b/in1");
lgraph = connectLayers(lgraph,"res4b_relu","res5a_branch1");
lgraph = connectLayers(lgraph,"res4b_relu","res5a_branch2a");
lgraph = connectLayers(lgraph,"bn5a_branch2b","res5a/in1");
lgraph = connectLayers(lgraph,"bn5a_branch1","res5a/in2");
lgraph = connectLayers(lgraph,"res5a_relu","res5b_branch2a");
lgraph = connectLayers(lgraph,"res5a_relu","res5b/in2");
lgraph = connectLayers(lgraph,"bn5b_branch2b","res5b/in1");

% -------------------------------------------------------------------------------
miniBatchSize  = 16;
validationFrequency = floor(size(testInput,4)/miniBatchSize);
options = trainingOptions('sgdm', ...
    'MiniBatchSize',miniBatchSize, ...
    'MaxEpochs',50, ...
    'InitialLearnRate',1e-4, ...
    'ExecutionEnvironment', 'multi-gpu',...
    'Shuffle','every-epoch', ...
    'ValidationData',{testInput,testOutput}, ...
    'ValidationFrequency',validationFrequency, ...
    'Verbose',true);

net = trainNetwork(trainInput, trainOutput, lgraph, options);

disp("Evaluating performance...");

pred = predict(net,testInput, 'MiniBatchSize', 16);

predBP = (pred.*abpScale + abpMean);

trueBP = (testOutput .* abpScale + abpMean);

predictionError =  trueBP - predBP;

% for MAP:
thresh = 10;

mae = abs(predictionError);

overallMAE = mean(mae)

numCorrect = sum(mae < 10);
disp("For SBP, DBP, MAP:");
accuracy = numCorrect./length(testInput)

save('resnet_CNN.mat','net', 'net', '-v7.3');



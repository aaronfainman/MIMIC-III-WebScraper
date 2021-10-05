addSubPaths();

if (exist('ppgImageData') ~= 1)

    disp("Loading PPG image data...");

    ppgImageData = load('testTrainImageDataPPG.mat');

    trainImages = ppgImageData.trainImages;
    testImages = ppgImageData.testImages;
    trainInput = ppgImageData.trainInput;
    testInput = ppgImageData.testInput;
else
    disp("PPG image data already in workspace...")
end


disp("Reading feature data...");

[input_tbl, output_tbl, normFactors] = MLFeatureRead(...
    '../physionet.org/inputFeatures.csv', '../physionet.org/outputFeatures.csv', ...
    'NormalisationFactors.mat');

output = table2array(output_tbl);

bp_output = output(:, [203 404 405]);

trainSize = length(trainInput);
trainOutput = bp_output(1:trainSize, :);
testOutput = bp_output(trainSize+1:end, :);

if length(testInput)+length(trainInput) > length(output)
    s = length(testInput)+length(trainInput) - length(output);
    testInput = testInput(:,:,:,s+1:end);
end

numOutputs = size(bp_output,2);

disp("Creating CNN...");

net = googlenet;

layers = net.Layers;

numLayers = length(layers);

layers = [
    layers(1:end-3)
    fullyConnectedLayer(numOutputs)
    regressionLayer];

layers(1:end-3) = freezeWeights(layers(1:end-3));

miniBatchSize  = 16;
validationFrequency = floor(length(trainImages.Files)/miniBatchSize);
options = trainingOptions('sgdm', ...
    'MiniBatchSize',miniBatchSize, ...
    'MaxEpochs',10, ...
    'InitialLearnRate',1e-3, ...
    'ExecutionEnvironment', 'multi-gpu',...
    'Shuffle','every-epoch', ...
    'ValidationData',{testInput,testOutput}, ...
    'ValidationFrequency',validationFrequency, ...
    'Verbose',true);

net = trainNetwork(trainInput, trainOutput, layers, options);

disp("Training CNN...");

[net, netInfo] = trainNetwork(trainInput,trainOutput,layers,options);

disp("Evaluating performance...");

pred = predict(net,testInput, 'MiniBatchSize', 16);

predBP = (pred(:,[203 404 405])* normFactors('ABPAmpScale')) + normFactors('ABPAmpMean');
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

fileList = {trainImages.Files, testImages.Files};

save('211005_GoogLeNet_CNN.mat','net', 'fileList', '-v7.3');



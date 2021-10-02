%% Using CWT for 2D CNN

addSubPaths();

segmented_file_dir = "../physionet.org/segmented_data/";
images_dir = "../physionet.org/cwt_images";

disp("Loading data...");

imageData = load('testTrainImageData.mat');

trainImages = imageData.trainImages;
testImages = imageData.testImages;
trainInput = imageData.trainInput;
testInput = imageData.testInput;

[input_tbl, output_tbl, normFactors] = MLFeatureRead(...
    '../physionet.org/inputFeatures.csv', '../physionet.org/outputFeatures.csv', ...
    'NormalisationFactors.mat');

output = table2array(output_tbl);

% bp_output = output(:, [203 404 405]);

trainSize = ceil(0.8*length(output));
trainOutput = output(1:trainSize, :);
testOutput = output(trainSize+1:end, :);

%%
numOutputs = size(output,2);

% layers = [
%     imageInputLayer([1024 1024 3])
%     convolution2dLayer(3,8,'Padding','same')
%     batchNormalizationLayer
%     reluLayer
%     averagePooling2dLayer(2,'Stride',2)
%     convolution2dLayer(3,16,'Padding','same')
%     batchNormalizationLayer
%     reluLayer
%     averagePooling2dLayer(2,'Stride',2)
%     convolution2dLayer(3,32,'Padding','same')
%     batchNormalizationLayer
%     reluLayer
%     convolution2dLayer(3,32,'Padding','same')
%     batchNormalizationLayer
%     reluLayer
%     dropoutLayer(0.2)
%     fullyConnectedLayer(numOutputs)
%     regressionLayer];

disp("Creating CNN...");

layers = [
    imageInputLayer([1024 1024 3])
    convolution2dLayer(3,8,'Padding','same')
    batchNormalizationLayer
    reluLayer
    averagePooling2dLayer(2,'Stride',2)
    fullyConnectedLayer(100)
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    dropoutLayer(0.2)
    fullyConnectedLayer(numOutputs)
    regressionLayer];

miniBatchSize  = 8;
validationFrequency = floor(length(trainImages.Files)/miniBatchSize);
options = trainingOptions('sgdm', ...
    'MiniBatchSize',miniBatchSize, ...
    'MaxEpochs',10, ...
    'InitialLearnRate',1e-6, ...
    'Shuffle','every-epoch', ...
    'ValidationData',{testInput,testOutput}, ...
    'ValidationFrequency',validationFrequency, ...
    'Plots','training-progress', ...
    'Verbose',true);

%     'LearnRateSchedule','piecewise', ...
%     'LearnRateDropFactor',0.1, ...
%     'LearnRateDropPeriod',20, ...

%% 
% Train network

disp("Training CNN...");

net = trainNetwork(trainInput,trainOutput,layers,options);

disp("Evaluating performance...");

pred = predict(net,testInput, 'MiniBatchSize', 8);

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

%figure
%scatter(predMAP,trueMAP,'+')
%xlabel("Predicted MAP")
%ylabel("True MAP")

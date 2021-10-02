%% Using CWT for 2D CNN

addSubPaths();

segmented_file_dir = "../physionet.org/segmented_data/";
images_dir = "../physionet.org/cwt_images";

disp("Reading images...");

allImages = imageDatastore(fullfile(images_dir,'PPG/'),'LabelSource', 'foldernames');

[trainImages, testImages] = splitEachLabel(allImages,0.8);

[input_tbl, output_tbl, normFactors] = MLFeatureRead(...
    '../physionet.org/inputFeatures.csv', '../physionet.org/outputFeatures.csv', ...
    'NormalisationFactors.mat');

output = table2array(output_tbl);

bp_output = output(:, [203 404 405]);

trainSize = ceil(0.8*length(bp_output));
trainOutput = bp_output(1:trainSize, :);
testOutput = bp_output(trainSize+1:end, :);

disp("Generating train and test I/O data...");

trainInput = [];
for i = 1:length(trainImages.Files)
    trainInput = cat(4,trainInput, readimage(trainImages,i));
end

testInput = [];
for i = 1:length(testImages.Files)
    testInput = cat(4,testInput, readimage(testImages,i));
end


%%
numOutputs = size(bp_output,2);

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
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    dropoutLayer(0.2)
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(numOutputs)
    regressionLayer];

miniBatchSize  = 8;
validationFrequency = floor(length(trainImages.Files)/miniBatchSize);
options = trainingOptions('sgdm', ...
    'MiniBatchSize',miniBatchSize, ...
    'MaxEpochs',30, ...
    'InitialLearnRate',1e-6, ...
    'Shuffle','every-epoch', ...
    'ValidationData',{testInput,testOutput}, ...
    'ValidationFrequency',validationFrequency, ...
    'Plots','training-progress', ...
    'Verbose',false);

%     'LearnRateSchedule','piecewise', ...
%     'LearnRateDropFactor',0.1, ...
%     'LearnRateDropPeriod',20, ...

%% 
% Train network

disp("Training CNN...");

net = trainNetwork(trainInput,trainOutput,layers,options);

disp("Evaluating performance...");

pred = predict(net,testInput, 'MiniBatchSize', 8);

predMAP = (pred(:,1)* normFactors('ABPAmpScale')) + normFactors('ABPAmpMean');
trueMAP = (testOutput(:,1)* normFactors('ABPAmpScale')) + normFactors('ABPAmpMean');

predictionError =  trueMAP - predMAP;

% for MAP:
thresh = 5;
numCorrect = sum(abs(predictionError(:,1)) < thresh);
numTestSamples = length(testOutput);

disp("For MAP:");
accuracy = numCorrect/numTestSamples

squares = predictionError.^2;
rmse = sqrt(mean(squares))

%figure
%scatter(predMAP,trueMAP,'+')
%xlabel("Predicted MAP")
%ylabel("True MAP")

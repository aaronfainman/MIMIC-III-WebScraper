%% Using CWT for 2D CNN

addSubPaths();

segmented_file_dir = "../physionet.org/segmented_data/";
images_dir = "../physionet.org/cwt_images";


if (exist('ppgImageData') ~= 1)
    
    disp("Loading PPG image data...");

    ppgImageData = load('testTrainImageDataPPG.mat');

    ppgTrainImages = ppgImageData.trainImages;
    ppgTestImages = ppgImageData.testImages;
    ppgTrainInput = ppgImageData.trainInput;
    ppgTestInput = ppgImageData.testInput;
else
    disp("PPG image data already in workspace...")
end

if (exist('abpImageData') ~= 1)

    disp("Loading ABP image data...");

    abpImageData = load('testTrainImageDataABP.mat');

    abpTrainImages = abpImageData.trainImages;
    abpTestImages = abpImageData.testImages;
    abpTrainOutput = abpImageData.trainInput;
    abpTestOutput = abpImageData.testInput;
else
    disp("ABP image data already in workspace...")
end


% Image to image regression example: 
% https://www.mathworks.com/help/5g/ug/deep-learning-data-synthesis-for-5g-channel-estimation.html

layers = [ ...
        imageInputLayer([256 256 3],'Normalization','none')
        convolution2dLayer(3,8,'Padding','same')
        reluLayer
	convolution2dLayer(8,8,'Padding','same')
        reluLayer
        convolution2dLayer(16,8,'Padding','same')
        reluLayer
        convolution2dLayer(8,8,'Padding','same')
        reluLayer
        convolution2dLayer(3,3,'Padding','same')
        regressionLayer
    ];

disp("Creating CNN...");

% layers = [
%    imageInputLayer([1024 1024 3])
%    convolution2dLayer(3,8,'Padding','same')
%    batchNormalizationLayer
%    reluLayer
%    averagePooling2dLayer(2,'Stride',2)
%    convolution2dLayer(3,16,'Padding','same')
%    batchNormalizationLayer
%    reluLayer
%    averagePooling2dLayer(2,'Stride',2)
%    dropoutLayer(0.2)
%    fullyConnectedLayer(numOutputs)
%    regressionLayer];

miniBatchSize  = 16;
validationFrequency = floor(length(ppgTrainImages.Files)/miniBatchSize);
options = trainingOptions('adam', ...
    'MiniBatchSize',miniBatchSize, ...
    'MaxEpochs',50, ...
    'InitialLearnRate',1e-6, ...
    'ExecutionEnvironment', 'gpu',...
    'Shuffle','every-epoch', ...
    'ValidationData',{ppgTestInput,abpTestOutput}, ...
    'ValidationFrequency',validationFrequency, ...
    'Plots','training-progress', ...
    'Verbose',true);

%     'LearnRateSchedule','piecewise', ...
%     'LearnRateDropFactor',0.1, ...
%     'LearnRateDropPeriod',20, ...

%% 
% Train network

disp("Training CNN...");

[net, netInfo] = trainNetwork(ppgTrainInput,abpTrainOutput,layers,options);

disp("Evaluating performance...");

pred = predict(net,ppgTestInput, 'MiniBatchSize', 16);


% for MAP:
% thresh = 10;
% numCorrect = [ sum(abs(predictionError(:,1)) < thresh) sum(abs(predictionError(:,2)) < thresh) sum(abs(predictionError(:,3)) < thresh)];
% numTestSamples = length(testOutput);

% disp("For MAP, DBP, SBP:");
% accuracy = numCorrect./numTestSamples

%squares = predictionError.^2;
%rmse = sqrt(mean(squares))


predError = pred - abpTestOutput;
sqError = predError.^2;

msePerImage = mean(sqError, [1 2 3]);
msePerPixel = mean(sqError, 4);

rmsePerImage = sqrt(msePerImage);
rmsePerPixel = sqrt(msePerImage);

meanRmsePerImage = mean(rmsePerImage);
meanRmsePerPixel = mean(rmsePerPixel);


fileList = {trainImages.Files, testImages.Files};

save('211003_CNN.mat','net', 'fileList', 'pred', '-v7.3');

%figure
%scatter(predMAP,trueMAP,'+')
%xlabel("Predicted MAP")
%ylabel("True MAP")

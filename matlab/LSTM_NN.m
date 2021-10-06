addSubPaths();

% trainedStuff = load('211004_LSTM_1.mat');

% lstmNN = trainedStuff.lstmNN;


if ~exist('LSTMTimeSeriesData.mat')
	segmented_file_dir = "../physionet.org/segmented_data/";

	disp('Reading data...');

   fileList = dir(segmented_file_dir+"*.txt");

   allData = cell(1,length(fileList));

   minLength = Inf;

   for idx = 1:length(fileList)
       data = importdata(segmented_file_dir + fileList(idx).name); 
       allData{idx} = data;
       minLength = min(minLength, length(data));
   end

   Fs = 125;
   Ts = 1/Fs;

   disp('Generating input and output sequences...');

   minTime = Ts*minLength;

   Fs_new = 25;
   Ts_new = 1/Fs_new;
   nT = round(Ts_new/Ts);

   ppgData = cell(length(fileList),1);
   abpData = cell(length(fileList),1);

   abpOutData = cell(length(fileList),1);

   outSampledPoints = 1:nT:minLength;
    
   length10s = 10/Ts;
   length8s = 8/Ts;
   
   minLength = length10s;
   outSampledPoints = (length8s+1):nT:minLength;
   
   parfor idx = 1:length(fileList)
       data = allData{idx};
       ppgData{idx} = data(1:minLength,3);
       abpData{idx} = data(1:minLength,2);
    
       abpOutData{idx} = data(outSampledPoints, 2);
   end

   ppgMean = mean(mean(reshape(cell2mat(ppgData),[minLength length(fileList)])));
   ppgRange = mean(range(reshape(cell2mat(ppgData),[minLength length(fileList)])));

   abpMean = mean(mean(reshape(cell2mat(abpData),[minLength length(fileList)])));
   abpRange = mean(range(reshape(cell2mat(abpData),[minLength length(fileList)])));
   
   
   parfor idx = 1:length(fileList)
       ppgData{idx} = (ppgData{idx}-ppgMean)./ppgRange;
       abpData{idx} = (abpData{idx}-abpMean)./abpRange;

       abpOutData{idx} = (abpOutData{idx}-abpMean)./abpRange;
   end

   save('LSTMTimeSeriesData.mat','ppgData','abpData','abpOutData','ppgMean','ppgRange','abpMean','abpRange');
else
	disp('Reading data from mat file...');
	dataMatFile = load('LSTMTimeSeriesData.mat');
	ppgData = dataMatFile.ppgData;
	abpData = dataMatFile.abpData;
	abpOutData = dataMatFile.abpOutData;
	ppgMean = dataMatFile.ppgMean;
	ppgRange = dataMatFile.ppgRange;
	abpMean = dataMatFile.abpMean;
    abpRange = dataMatFile.abpRange;
end


partition_variable = cvpartition(height(ppgData), "Holdout",0.25);

%trainingIndices = trainedStuff.trainTestIndices{1};
trainingIndices = training(partition_variable);
trainInput = ppgData(trainingIndices,:);
trainOutput = abpOutData(trainingIndices,:);

%testIndices = trainedStuff.trainTestIndices{2};
testIndices = test(partition_variable);
testInput = ppgData(testIndices,:);
testOutput = abpOutData(testIndices,:);

numInPoints = size(trainInput{1}, 1);
numOutPoints = size(trainOutput{1},1);

numHiddenUnits = 600;

disp('Creating NN...');

layers = [ ...
    sequenceInputLayer(numInPoints, 'Normalization', 'None')
    lstmLayer(256, 'OutputMode','sequence')
    dropoutLayer(0.2)
    lstmLayer(256, 'OutputMode','sequence')
    dropoutLayer(0.2)
    lstmLayer(256,'OutputMode','sequence')
    dropoutLayer(0.2)
    lstmLayer(256,'OutputMode','sequence')
    dropoutLayer(0.2)
    fullyConnectedLayer(numOutPoints)
    regressionLayer];

maxEpochs = 5;
miniBatchSize = 5;

options = trainingOptions('sgdm', ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'InitialLearnRate',0.1, ...
    'ExecutionEnvironment', 'gpu', ...
    'GradientThreshold',1, ...
    'Shuffle','never', ...
    'Verbose',1);

disp('Training NN...');

[lstmNN, lstmInfo] = trainNetwork(trainInput,trainOutput,layers,options);

disp('Evaluating performance...');

predOutput = predict(lstmNN,testInput, 'MiniBatchSize',miniBatchSize);

pearsonCoeffs = zeros(length(testOutput),1);

for i = 1:length(pearsonCoeffs)
    pearsonCoeffs(i) = pearsonCoeff(predOutput{i}, testOutput{i});
end

meanPearsonCorrelation = mean(pearsonCoeffs)

predBP = reshape(cell2mat(predOutput),[numOutPoints length(predOutput)]);
trueBP = reshape(cell2mat(testOutput),[numOutPoints length(predOutput)]);

predBP = (predBP.*abpRange)+abpMean;
trueBP = (trueBP.*abpRange)+abpMean;

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

save('211004_LSTM_1.mat', 'lstmNN', 'trainTestIndices');

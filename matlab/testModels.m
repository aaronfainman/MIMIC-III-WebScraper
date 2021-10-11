addSubPaths();

disp('Reading data from mat file...');
if (~exist("dataMatFile"))
dataMatFile = load('timeObservationsWithLastSecond.mat');
ppgData = dataMatFile.inputFeats;
abpOutData = dataMatFile.outputFeatsWave;

% [SBP, DBP, MAP]
abpVals = dataMatFile.outputFeatsBP;

normFactors = dataMatFile.normFactors;

ppgMean = normFactors('PPGAmpMean');
ppgRange = normFactors('PPGAmpScale');
abpMean = normFactors('ABPAmpMean');
abpRange = normFactors('ABPAmpScale');


disp('Separating train and test data...');
% partition_variable = cvpartition(height(ppgData), "Holdout",0.25);

% trainingIndices = dataMatFile.trainingIndices;
% trainInput = num2cell(ppgData(trainingIndices,:)',1)';
% trainOutput = num2cell(abpOutData(trainingIndices,:)',1)';
% trainOutputBP = dataMatFile.trainOutputT;

testIndices = dataMatFile.testIndices;
testInput = num2cell(ppgData(testIndices,:)',1)';
testOutput = num2cell(abpOutData(testIndices,:)',1)';
testOutputBP = dataMatFile.testOutputT;

% validateIndices = dataMatFile.validIndices;
% validateInput = num2cell(ppgData(validateIndices,:)',1)';
% validateOutput = num2cell(abpOutData(validateIndices,:)',1)';
% validateOutputBP = dataMatFile.validOutputT;

trueBP = abpOutData(testIndices,:).*abpRange + abpMean;
end

if (~exist("nnetWave") || ~exist("nnetBP"))
disp('Loading neural nets...');
nnetWave = load('biLSTM_pearson_211010_3runs.mat').netLSTM;
nnetBP = load('TrainedModels/netRetrainedOnAll3_extradata.mat').net_retrain2;
end

numObs = length(testInput);

n = 15;

rnd = randperm(numObs, n);

abpOuts = cell(1, n);

for i = 1:n
    abpOuts{i} = determineABP(testInput{rnd(i)}, nnetWave, nnetBP, [abpRange abpMean]);
end

pearsonCoeffs = zeros(1,n);
mae = zeros(1,n);

for i = 1:n
    pearsonCoeffs(i) = pearsonCoeff(abpOuts{i}, trueBP(rnd(i),:)');
    mae(i) = mean(abs(abpOuts{i} - trueBP(rnd(i),:)'));
end
	
figure;
for i = 1:n
    subplot(3,5,i);
    plot(trueBP(rnd(i),:));
    hold on;
    plot(abpOuts{i});
    hold off;
    title("Test " + rnd(i));
    xlabel("MAE = " + mae(i) +", P = " + pearsonCoeffs(i))
end

disp('Figures plotted.');





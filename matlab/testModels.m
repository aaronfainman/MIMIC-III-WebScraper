addSubPaths();

disp('Reading data from mat file...');
if (~exist("dataMatFile"))
dataMatFile = load('FinalNetworks/WaveformsExtendedData.mat');
ppgData = dataMatFile.inputFeats;
abpOutData = dataMatFile.outputFeatsWave;
abpVals = dataMatFile.outputFeatsBP;

disp('Getting test data...');

testIndices = dataMatFile.testIndices;
testInput = num2cell(ppgData(testIndices,:)',1)';
testOutput = num2cell(abpOutData(testIndices,:)',1)';
testOutputBP = abpOutData(testIndices,:);


end

disp('Loading neural nets...');
nnets = load('FinalNetworks/nnets.mat').nnets;

trueBP = abpOutData(testIndices,:).*nnets.abpScale + nnets.abpMean;

%%
numObs = length(testInput);

abpOuts = cell(numObs, 1);

for i = 1:numObs
    abpOuts{i} = predictABP(testInput{i}, nnets, 1);
end

pearsonCoeffs = zeros(1,numObs);
mae = zeros(1,numObs);

for i = 1:numObs
    pearsonCoeffs(i) = pearsonCoeff(abpOuts{i}, trueBP(i,:)');
    mae(i) = mean(abs(abpOuts{i} - trueBP(i,:)'));
end
	
figure;

n = 15;

%rnd = [3134, 3181, 2813, 1225, 2864, 707, 3104, 3018]
rnd = randperm(numObs, n);
for i = 1:n
    subplot(3,5,i);
    plot(trueBP(rnd(i),:));
    hold on;
    plot(abpOuts{rnd(i)});
    hold off;
 %  title("Test " + rnd(i));
 %  xlabel("MAE = " + mae(i) +", P = " + pearsonCoeffs(i))
end

disp('Figures plotted.');





addSubPaths();

disp('Reading data from mat file...');
if (~exist("dataMatFile"))
dataMatFile = load('timeObservationsWithLastSecond.mat');
ppgData = dataMatFile.inputFeats;
abpOutData = dataMatFile.outputFeatsWave;


featsFile = load('FeatureObservationsExtendedFeats.mat');

ppgFeats = featsFile.inputFeatsExt;

% [SBP, DBP, MAP]
abpVals = dataMatFile.outputFeatsBP;

disp('Getting test data...');

testIndices = featsFile.testIndices;
testInput = num2cell(ppgData(testIndices,:)',1)';
testFeats = featsFile.testInput;
testOutput = num2cell(abpOutData(testIndices,:)',1)';
testOutputBP = dataMatFile.testOutputT;

end

disp('Loading neural nets...');
nnets = load('FinalNetworks/nnets.mat').nnets;

trueBP = abpOutData(testIndices,:).*nnets.abpScale + nnets.abpMean;

%%
numObs = length(testInput);

n = 8;

rnd = [3134, 3181, 2813, 1225, 2864, 707, 3104, 3018]

abpOuts = cell(1, n);

for i = 1:n
    abpOuts{i} = predictABP(testInput{rnd(i)}, testFeats(i,:), nnets);
end

pearsonCoeffs = zeros(1,n);
mae = zeros(1,n);

for i = 1:n
    pearsonCoeffs(i) = pearsonCoeff(abpOuts{i}, trueBP(rnd(i),:)');
    mae(i) = mean(abs(abpOuts{i} - trueBP(rnd(i),:)'));
end
	
figure;
for i = 1:n
    subplot(2,4,i);
    plot(trueBP(rnd(i),:));
    hold on;
    plot(abpOuts{i});
    hold off;
 %  title("Test " + rnd(i));
 %  xlabel("MAE = " + mae(i) +", P = " + pearsonCoeffs(i))
end

disp('Figures plotted.');





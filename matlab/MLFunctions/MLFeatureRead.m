function [inputFeats, outputFeats, normFactors] = MLFeatureRead(inputFile, outputFile, normFactorFile)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if (nargin < 3)
    normFactorFile = 'NormalisationFactors.mat';
end
if (nargin < 2)
    outputFile = '../physionet.org/outputFeatures.csv';
end
if (nargin < 1)
    inputFile = '../physionet.org/inputFeatures.csv';
end

inputFeats = readtable(inputFile);
% remove all non-numeric columns - an extra string column often added to
% end of input csv file
inputFeatsVarTypes = varfun(@class,inputFeats, 'OutputFormat', 'cell');
numVars=0;
varsToRemove = {};
for idx=1:length(inputFeatsVarTypes)
    if( strcmp(inputFeatsVarTypes{idx}, 'double') )
        continue;
    end
    numVars = numVars+1;
    varsToRemove(numVars) = inputFeats.Properties.VariableNames(idx);
end
inputFeats = removevars(inputFeats, varsToRemove);


outputFeats = readtable(outputFile);
% remove all non-numeric columns - extra string columns often added to
% end of input csv file
outputFeatsVarTypes = varfun(@class,outputFeats, 'OutputFormat', 'cell');
numVars=0;
varsToRemove = {};
for idx=1:length(outputFeatsVarTypes)
    if( strcmp(outputFeatsVarTypes{idx}, 'double') )
        continue;
    end
    numVars = numVars+1;
    varsToRemove(numVars) = outputFeats.Properties.VariableNames(idx);
end
outputFeats = removevars(outputFeats, varsToRemove);

%remove missing values from input and output rows (must be removed
%simultaneously so inputs and outputs correctly correspond
inputMissingRows = find(any(ismissing(inputFeats),2));
outputMissingRows = find(any(ismissing(outputFeats),2));
allMissingRows = [inputMissingRows; outputMissingRows];
inputFeats(allMissingRows, :) = [];
outputFeats(allMissingRows, :) = [];
fprintf("Removed %i rows from data", length(allMissingRows)); 

normFactors = load(normFactorFile);
normFactors = normFactors.normFactors;

if(height(inputFeats)~= height(outputFeats))
    fprintf('Warning: feature files have different numbers of observations.\n');
end
fprintf('input features has %i rows and %i columns \n',height(inputFeats), width(inputFeats) );
fprintf('output features has %i rows and %i columns \n',height(outputFeats), width(outputFeats) );

end


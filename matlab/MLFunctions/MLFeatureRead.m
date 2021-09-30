function [inputFeats, outputFeats, normFactors] = MLFeatureRead()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

inputFeats = readtable('../physionet.org/inputFeatures.csv');
% remove all non-numeric columns - an extra string column often added to
% end of input csv file
inputFeatsVarTypes = varfun(@class,inputFeats, 'OutputFormat', 'cell');
for idx=1:length(inputFeatsVarTypes)
    if( strcmp(inputFeatsVarTypes{idx}, 'double') )
        continue;
    end
    varNames = inputFeats.Properties.VariableNames;
    inputFeats = removevars(inputFeats, varNames(idx));
end


outputFeats = readtable('../physionet.org/outputFeatures.csv');
% remove all non-numeric columns - an extra string column often added to
% end of input csv file
outputFeatsVarTypes = varfun(@class,outputFeats, 'OutputFormat', 'cell');
for idx=1:length(outputFeatsVarTypes)
    if( strcmp(outputFeatsVarTypes{idx}, 'double') )
        continue;
    end
    varNames = outputFeats.Properties.VariableNames;
    outputFeats = removevars(outputFeats, varNames(idx));
end

normFactors = load('NormalisationFactors.mat');
normFactors = normFactors.normFactors;

if(height(inputFeats)~= height(outputFeats))
    fprintf('Warning: feature files have different numbers of observations.\n');
end
fprintf('input features has %i rows and %i columns \n',height(inputFeats), width(inputFeats) );
fprintf('output features has %i rows and %i columns \n',height(outputFeats), width(outputFeats) );

end


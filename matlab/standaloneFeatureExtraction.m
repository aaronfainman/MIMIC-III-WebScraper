function [] = standaloneFeatureExtraction()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
addSubPaths();
opts = readOptionsStruct();

inputFeatFile = fopen(opts.input_feature_file, 'w');
outputFeatFile = fopen(opts.output_feature_file, 'w');

fileList = dir(opts.segmented_file_dir+"*.txt");

numFiles = length(fileList);

%Run the feature extraction once to get the column headings
[inputFeats, outputFeats] = fullInputOutputFeatureExtraction(fileList(1).name,opts);
writeMapKeysToFile(inputFeatFile, inputFeats, " %10s, ");
fprintf(inputFeatFile,"\n");
writeMapKeysToFile(outputFeatFile, outputFeats, " %10s, ");
fprintf(outputFeatFile,"\n");

fprintf("\n Extracting features from %i files.\n", numFiles);
fprintf("Current file:       ");

%if we want to parallelise this we need to be careful about parallel file
%writing
for (idx = 1:numFiles)
    fprintf('\b\b\b\b\b%5i', idx)

    [inputFeats, outputFeats] = fullInputOutputFeatureExtraction(fileList(idx).name,opts);
    
    writeMapValuesToFile(inputFeatFile, inputFeats, " %3.7f, ");
    fprintf(inputFeatFile,"\n");

    writeMapValuesToFile(outputFeatFile, outputFeats, " %3.7f, ");
    fprintf(outputFeatFile,"\n");
end


fclose(outputFeatFile);
fclose(inputFeatFile);

end


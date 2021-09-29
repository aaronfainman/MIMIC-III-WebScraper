function [] = standaloneFeatureExtraction()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

addSubPaths();
opts = readOptionsStruct();

featFilePermissions = 'a';
if(opts.overwrite_feature_files); featFilePermissions='w'; end;

inputFeatFile = fopen(opts.input_feature_file, featFilePermissions);
outputFeatFile = fopen(opts.output_feature_file, featFilePermissions);

fileList = dir(opts.segmented_file_dir+"*.txt");

numFiles = length(fileList);

%Run the feature extraction once to get the column headings if overwriting
%feature files
if(opts.overwrite_feature_files)
    fprintf("\n Features files being overwritten... \n")
    [inputFeats, outputFeats] = fullInputOutputFeatureExtraction(fileList(1).name,opts);
    writeMapKeysToFile(inputFeatFile, inputFeats, " %10s, ");
    fprintf(inputFeatFile,"\n");
    writeMapKeysToFile(outputFeatFile, outputFeats, " %10s, ");
    fprintf(outputFeatFile,"\n");
end

start_idx = opts.start_idx_segment2feature;
end_idx = opts.end_idx_segment2feature;
if(end_idx==-1); end_idx = numFiles; end;

fprintf("\n Extracting features from %i files (%i - %i) of available %i files.\n", end_idx-start_idx+1, start_idx, end_idx, numFiles);
fprintf("Current file:        ");

%if we want to parallelise this we need to be careful about parallel file
%writing
for (idx = start_idx:end_idx)
    fprintf('\b\b\b\b\b\b%6i', idx)

    [inputFeats, outputFeats] = fullInputOutputFeatureExtraction(fileList(idx).name,opts);
    
    writeMapValuesToFile(inputFeatFile, inputFeats, " %3.7f, ");
    fprintf(inputFeatFile,"\n");

    writeMapValuesToFile(outputFeatFile, outputFeats, " %3.7f, ");
    fprintf(outputFeatFile,"\n");
end
fprintf("\n Completed successfully. \n")

fclose(outputFeatFile);
fclose(inputFeatFile);

end


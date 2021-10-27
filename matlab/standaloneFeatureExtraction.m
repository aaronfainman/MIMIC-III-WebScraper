function [inputWave, outputWave] = standaloneFeatureExtraction()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

addSubPaths();
opts = readOptionsStruct();

featFilePermissions = 'a';
if(opts.overwrite_feature_files); featFilePermissions='w'; end;

% inputFeatFile = fopen(opts.input_feature_file, featFilePermissions);
% outputFeatFile = fopen(opts.output_feature_file, featFilePermissions);

fileList = dir(opts.segmented_file_dir+"*.txt");

numFiles = length(fileList);

%Run the feature extraction once to get the column headings if overwriting
%feature files
% if(opts.overwrite_feature_files)
%     fprintf("\n Features files being overwritten... \n")
%     [inputFeats, outputFeats] = fullInputOutputFeatureExtraction(fileList(1).name,opts);
%     writeMapKeysToFile(inputFeatFile, inputFeats, " %10s, ");
%     fprintf(inputFeatFile,"\n");
%     writeMapKeysToFile(outputFeatFile, outputFeats, " %10s, ");
%     fprintf(outputFeatFile,"\n");
% end

start_idx = opts.start_idx_segment2feature;
end_idx = opts.end_idx_segment2feature;
if(end_idx==-1); end_idx = numFiles; end;

fprintf("\n Extracting features from %i files (%i - %i) of available %i files.\n", end_idx-start_idx+1, start_idx, end_idx, numFiles);
fprintf("Current file:        ");


%%%% -----
normFactors = load('NormalisationFactors.mat').normFactors;
inputWave = zeros(end_idx,1250);
outputWave = zeros(end_idx,25);
%%%% -----


%if we want to parallelise this we need to be careful about parallel file
%writing
% parpool;

parfor (idx = start_idx:end_idx)
    fprintf('\b\b\b\b\b\b%6i', idx)

    t = getCurrentTask();

    inFileName = char(opts.input_feature_file);
    outFileName = char(opts.output_feature_file);

    inputFeatFile = fopen(string(inFileName(1:30))+num2str(t.ID)+".csv", 'a');
    outputFeatFile = fopen(string(outFileName(1:31))+num2str(t.ID)+".csv", 'a');

    [inputFeats, outputFeats] = fullInputOutputFeatureExtraction(fileList(idx).name,opts);
    
    writeMapValuesToFile(inputFeatFile, inputFeats, " %3.7f, ");
    fprintf(inputFeatFile,"\n");

    writeMapValuesToFile(outputFeatFile, outputFeats, " %3.7f, ");
    fprintf(outputFeatFile,"\n");


    dataFile = fopen(opts.segmented_file_dir + fileList(idx).name);

    data = cell2mat(textscan( dataFile, ...
     '%f %f %f', 'TreatAsEmpty', '-', 'EmptyValue', 0));

    inputWave(idx, :) = (interp1(data(:,1), data(:,2), linspace(0,10,1250))-normFactors('PPGAmpMean'))./normFactors('PPGAmpScale');
    outputWave(idx, :) = (interp1(data(:,1), data(:,3), linspace(9,10,25))-normFactors('ABPAmpMean'))./normFactors('ABPAmpScale');

    fclose(outputFeatFile);
     fclose(inputFeatFile);

end
fprintf("\n Completed successfully. \n")

% fclose(outputFeatFile);
% fclose(inputFeatFile);

end


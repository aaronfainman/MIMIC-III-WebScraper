function [outputArg1,outputArg2] = writeMapKeysToFile(fileID, keyValMap, formatSpec)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

allKeys = keyValMap.keys;
for i=1:keyValMap.Count
    fprintf(fileID, formatSpec, allKeys{i});
end
end
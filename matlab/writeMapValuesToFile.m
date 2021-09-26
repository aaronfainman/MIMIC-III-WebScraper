function [outputArg1,outputArg2] = writeMapValuesToFile(fileID, keyValMap, formatSpec)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
allKeys = keyValMap.keys;
for i=1:keyValMap.Count
    fprintf(fileID,formatSpec, keyValMap(allKeys{i}));
end

end
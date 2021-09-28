function [] = addSubPaths()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


fileList = dir();
folderList = fileList([fileList.isdir]);

for idx = 1:length(folderList)
    if(strcmp(string(folderList(idx).name),".."));continue; end;
    if(strcmp(string(folderList(idx).name),"."));continue; end;
    addpath(folderList(idx).name);
end


end


function [] = standaloneFilterAndSegment()
%STANDALONEFILTERANDSEGMENT Summary of this function goes here
%   Detailed explanation goes here

addSubPaths();
opts = readOptionsStruct();
filterAndSegment(opts);

end


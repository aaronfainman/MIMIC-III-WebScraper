function opts = readOptionsStruct(fullFileName)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

if(nargin==0)
    fullFileName = "options.json";
end

dataFile = fopen(fullFileName);
json_options = fscanf(dataFile, "%s");

opts = jsondecode(json_options);

%convert character arrays to string arrays
allOptsFields = fieldnames(opts);
for idx = 1:numel(allOptsFields)
    if( ischar( opts.(allOptsFields{idx}) ) )
        opts.(allOptsFields{idx}) = string(opts.(allOptsFields{idx}));
    end
end

end
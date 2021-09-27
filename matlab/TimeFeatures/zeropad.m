function [pad_arr] = zeropad(arr,num, dir)
%ZEROPAD Summary of this function goes here
%   Detailed explanation goes here
pad_size = [1,num];
dim=2;
if(size(arr) == [numel(arr), 1])
    dim=1;
    pad_size = [num,1];
end

if(dir=="pre")
   pad_arr = cat(dim,zeros(pad_size), arr);
else
    pad_arr = cat(dim,arr, zeros(pad_size));
end

end


function data = readPPG(s, numData)

if nargin < 2
    numData = 1;
end

data = zeros(numData,2);
for i = 1:numData
    comData = readline(s);
    data(i,:) = cell2mat(textscan(comData, '%f %f'));
end

end


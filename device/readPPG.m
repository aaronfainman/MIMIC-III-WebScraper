function data = readPPG(s)

comData = readline(s);

data = textscan(comData, '%f %f %f');

data = cell2mat(data);
data(1) = data(1)/1000;
end


function data = readPPG(s)

comData = readline(s);

data = textscan(comData, '%f %f');

data = cell2mat(data);
end


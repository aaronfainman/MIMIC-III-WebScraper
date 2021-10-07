function [allData, dataPerSegment] = generateObservations(opts, saveFlag)
% Splits the data up into observations for ML training. Creates cell arrays
% which have all observations and one grouped by segment (i.e. each segment
% cell will have continuous outputs from cell to cell)
addSubPaths();

Fs = opts.sampling_freq;
Ts = 1/Fs;

Fs_new = opts.downsampling_freq;
Ts_new = 1/Fs_new;
nT = round(Ts_new/Ts);

inputTime = opts.input_time;
outputTime = opts.output_time;

ppgStart_i = 0;
ppgEnd_i = inputTime;
abpStart_i = inputTime - outputTime;

inputWindow = inputTime/Ts;
outputWindow = outputTime/Ts;

fileList = dir(opts.segmented_file_dir+"*.txt");

allData = {};
dataPerSegment = cell(length(fileList), 1);

parfor i = 1:length(fileList)
    data = importdata(opts.segmented_file_dir + fileList(i).name);
    
    ppgData = data(:,3);
    abpData = data(:,2);
    
    ppgStart = ppgStart_i;
    ppgEnd = ppgEnd_i;
    abpStart = abpStart_i;
    
    numObsInSegment = fix((length(ppgData(:,1)) - inputWindow)/outputWindow) + 1;
     
    obsInSegment = cell(1, numObsInSegment);
    
    for j = 1:numObsInSegment
        outSampledPoints = (abpStart/Ts+1):nT:(ppgEnd/Ts);
        
        ppgObs = ppgData((ppgStart/Ts +1):(ppgEnd/Ts));
        abpObs = abpData((abpStart/Ts +1):(ppgEnd/Ts));
        
        abpOutObs = abpData(outSampledPoints);
        
        [~,~, sbpObs, dbpObs, mapObs] = findABPPeaks(abpObs, Ts, 0,0);
        
        obsInSegment{1,j} = {ppgObs, abpOutObs, [dbpObs; mapObs; sbpObs]};  
        
        ppgStart = ppgStart + outputTime;
        ppgEnd = ppgEnd + outputTime;
        abpStart = abpStart + outputTime;
    end
    
    dataPerSegment{i, 1} = obsInSegment;
end

for i = 1:length(dataPerSegment)
    allData = vertcat(allData,(dataPerSegment{i})');
end

if (saveFlag)
    save('observationData.mat', 'allData', 'dataPerSegment');
end

end


function [allData, dataPerSegment, ppgNorms, abpNorms] = generateObservations(opts, saveFlag)
% Splits the data up into observations for ML training. Creates cell arrays
% which have all observations and one grouped by segment (i.e. each segment
% cell will have continuous outputs from cell to cell)
addSubPaths();

normFacs = load('NormalisationFactors.mat').normFactors;

ppgNorms = [normFacs('PPGAmpMean') normFacs('PPGAmpScale')];
abpNorms = [normFacs('ABPAmpMean') normFacs('ABPAmpScale')];

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

shift = opts.overlap*inputTime;

inputWindow = inputTime/Ts;
outputWindow = outputTime/Ts;

fileList = dir(opts.segmented_file_dir+"*.txt");

allData = struct;
dataPerSegment = cell(length(fileList), 1);

parfor i = 1:length(fileList)
    data = importdata(opts.segmented_file_dir + fileList(i).name);
    
    ppgData = data(:,3);
    abpData = data(:,2);
    
    ppgStart = ppgStart_i;
    ppgEnd = ppgEnd_i;
    abpStart = abpStart_i;
    
    numObsInSegment = fix((length(ppgData(:,1)) - inputWindow)/(shift/Ts)) + 1;
     
    obsInSegment = cell(1, numObsInSegment);
    
    for j = 1:numObsInSegment
        outSampledPoints = (abpStart/Ts+1):nT:(ppgEnd/Ts);
        
        ppgObs = (ppgData((ppgStart/Ts +1):(ppgEnd/Ts))-ppgNorms(1))./ppgNorms(2);
        abpObs = (abpData((abpStart/Ts +1):(ppgEnd/Ts))-abpNorms(1))./abpNorms(2);
        
        abpOutObs = (abpData(outSampledPoints)-abpNorms(1))./abpNorms(2);
        
        [~,~, sbpObs, dbpObs, mapObs] = findABPPeaks(abpObs, Ts, 0,0);
        
        obsInSegment{1,j} = {ppgObs, abpOutObs, [dbpObs; mapObs; sbpObs]};  
        
        ppgStart = ppgStart + shift;
        ppgEnd = ppgEnd + shift;
        abpStart = abpStart + shift;
    end
    
    dataPerSegment{i, 1} = obsInSegment;
end

allData.ppg = [];
allData.abpWave = [];
allData.abpDiscrete = [];
for i = 1:length(dataPerSegment)
    i
    dataSeg = dataPerSegment{i};
    for j = 1:length(dataSeg)
        allData.ppg = [allData.ppg; (dataSeg{j}{1})'];
        allData.abpWave = [allData.abpWave; (dataSeg{j}{2})'];
        allData.abpDiscrete = [allData.abpDiscrete; (dataSeg{j}{3})'];
    end
end

if (saveFlag)
    save('observationData.mat', 'allData', 'dataPerSegment', 'ppgNorms', 'abpNorms');
end

end


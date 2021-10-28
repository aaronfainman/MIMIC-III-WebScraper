
addSubPaths();

segmented_file_dir = "../physionet.org/segmented_data/";
images_dir = "../physionet.org/cwt_images";

if ~isfolder(images_dir)
    mkdir(images_dir);
end
if ~isfolder(fullfile(images_dir,"ABP"))
    mkdir(fullfile(images_dir,"ABP"));
end
if ~isfolder(fullfile(images_dir,"PPG"))
    mkdir(fullfile(images_dir,"PPG"));
end

Fs = 125;

fileList = dir(segmented_file_dir+"*.txt"); 

allData = cell(1,length(fileList));

minLength = Inf;

startId = 1;
endId = length(fileList);

parfor idx = startId:endId
    data = importdata(segmented_file_dir + fileList(idx).name); 
    allData{idx} = data;
    minLength = min(minLength, length(data));
end

fb = cwtfilterbank('SignalLength',minLength,'VoicesPerOctave',12, 'SamplingFrequency', Fs);

cwtSize = size(fb.wt(allData{1}(1:minLength,3)));

imSize = [224 224]

abpVals = zeros(endId-startId+1, 3);

parfor idx = startId:endId
   
    data = allData{idx};
    
    ppg = data(1:minLength,3);
    abp = data(1:minLength,2);
    
    cwtPPG = fb.wt(ppg);
    cfsPPG = abs(cwtPPG);
    
    %ppgCWTs(:,:,idx) = cwtPPG;

    im = ind2rgb(im2uint8(rescale(cfsPPG)),jet(128));
  
    imFileName = strcat(fileList(idx).name(1:end-4),'_','PPG','.jpg');
    imwrite(imresize(im, imSize),fullfile(images_dir,'PPG',imFileName));
    	

    abpVals(idx, :) = [max(abp), min(abp), mean(abp)];
    %cwtABP = fb.wt(abp);
    %cfsABP = abs(cwtABP);
    
    %abpCWTs(:,:,idx) = cwtABP;

    %im = ind2rgb(im2uint8(rescale(cfsABP)),jet(128));
  
    %imFileName = strcat(fileList(idx).name(1:end-4),'_','ABP','.jpg');
    %imwrite(imresize(im, imSize,fullfile(images_dir,'ABP',imFileName));

end

segmented_file_dir = "../physionet.org/segmented_data/";
images_dir = "../physionet.org/cwt_images";

disp("Reading images...");

allImages = imageDatastore(fullfile(images_dir,'PPG/'),'LabelSource', 'foldernames');

[trainImages, testImages] = splitEachLabel(allImages,0.8);

trainSize = length(trainImages.Files);

disp("Generating train and test I/O data...");

trainInput = zeros(224,224,3,trainSize, 'uint8');

parfor i = 1:trainSize
    trainInput(:,:,:,i) = readimage(trainImages,i);
end

testInput = zeros(224,224,3,length(testImages.Files), 'uint8');
parfor i = 1:length(testImages.Files)
    testInput(:,:,:,i) = readimage(testImages,i);
end

trainOutput = abpVals(1:trainSize, :);
testOutput = abpVals(trainSize+1:trainSize+length(testImages.Files),:);

abpScale = mean(abpVals(:,1) - abpVals(:,2));
abpMean = mean(abpVals(:,3));

save('CNN_data.mat','testInput', 'testOutput', 'trainInput', 'trainOutput', 'abpScale', 'abpMean', '-v7.3');


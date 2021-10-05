
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

ppgCWTs = tall(zeros(cwtSize(1), cwtSize(2), length(startId:endId)));
abpCWTs = tall(zeros(cwtSize(1), cwtSize(2), length(startId:endId)));

imSize = [224 224]

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
    
    cwtABP = fb.wt(abp);
    cfsABP = abs(cwtABP);
    
    %abpCWTs(:,:,idx) = cwtABP;

    im = ind2rgb(im2uint8(rescale(cfsABP)),jet(128));
  
    imFileName = strcat(fileList(idx).name(1:end-4),'_','ABP','.jpg');
    imwrite(imresize(im, imSize),fullfile(images_dir,'ABP',imFileName));

end

save('cwtData.mat','ppgCWTs','abpCWTs');


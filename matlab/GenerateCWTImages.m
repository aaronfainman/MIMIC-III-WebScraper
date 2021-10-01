
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

for idx = 1:length(fileList)
    data = importdata(segmented_file_dir + fileList(idx).name); 
    allData{idx} = data;
    minLength = min(minLength, length(data));
end

fb = cwtfilterbank('SignalLength',minLength,'VoicesPerOctave',12, 'SamplingFrequency', Fs);

for idx = 1:length(fileList)
    data = allData{idx};
    
    cfsPPG = abs(fb.wt(data(1:minLength,3)));
    
    im = ind2rgb(im2uint8(rescale(cfsPPG)),jet(128));
  
    imFileName = strcat(fileList(idx).name(1:end-4),'_','PPG','.jpg');
    imwrite(imresize(im,[1024 1024]),fullfile(images_dir,'PPG',imFileName));
    
    cfsABP = abs(fb.wt(data(1:minLength,2)));
    
    im = ind2rgb(im2uint8(rescale(cfsABP)),jet(128));
  
    imFileName = strcat(fileList(idx).name(1:end-4),'_','ABP','.jpg');
    imwrite(imresize(im,[1024 1024]),fullfile(images_dir,'ABP',imFileName));
end

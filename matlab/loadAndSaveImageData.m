addSubPaths();

segmented_file_dir = "../physionet.org/segmented_data/";
images_dir = "../physionet.org/cwt_images";

disp("Reading images...");

allImages = imageDatastore(fullfile(images_dir,'PPG/'),'LabelSource', 'foldernames');

[trainImages, testImages] = splitEachLabel(allImages,0.8);

trainSize = ceil(0.8*length(allImages.Files));

disp("Generating train and test I/O data...");

trainInput = zeros(1024,1024,3,trainSize, 'uint8');

parfor i = 1:length(trainImages.Files)
    trainInput(:,:,:,i) = readimage(trainImages,i);
end

testInput = zeros(1024,1024,3,length(allImages.Files) - trainSize, 'uint8');
parfor i = 1:length(testImages.Files)
    testInput(:,:,:,i) = readimage(testImages,i);
end

save('testTrainImageData.mat', 'trainImages', 'testImages', 'trainInput', 'testInput', '-v7.3');

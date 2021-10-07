addSubPaths();

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

save('testTrainImageDataPPG.mat', 'trainImages', 'testImages', 'trainInput', 'testInput', '-v7.3');

function [] = filterAndSegment(opts)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


%ORDER OF Preprocessing:
% 1. open both data and ABP files
% 2. filter data (LPF + hampel filter)
% 3. split data into "valid" regions ie. regions where there are
%      varying signals and not continuous flat lines (=> disconnected
%      instruments)
% 4. for every valid region: segment out fixed number of periods of
%      the signal
% 5. write every segment to a file
%       naming convention: <7 digit patient record no>_<4 digit record no>-<4 digit segment no>.txt
% 6. (Commented out) write each beat location for every segment to a file
%       naming convention: each same name as segment with a b at the end

if ~isfolder(opts.orig_file_dir)
    error("Original file directory not found")
end

if ~isfolder(opts.abp_ann_dir)
    error("ABP file directory not found")
end
fileList = dir(opts.orig_file_dir+"*.txt"); %only consider all text files

if ~isfolder(opts.segmented_file_dir)
    mkdir(opts.segmented_file_dir)
else
    if(opts.clear_segmented_dir)
        rmdir(opts.segmented_file_dir, 's')
        mkdir(opts.segmented_file_dir)
    end
end

if ~isfolder(opts.segmented_abp_dir)
    mkdir(opts.segmented_abp_dir)
else
    rmdir(opts.segmented_abp_dir, 's')
    mkdir(opts.segmented_abp_dir)
end


%Filter transfer function

[filt_num, filt_den] = butter(opts.filter.order, ...
    2*pi.*opts.filter.cutoff/(2*pi*opts.samp_freq), opts.filter.type);

if opts.last_record_process == -1
    opts.last_record_process = length(fileList)
end

parfor idx = opts.first_record_process:opts.last_record_process
    % *********** 1. open both data and ABP files ***********  
     dataFile = fopen(opts.orig_file_dir + fileList(idx).name);
     data = cell2mat(textscan( dataFile, ...
         '%f %f %f', 'TreatAsEmpty', '-', 'EmptyValue', 0));
     fclose(dataFile);

     
     abpAnnFile = fopen([opts.abp_ann_dir fileList(idx).name(1:end-4) '_abp.txt']);
     locOfAbpBeats = cell2mat(textscan( abpAnnFile, ...
         '%*s %d %*s %*d %*d %*d'));
     fclose(abpAnnFile);
   
    % *********** 2. filter data (LPF + hampel filter) ***********   
%     currently not filtering either signal for frequency analysis purposes
     if(opts.apply_filter); data(:,3) = filter(filt_num, filt_den, data(:,3)); end
     
     % Hampel filter to remove outliers
     if (opts.apply_hampel_abp); data(:,2) = hampel(data(:,2)); end
     if (opts.apply_hampel_ppg); data(:,3) = hampel(data(:,3)); end
    
    % *********** 3. split data into "valid" regions  *********** 
     invalidABPRegions = findInvalidABPRegions(data(:,2), locOfAbpBeats);
     
     abp_flats = findFlatRegionsFast(data(:,2), opts.flats.derivative_thresh,opts.flats.window, opts.flats.window_thresh);
     ppg_flats = findFlatRegionsFast(data(:,3), opts.flats.derivative_thresh,opts.flats.window, opts.flats.window_thresh);
     all_invalid = abp_flats | ppg_flats | invalidABPRegions;
     
     regioned_signals = {};
     [regioned_signals, num_regions] = removeInvalidFromSignal(all_invalid, opts.min_region_length, data(:,1), data(:,2), data(:,3));
     
     segmentedData=[];
 
     % ***********  4. for every valid region: segment out fixed number of periods of the signal
      for i=1:num_regions
          regioned_data = [regioned_signals{i}{1}{:},regioned_signals{i}{2}{:},regioned_signals{i}{3}{:}]
         segmentedFileData = segmentSignal(  [regioned_signals{i}{1}{:}, ...
             regioned_signals{i}{2}{:}, ...
             regioned_signals{i}{3}{:}], ...
             opts.num_periods_per_segment, 3);
         
         % ***********  5. write every segment to a file *********** 
         for x = 1:length(segmentedFileData)
             out_data = segmentedFileData{x};
             out_data(:,1) = segmentedFileData{x}(:,1) - segmentedFileData{x}(1,1);
             outPath = opts.segmented_file_dir+fileList(idx).name(1:end-4) + "-"+num2str(x,'%0.4d')+".txt";
             writematrix(out_data, outPath , 'Delimiter', 'tab');
             
             % ***********  6. write beats for every segment to a file *********** 
             %get location of ABP beats for segment - necessary for later
             %  feature extraction
%              shifted_beats = getABPBeatsFromSegment(segmentedFileData{x}(:,1), data(:,1), locOfAbpBeats);
%              outPath = opts.segmented_abp_dir+fileList(idx).name(1:end-4) + "-"+num2str(x,'%0.4d')+"b.txt";
%              writematrix(shifted_beats, outPath , 'Delimiter', 'tab');
         end
      end

end



end


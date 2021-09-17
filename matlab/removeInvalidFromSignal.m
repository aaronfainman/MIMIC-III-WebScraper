function [validRegions, num_regions] = removeInvalidFromSignal(invalidRegions, minimumSegmentLength, time, signal1, signal2)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%   disbaling error checks for quicker processing
% if( length(invalidRegions)~=length(signal1) ||  length(invalidRegions)~=length(signal2))
%     error("Signal lengths not all equal");
% end
% 
% if ~any(invalidRegions) %if there are no flats in the signal
%     validRegions = {{time},{signal1},{signal2}};
% end

%use |diff| to find changes between normal regions and flat (regions between
%two spikes are flat)
spike_indices = [find( [0; abs(diff(invalidRegions))] )]; %0 added to account for last of first index when taking diff


%need to find first valid index -> first index that is a zero in
%flatRegions
first_idx = find(1-invalidRegions, 1, 'first');
if first_idx == 1
    spike_indices = [1; spike_indices; length(invalidRegions)];
else 
    spike_indices = [first_idx; spike_indices(2:end); length(invalidRegions)];
end


validRegions = {{},{},{}};
num_regions = 0;

% extract non flats regions
% remove regions that are too small (<minimumSegmentLength)
for i=1:2:length(spike_indices)-1
    if spike_indices(i+1)-spike_indices(i) < minimumSegmentLength
        continue;
    end
    
    num_regions = num_regions+1;
    idx1 = spike_indices(i);
    idx2 = spike_indices(i+1);
    validRegions{num_regions} = { {time(idx1:idx2)}, {signal1(idx1:idx2)}, { signal2(idx1:idx2) } };
    
end

end


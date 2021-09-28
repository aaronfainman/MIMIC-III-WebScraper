function [segmentedPeriods, indices] = segmentSignal(data, numPeriodsPerSegment,  colOfTarget, keepWholeSignal)

% Segments a signal into a cells which contain a specified number of cycles
% of that signal.
% Issue: the 'min peak distance' used is selected through trial and error
% tested on a number of different regions in different files, and seems to
% work but may require some tweaking.

if (nargin < 2)
    error('Please provide data and number of periods per segment')
end
if (nargin < 3)
   colOfTarget = 1;
end
if (nargin < 4)
    keepWholeSignal = false;
end

segmentedPeriods = {};
indices = [];

target = data(:,colOfTarget);

[~,locsOfMin] = findpeaks(-target, 'MinPeakDistance',60);
%disp(length(locsOfMin))
for l = 1:numPeriodsPerSegment:(length(locsOfMin)-numPeriodsPerSegment)
    first = locsOfMin(l);
    last = locsOfMin(l + numPeriodsPerSegment) - 1;
    segmentedPeriods{end+1} = data(first:last, :);
    indices(end+1) = first;
end

% Preserve incomplete segments with not enough periods at the end of the signal
if (keepWholeSignal)
    if (numPeriodsPerSegment*length(segmentedPeriods) < length(locsOfMin))
        first = locsOfMin(numPeriodsPerSegment*length(segmentedPeriods)+1);
        last = locsOfMin(end);
        segmentedPeriods{end+1} = data(first:last, :);
        indices(end+1) = first;
    end
end





end


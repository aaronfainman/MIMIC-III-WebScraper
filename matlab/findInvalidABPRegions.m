function invalidRegions = findInvalidABPRegions(abpSignal, locationsOfAbpBeats, tolerance)
% Uses the data from the WFDB WABP function which detects valid ABP signals
% to find invalid regions in the ABP signal. Performs this by mapping the
% locations to the signals in a logical array and then taking the maximum
% and then taking the maximum within a sliding window.
% invalidRegions is a vector the length of the ABP signal where 1 = invalid
% region and 0 = valid region


if (nargin < 2)
    error('Please provide ABP signal and locations of beats as extracted from wabp annotation.');
elseif (nargin < 3)
    tolerance = 120;
end
    

beatLocs = zeros(size(abpSignal));
% Why are there sample numbers greater than the size of the signal??
locationsOfAbpBeats(locationsOfAbpBeats > length(abpSignal)) = [];

beatLocs(locationsOfAbpBeats) = 1;
beatLocs(length(abpSignal)+1:end) = [];

invalidRegions = ~movmax(beatLocs,[tolerance tolerance]);

% plot(invalidRegions);

end


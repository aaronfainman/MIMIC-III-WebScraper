function maxIndices = extractMaxFreqSpectrum(spectrum, numMax, excludeDC)

if (nargin < 2) 
    error('Please provide spectrum and desired number of maximums');
elseif (nargin < 3)
    excludeDC = 0;
end

[~, sortedInd] = sort(abs(spectrum), 'desc');

if excludeDC
    sortedInd(sortedInd==1) = [];
end

% localMaxima = islocalmax(abs(spectrum));
% localMaxima = localMaxima(sortedInd);
% 
% sortedInd(~localMaxima) = [];

if (numMax < length(sortedInd))
    sortedInd = sortedInd(1:numMax);
end

maxIndices = sortedInd;

end




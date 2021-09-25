function [pkIndices, pkFreqs, pkMags, pkPhases, pkAvgWidth, fftLength] = extractFrequencyPeaks(t, x, numComponents, phasesPerPeak)
[f, fftX] = singlesidedFFT(t, x);

psdX = (abs(fftX)).^2;
psdX(2:end) = psdX(2:end)/2;

[~,pkIndices, widths] = findpeaks(psdX, 'NPeaks', numComponents, "SortStr", "descend");

pkAvgWidth = mean(widths)* mean(diff(f));

pkIndices(end+1) = 1;
pkIndices = sort(pkIndices);

pkFreqs = f(pkIndices)';
pkMags = abs(fftX(pkIndices));

phasesOnSide = (phasesPerPeak-1)/2;

getPhases = @(vec, p) vec(p-phasesOnSide:p+phasesOnSide)';

pkPhases = zeros(1, phasesPerPeak);
angles = angle(fftX);

for i = 2:length(pkIndices)
    pkPhases = [pkPhases; getPhases(angles,pkIndices(i))];
end

fftLength = length(fftX);

end


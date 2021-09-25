function [pkIndices, pkFreqs, pkMags, pkPhases, bandwidth] = extractNFrequencyComponents(t, x, numComponents, bandwidth_criterion)
[f, fftX] = singlesidedFFT(t, x);

psdX = (abs(fftX)).^2;
psdX(2:end) = psdX(2:end)/2;

pkIndices = [1; extractMaxFreqSpectrum(abs(psdABP), numComponents, 0)]

pkAvgWidth = mean(widths)* mean(diff(f));

% pkIndices(end+1) = 1;

pkIndices = sort(pkIndices);

pkFreqs = f(pkIndices)';
pkMags = abs(fftX(pkIndices));

pkPhases = angle(fftX(pkIndices));

fftLength = length(fftX);

power = sum(psdX);

cumPower = cumsum(psdX)./power;
bandwidth = f(find(cumPower == bandwidth_criterion,1));

end


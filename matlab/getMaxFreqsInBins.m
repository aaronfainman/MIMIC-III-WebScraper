function indices = getMaxFreqsInBins(f, fftSignal, fPerBin, binWidth, maxFreq)

indices = [];

df = mean(diff(f));

bins = 0:binWidth:maxFreq;

for i = 1:(length(bins)-1)
    region = abs(fftSignal(f >= bins(i) & f < bins(i+1)));
    binInd = extractMaxFreqSpectrum(region, fPerBin, 0);
    startInd = find(f >= bins(i) & f < bins(i+1),1) - 1;
    binInd = binInd + startInd;
    
    indices = [indices; binInd];
end

end


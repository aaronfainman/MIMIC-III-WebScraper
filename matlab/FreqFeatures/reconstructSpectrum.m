function [f, X] = reconstructSpectrum(indices, freqX, magX, angX, L, Fs, gaussWidth)

gaussianPulse = @(x,mean, stddev) exp(-(((x-mean).^2)/(2*stddev.^2)));

fEnd = Fs/2;

f = ((0:(L-1)) * fEnd/L)';

mags = zeros(size(f));
phases = zeros(size(f));

stdDev = gaussWidth/2;

df = mean(diff(f));

freqGauss = (-5:5)*df;

pulseGauss = gaussianPulse(freqGauss, 0, stdDev)';     

pwLength = size(angX,2);

for p = 1:length(indices)
    if indices(p) == 1
        mags(1) = magX(1);
    else
        gpStart = indices(p)-5;
        gpEnd = gpStart+10;
        gpS = max(1,gpStart);
        gpE= min(gpEnd,length(f));
        
        mags(gpS:gpE) = mags(gpS:gpE) +  magX(p)*pulseGauss(gpS-gpStart+1:end-(gpE-gpEnd));
        
        pwStart = indices(p)- (pwLength - 1)/2;
        pwEnd = pwStart+pwLength-1;

        phases(pwStart:pwEnd) = phases(pwStart:pwEnd) + angX(p,:)';
    end
end

X = abs(mags).*exp(1i.*phases);
end


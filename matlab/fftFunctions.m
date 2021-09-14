function [freqVector, freqSpectrum] = doublesidedFFT(timeVector, timeSignal)
   n = length(timeVector);
   dT = mean(diff(timeVector));
   df = 1/dT;
   freqVector = (-n/2:(n/2-1))* (df/n);
   freqSpectrum = fftshift(fft(timeSignal))/df;
end

function [freqVector, freqSpectrum] = singlesidedFFT(timeVector, timeSignal)
   n = length(timeVector);
   dT = mean(diff(timeVector));
   df = 1/dT;
   %freqVector = (-n/2:(n/2-1))* (df/n);
   freqVector = (0:(n/2 -1)) * (df/n);
   freqSpectrum = fft(timeSignal)/df;
   freqSpectrum(n/2+1 : end) = [];
   freqSpectrum(2:end) = freqSpectrum(2:end) * 2;
end

function [timeVector, timeSignal] = doublesidedIFFT(freqVector, freqSpectrum)
   n = length(freqVector);
   df = mean(diff(freqVector))*n;
   dT = 1/df;
   timeVector = (0:(n-1))*dT/n;
   timeSignal = real(ifft(ifftshift(freqSpectrum)))*df;
end

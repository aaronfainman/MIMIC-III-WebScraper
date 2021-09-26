function [timeVector, timeSignal] = singlesidedIFFT(freqVector, freqSpectrum)
   n = length(freqVector)*2;
   Fs = mean(diff(freqVector))*n;
   dT = 1/Fs;
   timeVector = (0:(n-1))*dT;
   
   freqSpectrum(2:end) = freqSpectrum(2:end) * (1/2);
   
   if (size(freqSpectrum,1) == 1) 
       freqSpectrum = [freqSpectrum 0 conj(flip(freqSpectrum(2:end)))];
   else
       freqSpectrum = [freqSpectrum; 0; conj(flip(freqSpectrum(2:end)))];
   end
   
   timeSignal = real(ifft(freqSpectrum)).*n;
end


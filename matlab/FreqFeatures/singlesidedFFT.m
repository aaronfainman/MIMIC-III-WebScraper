function [freqVector, freqSpectrum] = singlesidedFFT(timeVector, timeSignal, pow2)
   if (nargin < 2)
       error('Please provide time and data vectors')
   elseif (nargin < 3)
       pow2 = false;
   end
   
   dT = mean(diff(timeVector));
   
   if (pow2)
       n = 2^nextpow2(length(timeVector));
   else 
       n = length(timeVector);
       if (mod(n,2) == 1)
           n = n+1;
           timeVector(end+1) = timeVector(end) + dT;
           timeSignal(end+1) = 0;
       end
   end
   
   Fs = 1/dT;
   freqVector = (0:(n/2 -1)) * (Fs/n);
   freqSpectrum = fft(timeSignal, n)./n;
   freqSpectrum(n/2+1 : end) = [];
   freqSpectrum(2:end) = freqSpectrum(2:end) * 2;
  
end


function [freqVector, pwrSpectrum] = singlesidedPSD(timeVector, timeSignal)
   [freqVector, freqSpectrum] = singlesidedFFT(timeVector, timeSignal);
   
   pwrSpectrum = (abs(freqSpectrum).^2)./2;
   
   pwrSpectrum(1) = pwrSpectrum(1)*2;
end


function [ppg_signal, SpO2, ratio_of_ratios] = getPPGfromChannels(red_channel, infrared_channel, ADC_bits, ADC_voltage)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


if(nargin <4)
    ADC_bits = 14;
end
if(nargin <5)
    V_ADC = 3.3;
end


R = red_channel./(2^ADC_bits-1).*V_ADC;
IR = infrared_channel./(2^ADC_bits-1).*V_ADC;

[~, lowerR] = envelope(R, 400, 'peak');
R_ac = R - lowerR;
[~, lowerIR] = envelope(IR, 400, 'peak');
IR_ac = IR - lowerIR;

ratio_of_ratios = mean(R_ac)/mean(lowerR)*mean(lowerIR)/mean(IR_ac)
SpO2 = 104-17./ratio_of_ratios;
ppg_signal = R_ac+IR_ac.*ratio_of_ratios;
ppg_signal = ppg_signal(end:-1:1);

end


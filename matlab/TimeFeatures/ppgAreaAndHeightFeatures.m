function [PA, IPA, AI] = ppgAreaAndHeightFeatures(ppg_wave, sortedFeatures)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% Pulse Area (PA) - total area between feet
% Inflection point area (IPA) - ratio of area post and pre dicrotic notch
%       (will use diastolic point as approximation for dicrotic notch)
% Augmentation Index (AI) : height of diastolic peak:height of systolic peak

PA = [];
IPA = [];
AI = [];
for i = 1:length(sortedFeatures)
    
    first_foot = sortedFeatures(i,1);
    last_foot = sortedFeatures(i,4);
    
    baselineMag = ppg_wave(first_foot);
    if(ppg_wave(first_foot)>ppg_wave(last_foot)); baselineMag = ppg_wave(last_foot);end;
    
%     last_sum_idx = last_foot;
%     if(ppg_wave(last_foot) < ppg_wave(first_foot))
%         %look backwards for point below ppg_wave's first foot
%         last_sum_idx = find( ppg_wave(first_foot:last_foot)>ppg_wave(first_foot));
%         last_sum_idx = last_sum_idx(end) + first_foot
%     end
    
    dias_loc = sortedFeatures(i,3);
    A1 = sum(abs( ppg_wave(first_foot:dias_loc) - baselineMag));
    A2 = sum(abs(ppg_wave(dias_loc:last_foot) - baselineMag ));
    
    PA(i) = A1+A2;
    IPA(i) = A2/A1;
    
    sys_loc = sortedFeatures(i,2);
    
    AI(i) = ppg_wave(dias_loc)/ppg_wave(sys_loc);
end

end


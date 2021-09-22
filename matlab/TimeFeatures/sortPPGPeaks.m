function [sortedFeatures] = sortPPGPeaks(sysLocs, diasLocs, feetLocs)
%UNTITLED Sort the systolic peaks, diastolic peaks and feet into an
%easy-to-analyse format

sortedFeatures =[];

numFeatures = 0;
for i=1:length(feetLocs)-1
   currFoot = feetLocs(i);
   nextFoot = feetLocs(i+1);
   
   currSysIdx = find( ((sysLocs>currFoot) & (sysLocs<nextFoot)) , 1);
   if(isempty(currSysIdx)); continue; end;
   currSys = sysLocs(currSysIdx);
   
   currDiasIdx = find( ((diasLocs>currSys) & (diasLocs<nextFoot)) , 1);
   if(isempty(currDiasIdx)); continue; end;
   currDias = diasLocs(currDiasIdx);
   
   numFeatures = numFeatures + 1;
   
   sortedFeatures(numFeatures, :) = [currFoot, currSys, currDias, nextFoot];
end

end


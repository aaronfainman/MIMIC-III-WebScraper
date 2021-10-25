clc;
clearvars

%% Initialise variables
% 
% if (exist('arduino','var')) 
%     clear arduino
% end

Fs = 125;
Ts = 1/Fs;

len = length(0:Ts:(10-Ts));
ppgData = zeros(len,1);
abpData = zeros(len,1);
abpPredData = zeros(250,1);
tData =  nan(len,1);
tDataPred =  nan(250,1);
dbp = zeros(1,5);
sbp = zeros(1,5);
map = zeros(1,5);

dataFile = fopen('3003521_0015-0003.txt');
data1 = cell2mat(textscan( dataFile, ...
 '%f %f %f', 'TreatAsEmpty', '-', 'EmptyValue', 0));
fclose(dataFile);
dataFile = fopen('3003521_0015-0004.txt');
data2 = cell2mat(textscan( dataFile, ...
 '%f %f %f', 'TreatAsEmpty', '-', 'EmptyValue', 0));
fclose(dataFile);
fulldata = [data1;data2];
fulldata(:,1) = (0:length(fulldata)-1).*Ts;

dataCount = 0;


window = figure(1);
subplot(3,1,1)
ppgPlot = plot(tData, ppgData, 'LineWidth',1.5);
ppgPlot.XDataSource = 'tData';
ppgPlot.YDataSource = 'ppgData';
xlabel('time (s)')
title("Photoplethysmogram")
set(gca, "FontSize", 13)
grid on;
subplot(3,1,2)
% abpPlot = plot(tData,abpData, 'LineWidth',1.5);
% abpPlot.XDataSource = 'tData';
% abpPlot.YDataSource = 'abpData';
% xlabel('time (s)')
% ylabel("Pressure (mmHg)")
% title("Actual Arterial Blood Pressure")
% set(gca, "FontSize", 13)
% grid on;
set(gca,'xtick',[],'ytick',[])
set(gca, 'color', 'none')
set(gca, 'XColor', 'none')
set(gca, 'YColor', 'none')


% abpPlot.XDataSource = 'tDataPred';
% abpPlot.YDataSource = 'abpPredData';

subplot(3,1,3)
annot_act=annotation('textbox',[0.32 0.4 .9 .2],'String',' ','EdgeColor','none');
annot_act.FontSize = 20;
set(gca,'xtick',[],'ytick',[])
set(gca, 'color', 'none')
set(gca, 'XColor', 'none')
set(gca, 'YColor', 'none')

% subplot(3,2,5)
abpPlotPred = plot(tDataPred,abpPredData, 'LineWidth',1.5);
abpPlotPred.XDataSource = 'tDataPred';
abpPlotPred.YDataSource = 'abpPredData';
xlabel('time (s)')
ylabel("Pressure (mmHg)")
title("Predicted Arterial Blood Pressure")
set(gca, "FontSize", 13)
grid on;
% subplot(3,2,6)
annot_pred=annotation('textbox',[.53 0.4 .85 .2],'String',' ','EdgeColor','none');
annot_pred.FontSize =20;
% set(gca,'xtick',[],'ytick',[])
% set(gca, 'color', 'none')
% set(gca, 'XColor', 'none')
% set(gca, 'YColor', 'none')

% scr_siz = get(0,'ScreenSize') ;

window.Position =  [250 100 1000 700];
% figure(floor([scr_siz(3)/2 scr_siz(4)/2 scr_siz(3)/2 scr_siz(4)/2])) ;


 button = uicontrol('Style','togglebutton','String','Stop',...
        'Position',[0 0 50 25], 'parent',window);

reading = true;
dataCount = 0;

 
%     nnets.dbp = load('timeAndWidthFeats_DBP.mat').featNet_dbp;
%     nnets.sbp = load('timeAndWidthFeats_SBP.mat').featNet_sbp;
%     nnets.map = load('timeAndWidthFeats_MAP.mat').featNet_map;
    normFactors = load('NormalisationFactors.mat').normFactors;
%     nnets.abpScale = normFactors('ABPAmpScale');
%     nnets.abpMean = normFactors('ABPAmpMean');
%     nnets.ppgScale = normFactors('PPGAmpScale');
%     nnets.ppgMean = normFactors('PPGAmpMean');
nnets = load('nnets.mat').nnets;
    

% [3134, 3181, 2813, 1225, 2864, 707, 3104, 3018]

%% Create and initialise serial connection with Arduino

% COM = "COM10";
% BAUD = 115200;
% 
% if (~exist('successFlag','var'))
%     [arduino, successFlag] = initConnection(COM, BAUD);
% end
% 
% if (successFlag == -1)
%     error("Error: Connection with device cannot be established!")
% end
% 
% if (successFlag == 0)
%     error("Error: Device failure.")
% end
% 
% if (successFlag == 1)
%     disp("Connection Established.")
% end

%%

% abpData initialisation
tic

saveData = [];

t = 0;
i=0;
while(get(button, 'Value') == 0)
    i = i+1;
    if(i == length(fulldata)); break; end;
    newData = fulldata(i,2:3);
    
    numData = height(newData);
    dataCount = dataCount + numData;
    
    saveData = [saveData; newData];
    
    if (dataCount < len)
        tData(dataCount-numData+1:dataCount) =  t;
        ppgData(dataCount-numData+1:dataCount) =  newData(:,2);
        abpData(dataCount-numData+1:dataCount) =  newData(:,1);
    else
        tData = [tData(numData+1:end); t];
        ppgData = [ppgData(numData+1:end); newData(:,2)];
        abpData = [abpData(numData+1:end); newData(:,1)];
    end
    
    t = t + Ts;
    
    % filter data // extract pulsatile component

    if(mod(dataCount, round(Fs/2)) == 0)% || mod(dataCount, Fs) == 0 ) % i.e. every second

        % abp determination
        
        % filter/fix parts of PPG that are strange
        if(dataCount > Fs*10)
            inputFeats = getInputFeaturesVideo(ppgData,125);
            if(isempty(inputFeats)); continue; end;
%             sbp = predict(nnets.sbp, inputFeats).*nnets.abpScale + nnets.abpMean
%             dbp = predict(nnets.dbp, inputFeats).*nnets.abpScale + nnets.abpMean
%             map = predict(nnets.map, inputFeats).*nnets.abpScale + nnets.abpMean
            
            [~, ~, actual_sbp, actual_dbp, actual_map] = findABPPeaks(abpData, 125,false,false);
            [abpWave, sbp_i, dbp_i, map_i] = predictABPVideo(ppgData, nnets, 0);
            dbp = [dbp(2:5), dbp_i];
            sbp = [sbp(2:5), sbp_i];
            map = [map(2:5), map_i];
            
           abpPredData = [abpPredData(25:end); abpWave];
%             abpWave = interp1( (0:length(abpWave)-1).*1./25,abpWave, (0:5*length(abpWave)-5).*1./125   )';
            [sys_full_wave, dias_full_wave] = findABPPeaks(abpData, 25,false,false);
            [sys_pred_wave, dias_pred_wave] = findABPPeaks(abpWave, 25,false,false);
% %             if(~isempty(sys_full_wave) && ~isempty(sys_pred_wave))
% %                  abpPredData = [abpPredData(25:dias_full_wave(end)); abpWave(1:end)];
% % %                  if(length(abpPredData)>250); abpPredData = abpPredData(end-250+1:end); end;
% % %                  if(length(abpPredData)<250); abpPredData = [abpPredData; ones(250-length(abpPredData),1).*abpPredData(end)]; end;
% %             else
% %                 abpPredData = [abpPredData(26:end); abpWave];
% %             end
%               abpPredData(end-25-5:end-25+5) = movmean(abpPredData(end-25-5:end-25+5),5);
%               if(t(1)>20); abpPredData = alignsignals(abpPredData, abpData); end;
% %             tDataPred =tData;
% %             abpPredData = abpWave;
% %             tDataPred = tData(end-5*length(abpPredData)+1:5:end)
            abpPredData = abpWave;
            start_time = tData(sys_full_wave(end-1)-sys_pred_wave(end)*5);
%             if( length(sys_pred_wave)>1 ); 3; end;
            end_time = start_time+1;
            tDataPred = linspace(start_time, end_time, 25);
            
            text =  "Actual SBP - " + num2str(round(actual_sbp)); 
            text =   text + "\n\n Actual DBP - " +num2str(round(actual_dbp));
            text =   text + "\n\n Actual MAP - " +num2str(round(actual_map));

            set(annot_act,'String',sprintf(text))

            text = "Predicted SBP - " + num2str(round(mean(sbp))); 
            text =  text + "\n\n Predicted DBP - " + num2str(round(mean(dbp)));
            text =  text + "\n\n Predicted MAP - " + num2str(round(mean(map)));
            set(annot_pred,'String',sprintf(text))

            subplot(3,1,1); xlim([tData(1), tData(1)+10]);
%             subplot(3,2,3); xlim([tData(1), tData(1)+10]);

            subplot(3,1,3); 
            hold on; plot(tData, abpData, '--k');xlim([tData(sys_full_wave(end-1))-1, tData(sys_full_wave(end-1))+1]);
            legend("Predicted ABP", "Actual ABP")
         end

        % update both PPG and ABP signal
        refreshdata
        drawnow limitrate
    end
%     pause(0.00000005);
end
toc



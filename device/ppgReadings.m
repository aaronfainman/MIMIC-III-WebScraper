clc;
clearvars
%% Create and initialise serial connection with Arduino

COM = "COM10";

if (~exist('successFlag','var'))
    [arduino, successFlag] = initConnection(COM);
end

if (successFlag == -1)
    error("Error: Connection with device cannot be established!")
end

if (successFlag == 0)
    error("Error: Device failure.")
end

if (successFlag == 1)
    disp("Connection Established.")
end

%% Initialise variables

Fs = 50;
Ts = 1/Fs;

len = length(0:Ts:(10-Ts));
redData = nan(len,1);
irData = zeros(len,1);
tData =  zeros(len,1);

dataCount = 0;

window = figure(1);
ppgPlot = plot(tData, redData);
ppgPlot.XDataSource = 'tData';
ppgPlot.YDataSource = 'redData';

grid on;

button = uicontrol('Style','togglebutton','String','Stop',...
        'Position',[0 0 50 25], 'parent',window);

reading = true;
dataCount = 0;
while (get(button,'Value') == 0)
    newData = readPPG(arduino);
    
    numData = height(newData);
    dataCount = dataCount + numData;
    
    if (dataCount < len)
        tData(dataCount-numData+1:dataCount) =  newData(:,1);
        redData(dataCount-numData+1:dataCount) =  newData(:,2);
        irData(dataCount-numData+1:dataCount) =  newData(:,3);
    else
        tData = [tData(numData+1:end); newData(:,1)];
        redData = [redData(numData+1:end); newData(:,2)];
        irData = [irData(numData+1:end); newData(:,3)];
    end
    
    refreshdata
    drawnow limitrate
end
    


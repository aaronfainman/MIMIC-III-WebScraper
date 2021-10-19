clc;
clearvars

%% Initialise variables

if (exist('arduino','var')) 
    clear arduino
end

Fs = 125;
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

%% Create and initialise serial connection with Arduino

COM = "COM10";
BAUD = 115200;

if (~exist('successFlag','var'))
    [arduino, successFlag] = initConnection(COM, BAUD);
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

%%

% abpData initialisation
tic

saveData = [];

t = 0;
while (get(button,'Value') == 0)
    newData = readPPG(arduino);
    
    numData = height(newData);
    dataCount = dataCount + numData;
    
    saveData = [saveData; newData];
    
    if (dataCount < len)
        tData(dataCount-numData+1:dataCount) =  t;
        redData(dataCount-numData+1:dataCount) =  newData(:,1);
        irData(dataCount-numData+1:dataCount) =  newData(:,2);
    else
        tData = [tData(numData+1:end); t];
        redData = [redData(numData+1:end); newData(:,1)];
        irData = [irData(numData+1:end); newData(:,2)];
    end
    
    t = t + Ts;
    
    % filter data // extract pulsatile component
    
    if (mod(dataCount, Fs) == 0) % i.e. every second

        % abp determination
        
        % filter/fix parts of PPG that are strange
        
        % update both PPG and ABP signal
        refreshdata
        drawnow limitrate
    end
end
toc



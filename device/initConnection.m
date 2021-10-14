function [obj, successFlag] = initConnection(port)

obj = serialport(port, 19200);
configureTerminator(obj,"CR/LF");

flush(obj);

handshake = readline(obj);

if (handshake == "Initialisation successful.")
    successFlag = 1;
    returnVal = uint8(1);
    write(obj, returnVal, 'uint8');
elseif (handshake == "Initialisation unsuccessful.")
    successFlag = 0;
else
    successFlag = -1;
end
    
end
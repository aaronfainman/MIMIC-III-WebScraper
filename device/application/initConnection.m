function [obj, successFlag] = initConnection(port, baud)

obj = serialport(port, baud);
configureTerminator(obj,"CR/LF");

flush(obj);

handshake = readline(obj);

if (strcmp(handshake,"Initialisation successful."))
    successFlag = 1;
    returnVal = uint8(1);
    write(obj, returnVal, 'uint8');
elseif (strcmp(handshake,"Initialisation unsuccessful."))
    successFlag = 0;
else
    successFlag = -1;
end
    
end
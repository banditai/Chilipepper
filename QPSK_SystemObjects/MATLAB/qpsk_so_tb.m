%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% file: qpsk_so_tb.m
% data: 6/30/2013
% purpose: 
% This is the top level testbench for a qpsk transceiver example that seeks
% to demonstrate the use of System Objects within HDL code generation. The
% basic pipeline involves
% Tx:
% Microprocessor data buffer -> Bytes to binary -> CRC generation -> 
% Reed Solomon encoding -> Convolutional interleaving -> QPSK Modulation
% -> Training Insertion
% Channel:
% We emulate a random Gaussian noise channel
% Rx:
% Frequency offset correction -> Timing offset estimation -> Correlation
% and synchronization -> QPSK Demondulation -> Convolutional deinterleaving
% -> Reed Solomon decoding -> CRC check -> binary to bytes ->
% Microprocessor data buffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hHDLEnc = comm.HDLRSEncoder(204,188);
hHDLDec = comm.HDLRSDecoder(204,188);
hInt = comm.ConvolutionalInterleaver('NumRegisters', 3, ...
                    'RegisterLengthStep', 2, ...
                    'InitialConditions', [-1 -2 -3]');
hDeInt = comm.ConvolutionalDeinterleaver('NumRegisters', 3, ...
                    'RegisterLengthStep', 2, ...
                    'InitialConditions', [-1 -2 -3]');
crcGen = comm.HDLCRCGenerator;
crcDet = comm.HDLCRCDetector;
hModulator = comm.QPSKModulator('BitInput',true);

BIT_TO_BYTE = [1 2 4 8 16 32 64 128]';
BIT_TO_SYM = [1 2];

% emulate a set of bytes sent from the processor
messageASCII = 'hello world!';
message = double(unicode2native(messageASCII));
% our data payload is going to be 32 bytes
message32 = zeros(1,32);
message32(1:length(message)) = message;
% convert message to binary symbols
sym = zeros(2,32*6);
for i1 = 0:31
    for i2 = 0:3
        sym(1,i1*4+i2+1) = mybitget(message32(i1+1),i2*2+1);
        sym(2,i1*4+i2+1) = mybitget(message32(i1+1),i2*2+2);
        2;
    end
end
% check
bits = reshape(sym,32*12,1);
for i1 = 0:31
    byte(i1+1) = bits((i1*8+1):((i1+1)*8))'*BIT_TO_BYTE;
end
disp(['Error in byte encoding: ', num2str(sum(abs(message32-byte(1:32))))])

for i1 = 1:1024
    if i1 < 32*4
        symCur = sym(:,i1);
    else
        symCur = zeros(2,1);
    end
    [dataCrcEnc, startCrcEnc(i1), endCrcEnc(i1), validCrcEnc(i1)] = ...
        step(crcGen,symCur,i1==1,i1==32*4,i1<=32*4);
    symCrcEnc(i1) = BIT_TO_SYM*dataCrcEnc;
    [symRsEnc(i1), startRsEnc(i1), endRsEnc(i1), validRsEnc(i1)] = ...
        step(hHDLEnc, symCrcEnc(i1), startCrcEnc(i1), endCrcEnc(i1), validCrcEnc(i1));
    
    [symRsDec(i1), startRsDec(i1), endRsDec(i1), validRsDec(i1)] = ...
        step(hHDLDec, symRsEnc(i1), startRsEnc(i1), endRsEnc(i1), validRsEnc(i1));
    dataRsDec = [mod(symRsDec(i1),2); floor(symRsDec(i1)/2)];
    [dataDet(:,i1), startDet(i1),endDet(i1), validDet(i1),err(i1)] = ...
          step(crcDet,dataRsDec,startRsDec(i1),endRsDec(i1),validRsDec(i1));
      
end
dataSel = dataDet(:,validDet==1);
bitSel = reshape(dataSel,32*8,1);
for i1 = 0:31
    symDec(i1+1) = bitSel(i1*8+1:(i1+1)*8)'*BIT_TO_BYTE;
end
disp(['Error in decoding: ', num2str(sum(abs(message32-symDec)))])
disp(['CRC Error: ', num2str(sum(err))]);



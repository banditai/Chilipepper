%#codegen
function [i_out, q_out, TRANSMIT_DONE] = ...
    qpsk_tx(data_in, i1, HEADER_BITS, ml)

    OS_RATE = 8;
    SYM_RATE = 4;
    HEADER_DELAY = 90; % in bits
    RSBytes = 4;       % must be an even number
    RS_DELAY = 4;
    CRC_DELAY = 10;
    INTERLEAVE_DELAY = 9;
    
    persistent dataInterleaved
    persistent crcGen
    persistent hHDLEnc
    persistent hHDLInt
    persistent symIndex
    persistent CRC_VALID
    persistent ENC_VALID
    persistent encDataOut
    i_out = 0;
    q_out = 0;
    TRANSMIT_DONE = false;
    dataCrcEnc = [false ; false];
    
    if (isempty(hHDLEnc))
                                   %ml+RSBytes,ml
        hHDLEnc = comm.HDLRSEncoder(16+4,16,'BSource','Property','B',0);
    end
    
    if (isempty(crcGen))
        crcGen = comm.HDLCRCGenerator;
    end
    
    if isempty(hHDLInt)
        hHDLInt = ConvIntSO();
    end
    
    if (i1 == 1 || isempty(CRC_VALID))
        symIndex = 0;
        dataInterleaved = [ uint8(0) ; uint8(0)];
        CRC_VALID = logical(0);
        ENC_VALID = logical(0);
        startCrcEnc = logical(0);
        startOut = logical(0);
        endOut = logical(0);
        encDataOut = 0;
    end
    
    % CRC Generator
    if (HEADER_BITS == 0 && mod(i1,8) == 0 && (i1 <= (HEADER_DELAY+(ml*SYM_RATE)-1)*OS_RATE) || CRC_VALID == 1 && mod(i1,8) == 0)               
        [dataCrcEnc, startCrcEnc, endCrcEnc, CRC_VALID] = ...
            step(crcGen,[bitget(data_in,symIndex+2) == true ; bitget(data_in,symIndex+1) == true ],...
            i1==(HEADER_DELAY)*OS_RATE,i1==(HEADER_DELAY+(ml*SYM_RATE)-1)*OS_RATE,...
            i1 < (HEADER_DELAY+(ml*SYM_RATE)-1)*OS_RATE+1);
        symIndex = mod((symIndex + 2),8);
    end
    
    % Reed Solomon Encoding
    if (CRC_VALID == 1 && mod(i1,8) == 0 || ENC_VALID == 1 && mod(i1,8) == 0)
        [encDataOut, startOut, endOut, ENC_VALID] = ...
            step(hHDLEnc, [1 2]*dataCrcEnc, i1 == (HEADER_DELAY+CRC_DELAY)*OS_RATE, i1 == (HEADER_DELAY+CRC_DELAY+((ml+2)*SYM_RATE)-1)*OS_RATE,...
            CRC_VALID);
    end
    
   % Convolutional Encoder
   if (mod(i1,8) == 0 && ENC_VALID == 1 || i1 >= (HEADER_DELAY+CRC_DELAY+RS_DELAY+(ml+2)*SYM_RATE)*OS_RATE )
       [dataInterleaved] = step(hHDLInt,[bitget(uint8(encDataOut),2) ; bitget(uint8(encDataOut),1)]);
        if (i1 >= (HEADER_DELAY+CRC_DELAY+RS_DELAY+INTERLEAVE_DELAY+(ml+2)*SYM_RATE)*OS_RATE)
            TRANSMIT_DONE = true;
        end
   end
    
   % QPSK Modulator & SRRC filtering
    if (CRC_VALID == 1 || HEADER_BITS == 1)
        [d_b2s] = qpsk_tx_byte2sym(dataInterleaved, i1);
        [d_ssrc] = qpsk_srrc(d_b2s, i1);
        % make i/q discrete ports and scale to the full 12-bit range of the DAC
        % (one bit is for sign)
        i_out = round(real(d_ssrc)*2^11);
        q_out = round(imag(d_ssrc)*2^11);
    end
end
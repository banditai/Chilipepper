%#codegen
function [i_out, q_out] = ...
    qpsk_tx(data_in, i1, HEADER_BITS, ml)

    persistent dataCrcEnc
    persistent crcGen
    persistent symIndex
    persistent CRC_VALID

    i_out = 0;
    q_out = 0;
    
    if (isempty(crcGen))
        crcGen = comm.HDLCRCGenerator;
    end
    
    if (i1 == 1 || isempty(CRC_VALID))
        symIndex = 0;
        dataCrcEnc = [ false ; false];
        CRC_VALID = logical(0);
        startCrcEnc = logical(0);
        endCrcEnc = logical(0);
    end
    
    % 
    
    if (HEADER_BITS == 0 && mod(i1,8) == 1 || CRC_VALID == 1 && mod(i1,8) == 1)
        [dataCrcEnc, startCrcEnc, endCrcEnc, CRC_VALID] = ...
            step(crcGen,[bitget(data_in,symIndex+2) == true ; bitget(data_in,symIndex+1) == true ],i1 == 713,i1 == (ml*4*8)+713,i1 < (ml*4*8)+714);
        symIndex = mod((symIndex + 2),8);
    end
    
    if (CRC_VALID == 1 || HEADER_BITS == 1)
        [d_b2s] = qpsk_tx_byte2sym(dataCrcEnc, i1);
        [d_ssrc] = qpsk_srrc(d_b2s, i1);
        % make i/q discrete ports and scale to the full 12-bit range of the DAC
        % (one bit is for sign)
        i_out = round(real(d_ssrc)*2^11);
        q_out = round(imag(d_ssrc)*2^11);
    end
end